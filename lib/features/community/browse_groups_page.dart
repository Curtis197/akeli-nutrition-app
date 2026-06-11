import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/supabase_client.dart';
import '../../providers/auth_provider.dart';
import '../../providers/dm_provider.dart';
import '../../providers/food_region_provider.dart';
import '../../shared/widgets/avatar.dart';
import 'community_page.dart';

class BrowseGroupsPage extends ConsumerStatefulWidget {
  const BrowseGroupsPage({super.key});

  @override
  ConsumerState<BrowseGroupsPage> createState() => _BrowseGroupsPageState();
}

class _BrowseGroupsPageState extends ConsumerState<BrowseGroupsPage> {
  String? _regionId;
  String? _language;
  String? _topic;

  static const _languages = {
    'fr': 'Français', 'en': 'English', 'es': 'Español',
    'pt': 'Português', 'wo': 'Wolof', 'bm': 'Bambara', 'ln': 'Lingala'
  };

  static const _topics = {
    'cuisine_africaine': 'Cuisine Africaine', 'batch_cooking': 'Session de cuisine',
    'nutrition': 'Nutrition', 'sport_forme': 'Sport & Forme',
    'perte_de_poids': 'Perte de poids', 'vegetarien': 'Végétarien', 'autre': 'Autre'
  };

