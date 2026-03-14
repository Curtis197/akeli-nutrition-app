import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/supabase_client.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/avatar.dart';

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
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Communauté'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: groupsAsync.when(
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
                onTap: () => context
                    .go(AkeliRoutes.groupChatPath(group['id'] as String)),
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
                        initials: name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase(),
                        size: AvatarSize.md,
                      ),
                      const SizedBox(width: AkeliSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name,
                                style: Theme.of(context).textTheme.titleSmall),
                            if (group['description'] != null)
                              Text(
                                group['description'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                      Column(
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
                    ],
                  ),
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
        backgroundColor: AkeliColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}
