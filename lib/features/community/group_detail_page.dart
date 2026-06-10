import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/section_header.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  const GroupDetailPage({super.key, required this.groupId});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  final _logger = appLogger;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _logger.provider('GroupDetailPage initState() | groupId: ${widget.groupId}');
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _logger.provider('GroupDetailPage disposed');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('GroupDetailPage build() | groupId: ${widget.groupId}');
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final groupAsync = ref.watch(groupDetailsProvider(widget.groupId));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AkeliRoutes.groupChatPath(widget.groupId));
            }
          },
        ),
        title: const Text('Détail du groupe'),
      ),
      body: Column(
        children: [
          // ── Group cover header ───────────────────────────────────────────
          groupAsync.when(
            data: (group) {
              final name = group?['name'] as String? ?? 'Groupe inconnu';
              final description = group?['description'] as String?;
              final coverUrl = group?['cover_url'] as String?;

              return Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AkeliColors.primary.withValues(alpha: 0.1),
                  image: coverUrl != null
                      ? DecorationImage(
                          image: NetworkImage(coverUrl),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withValues(alpha: 0.4),
                            BlendMode.darken,
                          ),
                        )
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (coverUrl == null)
                        const Text('👥', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          name,
                          style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: coverUrl != null ? Colors.white : null,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            description,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: coverUrl != null
                                      ? Colors.white70
                                      : AkeliColors.textSecondary,
                                ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
            loading: () => Container(
              height: 180,
              color: AkeliColors.primary.withValues(alpha: 0.1),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => Container(
              height: 180,
              color: AkeliColors.error.withValues(alpha: 0.1),
              child: const Center(child: Text('Erreur de chargement')),
            ),
          ),

          // ── Tab bar ──────────────────────────────────────────────────────
          ColoredBox(
            color: AkeliColors.background,
            child: TabBar(
              controller: _tabController,
              labelColor: AkeliColors.primary,
              unselectedLabelColor: AkeliColors.textSecondary,
              indicatorColor: AkeliColors.primary,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'Membres'),
                Tab(text: 'Photos'),
                Tab(text: 'Recettes'),
              ],
            ),
          ),

          // ── Tab content ──────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _MembersTab(
                  groupId: widget.groupId,
                  currentUserId: currentUserId,
                  isAdmin: isAdmin,
                  membersAsync: membersAsync,
                  onDmTap: (member) => _onDmTap(context, member),
                  onExcludeTap: (member) => _onExcludeTap(context, member),
                ),
                _ImagesTab(groupId: widget.groupId),
                _RecipesTab(groupId: widget.groupId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onDmTap(BuildContext context, GroupMember member) async {
    _logger.userAction('DM button tapped',
        screen: 'GroupDetailPage',
        metadata: {'targetUserId': member.userId});
    try {
      final existingId = await checkExistingDm(ref, member.userId);
      if (existingId != null) {
        if (context.mounted) {
          context.push(AkeliRoutes.dmChatPath(existingId), extra: member.displayName);
        }
        return;
      }

      final pending = await checkPendingRequest(ref, member.userId);
      if (pending) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande déjà envoyée')),
          );
        }
        return;
      }

      await sendDmRequest(ref, member.userId);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Demande envoyée à ${member.displayName}')),
        );
      }
    } catch (e, st) {
      appLogger.db('ERROR | _onDmTap | ${e.toString()}', error: e, stackTrace: st);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Une erreur est survenue. Veuillez réessayer.')),
        );
      }
    }
  }

  Future<void> _onExcludeTap(BuildContext context, GroupMember member) async {
    _logger.userAction('Exclude member tapped',
        screen: 'GroupDetailPage',
        metadata: {'targetUserId': member.userId});

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Exclure ${member.displayName} ?'),
        content: const Text(
            'Cette personne perdra l\'accès au groupe et au chat de groupe.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AkeliColors.error),
            child: const Text('Exclure'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final client = ref.read(supabaseClientProvider);
    _logger.edge('remove-group-member',
        'BEFORE | groupId: ${widget.groupId} | target: ${member.userId}');

    try {
      await client.functions.invoke(
        'remove-group-member',
        body: {
          'group_id': widget.groupId,
          'target_user_id': member.userId,
        },
      );
      _logger.edge('remove-group-member', 'AFTER | success');
      ref.invalidate(groupMembersProvider(widget.groupId));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre exclu du groupe')),
        );
      }
    } on FunctionException catch (e, st) {
      _logger.edge('remove-group-member',
          'ERROR | status: ${e.status} | ${e.reasonPhrase}',
          error: e, stackTrace: st);
      if (!context.mounted) return;
      if (e.status == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("Vous n'êtes plus administrateur de ce groupe")),
        );
      } else if (e.status == 404) {
        // Target already removed — treat as success
        ref.invalidate(groupMembersProvider(widget.groupId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membre exclu du groupe')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Une erreur est survenue. Veuillez réessayer.')),
        );
      }
    } catch (e, st) {
      _logger.edge('remove-group-member', 'ERROR | $e', error: e, stackTrace: st);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Une erreur est survenue. Veuillez réessayer.')),
      );
    }
  }
}

