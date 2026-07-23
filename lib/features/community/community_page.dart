import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/mode_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/empty_state.dart';

// ---------------------------------------------------------------------------
// Groups data (V2 placeholder)
// ---------------------------------------------------------------------------

final communityGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final logger = appLogger;
  logger.provider('communityGroupsProvider build()');
  ref.onDispose(() => logger.provider('communityGroupsProvider disposed'));

  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final appMode = ref.watch(currentModeProvider);
  final activeMode = appMode == AppMode.beauty ? 'beauty' : 'nutrition';

  logger.db('BEFORE | table: group_member | op: SELECT my groups | userId: ${user.id}');
  final memberships = await client
      .from('group_member')
      .select('group_id')
      .eq('user_id', user.id) as List<dynamic>;

  if (memberships.isEmpty) return [];

  final groupIds = memberships
      .cast<Map<String, dynamic>>()
      .map((m) => m['group_id'] as String)
      .toList();

  logger.db('BEFORE | table: v_community_group | op: SELECT | mode: $activeMode | count: ${groupIds.length}');
  final groups = await client
      .from('v_community_group')
      .select('*')
      .inFilter('id', groupIds)
      .eq('app_mode', activeMode)
      .order('updated_at', ascending: false) as List<dynamic>;

  logger.db('AFTER | table: v_community_group | rows: ${groups.length}');
  return groups.cast<Map<String, dynamic>>();
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
  late TabController _tabController;
  final _logger = appLogger;

  static const _languages = {
    'fr': 'Français', 'en': 'English', 'es': 'Español',
    'pt': 'Português', 'wo': 'Wolof', 'bm': 'Bambara', 'ln': 'Lingala'
  };

  static const _topics = {
    'cuisine_africaine': 'Cuisine Africaine', 'batch_cooking': 'Session de cuisine',
    'nutrition': 'Nutrition', 'sport_forme': 'Sport & Forme',
    'perte_de_poids': 'Perte de poids', 'vegetarien': 'Végétarien', 'autre': 'Autre'
  };

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
    final l10n = AppLocalizations.of(context);
    final pendingAsync = ref.watch(pendingDmRequestsProvider);
    final pendingCount = pendingAsync.valueOrNull?.length ?? 0;
    final appMode = ref.watch(currentModeProvider);
    final isBeauty = appMode == AppMode.beauty;
    final title = isBeauty ? 'Communauté Beauté' : l10n.communityTitle;

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {
              _logger.userAction('Browse groups tapped', screen: 'CommunityPage');
              context.push(AkeliRoutes.browseGroups);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.communityMyGroups),
            Tab(text: l10n.communityPublicGroups),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.communityPrivateGroups),
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
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: AkeliColors.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
                ),
                builder: (ctx) => const _CreateGroupSheet(),
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

class _CreateGroupSheet extends ConsumerStatefulWidget {
  const _CreateGroupSheet();

  @override
  ConsumerState<_CreateGroupSheet> createState() => _CreateGroupSheetState();
}

class _CreateGroupSheetState extends ConsumerState<_CreateGroupSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  bool _isPublic = true;
  bool _isLoading = false;
  String? _errorMsg;
  Uint8List? _coverImageBytes;
  String? _coverImageExtension;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
      if (file != null) {
        final bytes = await file.readAsBytes();
        final ext = file.name.split('.').last.toLowerCase();
        setState(() {
          _coverImageBytes = bytes;
          _coverImageExtension = ext.isNotEmpty ? ext : 'jpg';
        });
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.communityGroupImageError)),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final groupId = await createGroup(
        ref,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        isPublic: _isPublic,
        coverImageBytes: _coverImageBytes,
        coverImageExtension: _coverImageExtension,
      );
      
      ref.invalidate(communityGroupsProvider);
      if (mounted) {
        Navigator.pop(context);
        context.push(AkeliRoutes.groupChatPath(groupId));
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Erreur lors de la création du groupe.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: AkeliSpacing.lg,
        right: AkeliSpacing.lg,
        top: AkeliSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nouveau groupe',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AkeliSpacing.lg),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AkeliColors.surfaceContainer,
                      backgroundImage: _coverImageBytes != null
                          ? MemoryImage(_coverImageBytes!)
                          : null,
                      child: _coverImageBytes == null
                          ? const Icon(Icons.camera_alt, size: 32, color: AkeliColors.textSecondary)
                          : null,
                    ),
                    if (_coverImageBytes != null)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AkeliColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AkeliSpacing.lg),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Le nom est requis';
                return null;
              },
            ),
            const SizedBox(height: AkeliSpacing.md),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (Optionnelle)',
                border: OutlineInputBorder(),
              ),
              maxLength: 200,
              maxLines: 3,
            ),
            const SizedBox(height: AkeliSpacing.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).communityPublicGroup),
                Switch(
                  value: _isPublic,
                  onChanged: (val) {
                    setState(() => _isPublic = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: AkeliSpacing.xl),
            if (_errorMsg != null) ...[
              Text(
                _errorMsg!,
                style: const TextStyle(color: AkeliColors.error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AkeliSpacing.md),
            ],
            FilledButton(
              onPressed: _isLoading ? null : _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(AppLocalizations.of(context).communityCreateGroup),
            ),
            const SizedBox(height: AkeliSpacing.xl),
          ],
        ),
        ),
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
      error: (err, _) => Center(child: Text(AppLocalizations.of(context).communityError(err.toString()))),
      data: (groups) {
        if (groups.isEmpty) {
          return Center(
            child: Text(AppLocalizations.of(context).communityNoGroups),
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
                          if (group['description'] != null && (group['description'] as String).isNotEmpty)
                            Text(
                              group['description'] as String,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall,
                            ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              if (group['language'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AkeliColors.background,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.language, size: 10, color: AkeliColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(_CommunityPageState._languages[group['language']] ?? group['language'] as String, style: const TextStyle(fontSize: 10, color: AkeliColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              if (group['topic'] != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AkeliColors.background,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.tag, size: 10, color: AkeliColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(_CommunityPageState._topics[group['topic']] ?? group['topic'] as String, style: const TextStyle(fontSize: 10, color: AkeliColors.textSecondary)),
                                    ],
                                  ),
                                ),
                            ],
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
      buildTile: (context) {
        final name = g['name'] as String;
        return ListTile(
          leading: AkeliAvatar(
            imageUrl: g['cover_url'] as String?,
            initials: name.isNotEmpty ? name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase() : '?',
            size: AvatarSize.sm,
          ),
          title: Text(name),
        subtitle:
            Text(AppLocalizations.of(context).communityMembersCount((g['member_count'] as int?) ?? 0)),
        onTap: () {
          appLogger.userAction('Group tile tapped', screen: 'CommunityPage',
              metadata: {'groupId': g['id']});
          context.push(AkeliRoutes.groupChatPath(g['id'] as String));
        },
        );
      },
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
        onTap: () {
          appLogger.userAction('DM tile tapped', screen: 'CommunityPage',
              metadata: {'conversationId': dm.conversationId});
          context.push(AkeliRoutes.dmChatPath(dm.conversationId),
              extra: dm.otherUserName);
        },
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
                      ref, req.requestId);
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
            child: Text(AppLocalizations.of(context).communityRefuse),
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
            child: Text(AppLocalizations.of(context).communityAccept),
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
