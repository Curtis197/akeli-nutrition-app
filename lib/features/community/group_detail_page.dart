import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
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

    bool isAdmin = false;
    membersAsync.whenData((members) {
      final me = members.where((m) => m.userId == currentUserId).firstOrNull;
      if (me?.role == 'admin') isAdmin = true;
    });

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
                    trailingLabel: isAdmin ? 'Inviter' : null,
                    onTrailingTap: isAdmin
                        ? () {
                            appLogger.userAction('Invite tapped',
                                screen: 'GroupDetailPage');
                            _showInviteSheet(context, ref, groupId);
                          }
                        : null,
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

void _showInviteSheet(BuildContext context, WidgetRef ref, String groupId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => _InviteSheet(groupId: groupId),
  );
}

class _InviteSheet extends ConsumerStatefulWidget {
  final String groupId;
  const _InviteSheet({required this.groupId});

  @override
  ConsumerState<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends ConsumerState<_InviteSheet> {
  final Set<String> _selectedUserIds = {};
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_selectedUserIds.isEmpty) return;
    setState(() => _isSubmitting = true);

    appLogger.userAction('Submit group invites',
        screen: 'GroupDetailPage',
        metadata: {
          'count': _selectedUserIds.length.toString(),
          'groupId': widget.groupId,
        });

    try {
      final client = ref.read(supabaseClientProvider);
      await client.functions.invoke(
        'invite-to-group',
        body: {
          'group_id': widget.groupId,
          'user_ids': _selectedUserIds.toList(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invitations envoyées')),
        );
      }
    } catch (e, st) {
      appLogger.db('ERROR | invoke invite-to-group | $e',
          error: e, stackTrace: st);
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dmsAsync = ref.watch(myPrivateConversationsProvider);
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final pendingInvitesAsync =
        ref.watch(pendingGroupInvitesProvider(widget.groupId));

    return Container(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Inviter des membres',
                  style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: AkeliSpacing.md),
          Expanded(
            child: dmsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
              data: (dms) {
                final members = membersAsync.valueOrNull ?? [];
                final memberIds = members.map((m) => m.userId).toSet();

                final pendingInvites = pendingInvitesAsync.valueOrNull ?? [];
                final pendingIds = pendingInvites.toSet();

                final eligibleDms = dms.where((dm) {
                  return !memberIds.contains(dm.otherUserId) &&
                      !pendingIds.contains(dm.otherUserId);
                }).toList();

                if (eligibleDms.isEmpty) {
                  return const EmptyState(
                    icon: Icons.person_search,
                    title: 'Aucun contact éligible',
                    subtitle:
                        "Vous n'avez pas encore de conversations privées avec des utilisateurs à inviter.",
                  );
                }

                return ListView.builder(
                  itemCount: eligibleDms.length,
                  itemBuilder: (context, index) {
                    final dm = eligibleDms[index];
                    final isSelected =
                        _selectedUserIds.contains(dm.otherUserId);
                    return CheckboxListTile(
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedUserIds.add(dm.otherUserId);
                          } else {
                            _selectedUserIds.remove(dm.otherUserId);
                          }
                        });
                      },
                      title: Text(dm.otherUserName),
                      secondary: AkeliAvatar(
                        imageUrl: dm.otherUserAvatar,
                        initials: dm.otherUserName.isNotEmpty
                            ? dm.otherUserName[0].toUpperCase()
                            : '?',
                        size: AvatarSize.sm,
                      ),
                    );
                  },
                );
              },
            ),
          ),
          FilledButton(
            onPressed:
                _selectedUserIds.isEmpty || _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text('Inviter (${_selectedUserIds.length})'),
          ),
        ],
      ),
    );
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