// ── Tab 0 — Members ───────────────────────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final String groupId;
  final String? currentUserId;
  final bool isAdmin;
  final AsyncValue<List<GroupMember>> membersAsync;
  final void Function(GroupMember) onDmTap;
  final void Function(GroupMember) onExcludeTap;

  const _MembersTab({
    required this.groupId,
    required this.currentUserId,
    required this.isAdmin,
    required this.membersAsync,
    required this.onDmTap,
    required this.onExcludeTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      children: [
        AkeliSectionHeader(
          title: 'Membres',
          trailingLabel: isAdmin ? 'Inviter' : null,
          onTrailingTap: isAdmin
              ? () {
                  appLogger.userAction('Invite tapped', screen: 'GroupDetailPage');
                  _showInviteSheet(context, ref, groupId);
                }
              : null,
        ),
        const SizedBox(height: 12),
        membersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
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
                  onDmTap: () => onDmTap(member),
                  onProfileTap: () {
                    appLogger.userAction('Profile tapped',
                        screen: 'GroupDetailPage',
                        metadata: {'targetUserId': member.userId});
                    context.push(AkeliRoutes.userProfilePath(member.userId));
                  },
                  onExcludeTap: isAdmin && !isMe ? () => onExcludeTap(member) : null,
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Tab 1 — Photos ───────────────────────────────────────────────────────────

class _ImagesTab extends ConsumerWidget {
  final String groupId;
  const _ImagesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_ImagesTab build() | groupId: $groupId');
    final imagesAsync = ref.watch(groupSharedImagesProvider(groupId));

    return imagesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        appLogger.provider('_ImagesTab → error | $e');
        return const Center(child: Text('Erreur de chargement'));
      },
      data: (urls) {
        appLogger.provider('_ImagesTab → data | count: ${urls.length}');
        if (urls.isEmpty) {
          return const EmptyState(
            icon: Icons.photo_library_outlined,
            title: 'Aucune photo partagée',
            subtitle: 'Les photos envoyées dans le chat apparaîtront ici.',
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(AkeliSpacing.sm),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
          ),
          itemCount: urls.length,
          itemBuilder: (context, i) => _ImageTile(url: urls[i]),
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  const _ImageTile({required this.url});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appLogger.userAction('Photo tapped', screen: 'GroupDetailPage');
        _openFullscreen(context);
      },
      child: CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(color: AkeliColors.surfaceContainer),
        errorWidget: (_, __, ___) => Container(
          color: AkeliColors.surfaceContainer,
          child: const Icon(Icons.broken_image_outlined, color: AkeliColors.outline),
        ),
      ),
    );
  }

  void _openFullscreen(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(imageUrl: url),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab 2 — Recipes ──────────────────────────────────────────────────────────

class _RecipesTab extends ConsumerWidget {
  final String groupId;
  const _RecipesTab({required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_RecipesTab build() | groupId: $groupId');
    final recipeIdsAsync = ref.watch(groupSharedRecipesProvider(groupId));

    return recipeIdsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) {
        appLogger.provider('_RecipesTab → error | $e');
        return const Center(child: Text('Erreur de chargement'));
      },
      data: (ids) {
        appLogger.provider('_RecipesTab → data | count: ${ids.length}');
        if (ids.isEmpty) {
          return const EmptyState(
            icon: Icons.restaurant_menu_rounded,
            title: 'Aucune recette partagée',
            subtitle: 'Les recettes partagées dans le chat apparaîtront ici.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AkeliSpacing.md),
          itemCount: ids.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _SharedRecipeCard(recipeId: ids[i]),
        );
      },
    );
  }
}

class _SharedRecipeCard extends ConsumerWidget {
  final String recipeId;
  const _SharedRecipeCard({required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recipeAsync = ref.watch(recipeDetailProvider(recipeId));

    return recipeAsync.when(
      loading: () => Container(
        height: 80,
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainer,
          borderRadius: BorderRadius.circular(AkeliRadius.md),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (recipe) {
        if (recipe == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            appLogger.userAction('Shared recipe tapped',
                screen: 'GroupDetailPage',
                metadata: {'recipeId': recipeId});
            context.push(AkeliRoutes.recipeDetailPath(recipeId));
          },
          child: Container(
            decoration: BoxDecoration(
              color: AkeliColors.surface,
              borderRadius: BorderRadius.circular(AkeliRadius.md),
              boxShadow: const [AkeliShadows.sm],
            ),
            clipBehavior: Clip.hardEdge,
            child: Row(
              children: [
                if (recipe.thumbnailUrl != null)
                  CachedNetworkImage(
                    imageUrl: recipe.thumbnailUrl!,
                    width: 90,
                    height: 80,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 90,
                      height: 80,
                      color: AkeliColors.surfaceContainer,
                      child: const Icon(Icons.restaurant, color: AkeliColors.outline),
                    ),
                  )
                else
                  Container(
                    width: 90,
                    height: 80,
                    color: AkeliColors.surfaceContainer,
                    child: const Icon(Icons.restaurant, color: AkeliColors.outline),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          recipe.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (recipe.calories != null) ...[
                              const Icon(Icons.local_fire_department_rounded,
                                  size: 13, color: AkeliColors.secondary),
                              const SizedBox(width: 3),
                              Text(
                                '${recipe.calories!.round()} kcal',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: AkeliColors.textSecondary),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Icon(Icons.timer_outlined,
                                size: 13, color: AkeliColors.textSecondary),
                            const SizedBox(width: 3),
                            Text(
                              '${recipe.totalTimeMin} min',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(color: AkeliColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right_rounded,
                      color: AkeliColors.primary, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Invite sheet ─────────────────────────────────────────────────────────────

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
      appLogger.db('ERROR | invoke invite-to-group | $e', error: e, stackTrace: st);
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
    final pendingInvitesAsync = ref.watch(pendingGroupInvitesProvider(widget.groupId));

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

                final eligibleDms = dms
                    .where((dm) =>
                        !memberIds.contains(dm.otherUserId) &&
                        !pendingIds.contains(dm.otherUserId))
                    .toList();

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
                    final isSelected = _selectedUserIds.contains(dm.otherUserId);
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
            onPressed: _selectedUserIds.isEmpty || _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Inviter (${_selectedUserIds.length})'),
          ),
        ],
      ),
    );
  }
}

// ── Member row ────────────────────────────────────────────────────────────────

class _MemberRow extends StatelessWidget {
  final GroupMember member;
  final bool isMe;
  final VoidCallback onDmTap;
  final VoidCallback onProfileTap;
  final VoidCallback? onExcludeTap;

  const _MemberRow({
    required this.member,
    required this.isMe,
    required this.onDmTap,
    required this.onProfileTap,
    this.onExcludeTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onProfileTap,
      borderRadius: BorderRadius.circular(AkeliRadius.md),
      child: Padding(
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
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      member.displayName,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (member.role == 'admin') ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AkeliColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Admin',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AkeliColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
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
            if (onExcludeTap != null)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AkeliColors.textSecondary),
                onSelected: (value) {
                  if (value == 'exclude') onExcludeTap!();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'exclude',
                    child: Row(
                      children: [
                        Icon(Icons.person_remove_outlined, color: AkeliColors.error, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Exclure du groupe',
                          style: TextStyle(color: AkeliColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
