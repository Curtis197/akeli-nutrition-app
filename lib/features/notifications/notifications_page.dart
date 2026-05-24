import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/notifications_provider.dart';
import 'package:akeli/providers/dm_provider.dart';
import 'package:akeli/shared/widgets/empty_state.dart';
import 'package:akeli/shared/widgets/notif_card.dart';

final _logger = appLogger;

class NotificationsPage extends ConsumerStatefulWidget {
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends ConsumerState<NotificationsPage> {
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
        leading: const BackButton(),
        title: const Text('Notifications'),
      ),
      body: notifAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          _logger.provider('NotificationsPage → error | $e');
          return const EmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'Aucune notification',
            subtitle: 'Vous recevrez ici vos rappels de repas et messages.',
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
                    ref.invalidate(notificationsProvider);
                  }).catchError((e) {
                    _logger.db('ERROR | acceptDmRequest | $e');
                  });
                },
          onDecline: requestId.isEmpty
              ? null
              : () {
                  _logger.userAction('Decline DM request tapped',
                      screen: 'NotificationsPage',
                      metadata: {'request_id': requestId});
                  rejectDmRequest(ref, requestId).then((_) {
                    ref.invalidate(notificationsProvider);
                  }).catchError((e) {
                    _logger.db('ERROR | rejectDmRequest | $e');
                  });
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
