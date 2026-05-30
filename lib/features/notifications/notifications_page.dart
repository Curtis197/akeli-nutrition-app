import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/supabase_client.dart';
import 'package:akeli/features/community/community_page.dart';
import 'package:akeli/providers/notifications_provider.dart';
import 'package:akeli/providers/dm_provider.dart';
import 'package:akeli/shared/widgets/empty_state.dart';
import 'package:akeli/shared/widgets/notif_card.dart';

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _logger.provider('NotificationsPage initState()');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      markAllNotificationsRead(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('NotificationsPage build()');
    final notifAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(AkeliRoutes.home);
          }
        },
      ),
        title: const Text('Notifications'),
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          _logger.provider('NotificationsPage → error | $e');
          return const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Erreur de chargement',
            subtitle: 'Impossible de charger les notifications. Réessayez.',
          );
        },
        data: (notifications) {
          _logger.provider(
              'NotificationsPage → data | count: ${notifications.length}');
          if (notifications.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              subtitle: 'Vous recevrez ici vos rappels de repas et messages.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: notifications.length,
            itemBuilder: (context, index) =>
                _buildCard(notifications[index]),
          );
        },
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> notif) {
    final type = notif['type'] as String? ?? '';
    final title = notif['title'] as String? ?? '';
    final body = notif['body'] as String? ?? '';
    final createdAt = notif['created_at'] as String? ?? '';
    final data = (notif['data'] as Map<String, dynamic>?) ?? {};

    switch (type) {
      case 'message':
        return AkeliNotifCard(
          type: NotifType.chat,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
        );

      case 'conversation_request':
        final requestId = data['request_id'] as String? ?? '';
        final requesterId = data['requester_id'] as String? ?? '';
        return AkeliNotifCard(
          type: NotifType.request,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          onAccept: requestId.isEmpty
              ? null
              : () {
                  _logger.userAction('Accept DM request tapped',
                      screen: 'NotificationsPage',
                      metadata: {'request_id': requestId});
                  acceptDmRequest(ref, requestId, requesterId).then((_) {
                    if (mounted) ref.invalidate(notificationsProvider);
                  }).catchError((Object e, StackTrace st) {
                    _logger.db('ERROR | acceptDmRequest | $e', error: e, stackTrace: st);
                  });
                },
          onDecline: requestId.isEmpty
              ? null
              : () {
                  _logger.userAction('Decline DM request tapped',
                      screen: 'NotificationsPage',
                      metadata: {'request_id': requestId});
                  rejectDmRequest(ref, requestId).then((_) {
                    if (mounted) ref.invalidate(notificationsProvider);
                  }).catchError((Object e, StackTrace st) {
                    _logger.db('ERROR | rejectDmRequest | $e', error: e, stackTrace: st);
                  });
                },
        );

      case 'group_invite':
        final inviteId = data['invite_id'] as String? ?? '';
        return AkeliNotifCard(
          type: NotifType.request,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          onAccept: inviteId.isEmpty
              ? null
              : () async {
                  _logger.userAction('Accept group invite tapped',
                      screen: 'NotificationsPage',
                      metadata: {'invite_id': inviteId});
                  try {
                    final client = ref.read(supabaseClientProvider);
                    final result = await client.rpc('accept_group_invite', params: {'p_invite_id': inviteId});
                    if (mounted) {
                      ref.invalidate(notificationsProvider);
                      ref.invalidate(communityGroupsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Vous avez rejoint le groupe'),
                          action: SnackBarAction(
                            label: 'Ouvrir',
                            onPressed: () {
                              context.go(AkeliRoutes.groupDetailPath(result.toString()));
                            },
                          ),
                        ),
                      );
                    }
                  } catch (e, st) {
                    _logger.db('ERROR | accept_group_invite | $e', error: e, stackTrace: st);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Erreur: Invitation introuvable ou déjà traitée')),
                      );
                    }
                  }
                },
          onDecline: inviteId.isEmpty
              ? null
              : () async {
                  _logger.userAction('Decline group invite tapped',
                      screen: 'NotificationsPage',
                      metadata: {'invite_id': inviteId});
                  try {
                    final client = ref.read(supabaseClientProvider);
                    await client.from('group_invite').update({'status': 'declined'}).eq('id', inviteId);
                    if (mounted) {
                      ref.invalidate(notificationsProvider);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invitation déclinée')),
                      );
                    }
                  } catch (e, st) {
                    _logger.db('ERROR | decline group invite | $e', error: e, stackTrace: st);
                  }
                },
        );

      case 'meal_reminder':
        final mealType = data['meal_type'] as String? ?? '';
        return AkeliNotifCard(
          type: NotifType.meal,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          emoji: _mealEmoji(mealType),
        );

      default:
        return AkeliNotifCard(
          type: NotifType.meal,
          title: title,
          subtitle: body,
          time: _relativeTime(createdAt),
          emoji: '🔔',
        );
    }
  }
}

String _relativeTime(String isoString) {
  final dt = DateTime.tryParse(isoString);
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt.toLocal());
  if (diff.inMinutes < 1) return "À l'instant";
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
  if (diff.inDays == 1) return 'Hier';
  return 'Il y a ${diff.inDays} j';
}

String _mealEmoji(String mealType) {
  switch (mealType) {
    case 'breakfast':
      return '🥣';
    case 'lunch':
      return '🍽️';
    case 'dinner':
      return '🌙';
    case 'snack':
      return '🍎';
    default:
      return '🍽️';
  }
}