  void _resetFilters() {
    setState(() {
      _regionId = null;
      _language = null;
      _topic = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final regionsAsync = ref.watch(foodRegionsProvider);
    final userId = ref.watch(currentUserProvider)?.id;
    final params = BrowseGroupsParams(
      userId: userId,
      regionId: _regionId,
      language: _language,
      topic: _topic,
    );
    final browseAsync = ref.watch(browseGroupsProvider(params));
    
    // get my groups to see which ones I've already joined
    final myGroups = ref.watch(communityGroupsProvider).valueOrNull ?? [];
    final myGroupIds = myGroups.map((g) => g['id'] as String).toSet();

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Découvrir des groupes'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        actions: [
          if (_regionId != null || _language != null || _topic != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Réinitialiser',
              onPressed: _resetFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          // Filters
          Container(
            padding: const EdgeInsets.symmetric(vertical: AkeliSpacing.sm),
            color: AkeliColors.surface,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
              child: Row(
                children: [
                  // Region filter
                  regionsAsync.when(
                    data: (regions) => DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _regionId,
                        hint: const Text('Région'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Toutes')),
                          ...regions.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                        ],
                        onChanged: (v) => setState(() => _regionId = v),
                      ),
                    ),
                    loading: () => const SizedBox(width: 80, child: LinearProgressIndicator()),
                    error: (_, __) => const Text('Erreur régions'),
                  ),
                  const SizedBox(width: AkeliSpacing.md),
                  // Language filter
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _language,
                      hint: const Text('Langue'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Toutes')),
                        ..._languages.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                      ],
                      onChanged: (v) => setState(() => _language = v),
                    ),
                  ),
                  const SizedBox(width: AkeliSpacing.md),
                  // Topic filter
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _topic,
                      hint: const Text('Sujet'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Tous')),
                        ..._topics.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                      ],
                      onChanged: (v) => setState(() => _topic = v),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Group List
          Expanded(
            child: browseAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erreur: $err')),
              data: (groups) {
                if (groups.isEmpty) {
                  return const Center(child: Text('Aucun groupe ne correspond à ces critères.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final groupId = group['id'] as String;
                    final isMember = myGroupIds.contains(groupId);
                    return _GroupBrowseCard(
                      group: group,
                      isMember: isMember,
                      regionsMap: regionsAsync.valueOrNull ?? {},
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupBrowseCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> group;
  final bool isMember;
  final Map<String, String> regionsMap;

  const _GroupBrowseCard({
    required this.group,
    required this.isMember,
    required this.regionsMap,
  });

  @override
  ConsumerState<_GroupBrowseCard> createState() => _GroupBrowseCardState();
}

class _GroupBrowseCardState extends ConsumerState<_GroupBrowseCard> {
  bool _isJoining = false;

  Future<void> _joinGroup() async {
    final groupId = widget.group['id'] as String;
    appLogger.userAction('Join group tapped', screen: 'BrowseGroupsPage', metadata: {'groupId': groupId});
    
    setState(() => _isJoining = true);
    
    final client = ref.read(supabaseClientProvider);
    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    try {
      // 1. Join group member
      appLogger.db('BEFORE | table: group_member | op: INSERT | groupId: $groupId');
      await client.from('group_member').insert({
        'group_id': groupId,
        'user_id': userId,
        'role': 'member'
      });
      appLogger.db('AFTER | table: group_member | joined');

      // 2. Add to conversation participant
      final conv = await client.from('conversation').select('id').eq('community_group_id', groupId).maybeSingle();
      if (conv != null) {
        await client.from('conversation_participant').insert({
          'conversation_id': conv['id'],
          'user_id': userId,
        });
      }

      ref.invalidate(communityGroupsProvider);
      ref.invalidate(browseGroupsProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Groupe rejoint avec succès')));
        context.push(AkeliRoutes.groupChatPath(groupId));
      }
    } catch (e) {
      appLogger.db('ERROR | joinGroup | $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'adhésion')));
        setState(() => _isJoining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.group['name'] as String;
    final description = widget.group['description'] as String?;
    final memberCount = widget.group['member_count'] as int? ?? 0;
    final maxMembers = widget.group['max_members'] as int?;
    
    final regionId = widget.group['region_code'] as String?;
    final languageCode = widget.group['language'] as String?;
    final topicCode = widget.group['topic'] as String?;

    final regionName = regionId != null ? widget.regionsMap[regionId] : null;
    final langName = languageCode != null ? _BrowseGroupsPageState._languages[languageCode] : null;
    final topicName = topicCode != null ? _BrowseGroupsPageState._topics[topicCode] : null;

    final isFull = maxMembers != null && memberCount >= maxMembers;

    return Container(
      margin: const EdgeInsets.only(bottom: AkeliSpacing.sm),
      padding: const EdgeInsets.all(AkeliSpacing.md),
      decoration: BoxDecoration(
        color: AkeliColors.surface,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
        boxShadow: const [AkeliShadows.sm],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AkeliAvatar(
                imageUrl: widget.group['cover_url'] as String?,
                initials: name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase(),
                size: AvatarSize.md,
              ),
              const SizedBox(width: AkeliSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleSmall),
                    if (description != null)
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (regionName != null || langName != null || topicName != null) ...[
            const SizedBox(height: AkeliSpacing.sm),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (regionName != null) _Chip(icon: Icons.public, label: regionName),
                if (langName != null) _Chip(icon: Icons.language, label: langName),
                if (topicName != null) _Chip(icon: Icons.tag, label: topicName),
              ],
            ),
          ],
          const SizedBox(height: AkeliSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.people_outline_rounded, size: 16, color: AkeliColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    maxMembers != null ? '$memberCount / $maxMembers' : '$memberCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AkeliColors.textSecondary),
                  ),
                ],
              ),
              if (widget.isMember)
                FilledButton.tonal(
                  onPressed: () => context.push(AkeliRoutes.groupChatPath(widget.group['id'])),
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 44))),
                  child: const Text('Ouvrir'),
                )
              else if (isFull)
                const FilledButton.tonal(
                  onPressed: null,
                  style: ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 44))),
                  child: Text('Complet'),
                )
              else
                FilledButton(
                  onPressed: _isJoining ? null : _joinGroup,
                  style: const ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 44))),
                  child: _isJoining
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Rejoindre'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AkeliColors.background,
        borderRadius: BorderRadius.circular(AkeliRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AkeliColors.primary),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
