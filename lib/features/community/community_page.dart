import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/dm_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/empty_state.dart';

// ---------------------------------------------------------------------------
// Groups data (V2 placeholder)
// ---------------------------------------------------------------------------

final communityGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  appLogger.provider('communityGroupsProvider build()');
  ref.onDispose(() => appLogger.provider('communityGroupsProvider disposed'));
  return [];
});

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _logger.provider('CommunityPage initState()');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _logger.provider('CommunityPage disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('CommunityPage build()');
    final pendingAsync = ref.watch(pendingDmRequestsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Communauté'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(text: 'Tout'),
            const Tab(text: 'Groupes'),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Privés'),
                  if (pendingCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AkeliColors.primary,
                        borderRadius:
                            BorderRadius.circular(AkeliRadius.pill),
                      ),
                      child: Text(
                        '$pendingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ToutTab(),
          _GroupesTab(),
          _PrivesTab(),
        ],
      ),
      floatingActionButton: ListenableBuilder(
        listenable: _tabController,
        builder: (context, _) {
          if (_tabController.index != 1) return const SizedBox.shrink();
          return FloatingActionButton(
            onPressed: () {
              _logger.userAction('Create group FAB tapped',
                  screen: 'CommunityPage');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('Création de groupe — bientôt disponible')),
              );
            },
            backgroundColor: AkeliColors.primary,
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _GroupesTab — existing groups list
// ---------------------------------------------------------------------------

class _GroupesTab extends ConsumerWidget {
  const _GroupesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(communityGroupsProvider);
    appLogger.provider('_GroupesTab build()');

    return groupsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Erreur: $err')),
      data: (groups) {
        if (groups.isEmpty) {
          return const Center(
            child: Text('Aucun groupe disponible pour le moment.'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(AkeliSpacing.md),
          itemCount: groups.length,
          itemBuilder: (context, i) {
            final group = groups[i];
            final memberCount = (group['member_count'] as int?) ?? 0;
            final name = group['name'] as String;
            return InkWell(
              onTap: () {
                appLogger.userAction('Group card tapped',
                    screen: 'CommunityPage',
                    metadata: {'groupId': group['id']});
                context
                    .go(AkeliRoutes.groupChatPath(group['id'] as String));
              },
              borderRadius: BorderRadius.circular(AkeliRadius.md),
              child: Container(
                margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
                padding: const EdgeInsets.all(AkeliSpacing.md),
                decoration: BoxDecoration(
                  color: AkeliColors.surface,
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                  boxShadow: const [AkeliShadows.sm],
                ),
                child: Row(
                  children: [
                    AkeliAvatar(
                      imageUrl: group['cover_url'] as String?,
                      initials: name
                          .substring(0, name.length >= 2 ? 2 : 1)
                          .toUpperCase(),
                      size: AvatarSize.md,
                    ),
                    const SizedBox(width: AkeliSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall),
                          if (group['description'] != null)
                            Text(
                              group['description'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                        ],
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.people_outline_rounded,
                            size: 14,
                            color: AkeliColors.textSecondary),
                        Text(
                          '$memberCount',
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                  color: AkeliColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// _ToutTab — merged groups + DMs sorted by updatedAt
// ---------------------------------------------------------------------------

class _ToutTab extends ConsumerWidget {
  const _ToutTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_ToutTab build()');
    final groupsAsync = ref.watch(communityGroupsProvider);
    final dmsAsync = ref.watch(myPrivateConversationsProvider);

    final groups = groupsAsync.valueOrNull ?? [];
    final dms = dmsAsync.valueOrNull ?? [];

    if (groupsAsync.isLoading || dmsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groups.isEmpty && dms.isEmpty) {
      return const EmptyState(
        icon: Icons.forum_outlined,
        title: 'Aucune conversation',
        subtitle: 'Rejoignez un groupe ou envoyez un message privé.',
      );
    }

    final items = <_ToutItem>[
      ...groups.map((g) => _ToutItem.group(g)),
      ...dms.map((dm) => _ToutItem.dm(dm)),
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return ListView.builder(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i].buildTile(context),
    );
  }
}

class _ToutItem {
  final DateTime updatedAt;
  final Widget Function(BuildContext) _buildTile;

  _ToutItem._(
      {required this.updatedAt,
      required Widget Function(BuildContext) buildTile})
      : _buildTile = buildTile;

  factory _ToutItem.group(Map<String, dynamic> g) {
    final updatedAt = g['updated_at'] != null
        ? DateTime.tryParse(g['updated_at'] as String) ?? DateTime(2000)
        : DateTime(2000);
    return _ToutItem._(
      updatedAt: updatedAt,
      buildTile: (context) => ListTile(
        leading: const Icon(Icons.people_outline_rounded,
            color: AkeliColors.primary),
        title: Text(g['name'] as String),
        subtitle:
            Text('${(g['member_count'] as int?) ?? 0} membres'),
        onTap: () => context
            .push(AkeliRoutes.groupChatPath(g['id'] as String)),
      ),
    );
  }

  factory _ToutItem.dm(DmConversation dm) {
    return _ToutItem._(
      updatedAt: dm.updatedAt,
      buildTile: (context) => ListTile(
        leading: AkeliAvatar(
          imageUrl: dm.otherUserAvatar,
          initials: dm.otherUserName.isNotEmpty
              ? dm.otherUserName[0].toUpperCase()
              : '?',
          size: AvatarSize.sm,
        ),
        title: Text(dm.otherUserName),
        subtitle: Text(
          dm.lastMessage ?? '—',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: dm.unreadCount > 0
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AkeliColors.primary,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () => context.push(
          AkeliRoutes.dmChatPath(dm.conversationId),
          extra: dm.otherUserName,
        ),
      ),
    );
  }

  Widget buildTile(BuildContext context) => _buildTile(context);
}

// ---------------------------------------------------------------------------
// _PrivesTab — pending requests + DM list
// ---------------------------------------------------------------------------

class _PrivesTab extends ConsumerWidget {
  const _PrivesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('_PrivesTab build()');
    final requestsAsync = ref.watch(pendingDmRequestsProvider);
    final dmsAsync = ref.watch(myPrivateConversationsProvider);

    final requests = requestsAsync.valueOrNull ?? [];
    final dms = dmsAsync.valueOrNull ?? [];

    if (requestsAsync.isLoading || dmsAsync.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (requests.isEmpty && dms.isEmpty) {
      return const EmptyState(
        icon: Icons.chat_bubble_outline_rounded,
        title: 'Aucune conversation privée',
        subtitle: 'Rejoignez un groupe pour commencer.',
      );
    }

    return ListView(
      padding: const EdgeInsets.all(AkeliSpacing.md),
      children: [
        if (requests.isNotEmpty) ...[
          Text(
            'Demandes en attente',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AkeliColors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: AkeliSpacing.sm),
          ...requests.map((req) => _RequestCard(
                request: req,
                onAccept: () async {
                  final convId = await acceptDmRequest(
                      ref, req.requestId, req.requesterId);
                  if (context.mounted) {
                    context.push(AkeliRoutes.dmChatPath(convId),
                        extra: req.requesterName);
                  }
                },
                onReject: () => rejectDmRequest(ref, req.requestId),
              )),
          const Divider(height: AkeliSpacing.xl),
        ],
        ...dms.map((dm) => _DmTile(dm: dm)),
      ],
    );
  }
}

class _RequestCard extends StatelessWidget {
  final DmRequest request;
  final Future<void> Function() onAccept;
  final Future<void> Function() onReject;

  const _RequestCard({
    required this.request,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        boxShadow: const [AkeliShadows.sm],
      ),
      child: Row(
        children: [
          AkeliAvatar(
            imageUrl: request.requesterAvatar,
            initials: request.requesterName.isNotEmpty
                ? request.requesterName[0].toUpperCase()
                : '?',
            size: AvatarSize.md,
          ),
          const SizedBox(width: AkeliSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.requesterName,
                    style: Theme.of(context).textTheme.titleSmall),
                if (request.message != null)
                  Text(
                    request.message!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: () async {
              appLogger.userAction('DM request rejected',
                  screen: 'CommunityPage',
                  metadata: {'requestId': request.requestId});
              try {
                await onReject();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erreur lors du refus')),
                  );
                }
              }
            },
            child: const Text('Refuser'),
          ),
          const SizedBox(width: AkeliSpacing.xs),
          FilledButton(
            onPressed: () async {
              appLogger.userAction('DM request accepted',
                  screen: 'CommunityPage',
                  metadata: {'requestId': request.requestId});
              try {
                await onAccept();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Erreur lors de l\'acceptation')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(
                  horizontal: AkeliSpacing.md, vertical: AkeliSpacing.sm),
            ),
            child: const Text('Accepter'),
          ),
        ],
      ),
    );
  }
}

class _DmTile extends StatelessWidget {
  final DmConversation dm;
  const _DmTile({required this.dm});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AkeliAvatar(
        imageUrl: dm.otherUserAvatar,
        initials: dm.otherUserName.isNotEmpty
            ? dm.otherUserName[0].toUpperCase()
            : '?',
        size: AvatarSize.md,
      ),
      title: Text(dm.otherUserName),
      subtitle: Text(
        dm.lastMessage ?? '—',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: dm.unreadCount > 0
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AkeliColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
      onTap: () {
        appLogger.userAction('DM tile tapped',
            screen: 'CommunityPage',
            metadata: {'conversationId': dm.conversationId});
        context.push(AkeliRoutes.dmChatPath(dm.conversationId),
            extra: dm.otherUserName);
      },
    );
  }
}
