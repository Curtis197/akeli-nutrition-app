import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final communityGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  ref.watch(currentUserProvider);
  final data = await supabase
      .from('community_group')
      .select('*, group_member(count)')
      .eq('is_public', true)
      .order('member_count', ascending: false)
      .limit(20);
  return (data as List<dynamic>).cast<Map<String, dynamic>>();
});

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class CommunityPage extends ConsumerWidget {
  const CommunityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(communityGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Communauté')),
      body: groupsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (groups) {
          if (groups.isEmpty) {
            return const Center(
              child: Text('Aucun groupe disponible pour le moment.'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AkeliSpacing.md),
            itemCount: groups.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AkeliSpacing.sm),
            itemBuilder: (context, i) {
              final group = groups[i];
              final memberCount = (group['member_count'] as int?) ?? 0;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AkeliColors.primary.withValues(alpha: 0.15),
                    backgroundImage: group['cover_url'] != null
                        ? NetworkImage(group['cover_url'] as String)
                        : null,
                    child: group['cover_url'] == null
                        ? const Icon(Icons.people_rounded,
                            color: AkeliColors.primary)
                        : null,
                  ),
                  title: Text(group['name'] as String,
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: group['description'] != null
                      ? Text(
                          group['description'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline_rounded,
                          size: 14, color: AkeliColors.textSecondary),
                      Text(
                        '$memberCount',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: AkeliColors.textSecondary),
                      ),
                    ],
                  ),
                  onTap: () => context
                      .go(AkeliRoutes.groupChatPath(group['id'] as String)),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Création de groupe — bientôt disponible')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
