import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('GroupDetailPage build() | groupId: $groupId');
    final membersAsync = ref.watch(groupMembersProvider(groupId));
    final currentUserId = ref.watch(currentUserProvider)?.id;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Détail du groupe'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              color: AkeliColors.primary.withValues(alpha: 0.1),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('👥', style: TextStyle(fontSize: 48)),
                    const SizedBox(height: 8),
                    Text(
                      'Groupe',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AkeliSpacing.lg),
                  AkeliSectionHeader(
                    title: 'Membres',
                    trailingLabel: 'Inviter',
                    onTrailingTap: () {
                      appLogger.userAction('Invite tapped',
                          screen: 'GroupDetailPage');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Inviter un ami — bientôt disponible')),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  membersAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                    data: (members) {
                      if (members.isEmpty) {
                        return const EmptyState(
                          icon: Icons.people_outline_rounded,
                          title: 'Aucun membre',
                          subtitle: 'Les membres apparaîtront ici.',
                        );
                      }
                      return Column(
                        children: members.map((member) {
                          final isMe = member.userId == currentUserId;
                          return _MemberRow(
                            member: member,
                            isMe: isMe,
                            onDmTap: () => _onDmTap(context, ref, member),
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: AkeliSpacing.lg),
                  const AkeliSectionHeader(title: 'Recettes partagées'),
                  const SizedBox(height: 12),
                  const EmptyState(
                    icon: Icons.restaurant_menu_rounded,
                    title: 'Aucune recette partagée',
                    subtitle:
                        'Les recettes partagées par le groupe apparaîtront ici.',
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onDmTap(
      BuildContext context, WidgetRef ref, GroupMember member) async {
    appLogger.userAction('DM button tapped',
        screen: 'GroupDetailPage',
        metadata: {'targetUserId': member.userId});
    try {
      // 1. Already have a conversation?
      final existingId = await checkExistingDm(ref, member.userId);
      if (existingId != null) {
        if (context.mounted) {
          context.push(AkeliRoutes.dmChatPath(existingId),
              extra: member.displayName);
        }
        return;
      }

      // 2. Already sent a request?
      final pending = await checkPendingRequest(ref, member.userId);
      if (pending) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande déjà envoyée')),
          );
        }
        return;
      }

      // 3. Send new request
      await sendDmRequest(ref, member.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demande envoyée à ${member.displayName}')),
        );
      }
    } catch (e, st) {
      appLogger.db('ERROR | _onDmTap | ${e.toString()}',
          error: e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Une erreur est survenue. Veuillez réessayer.')),
        );
      }
    }
  }
}

class _MemberRow extends StatelessWidget {
  final GroupMember member;
  final bool isMe;
  final VoidCallback onDmTap;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onDmTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
      child: Row(
        children: [
          AkeliAvatar(
            imageUrl: member.avatarUrl,
            initials: member.displayName.isNotEmpty
                ? member.displayName[0].toUpperCase()
                : '?',
            size: AvatarSize.md,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(member.displayName,
                    style: Theme.of(context).textTheme.titleSmall),
                Text(
                  member.role == 'admin' ? 'Admin' : 'Membre',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AkeliColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (!isMe)
            IconButton(
              icon: const Icon(Icons.mail_outline_rounded),
              color: AkeliColors.primary,
              tooltip: 'Message privé',
              onPressed: onDmTap,
            ),
        ],
      ),
    );
  }
}
