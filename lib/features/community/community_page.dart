import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../shared/widgets/avatar.dart';
final communityGroupsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  await Future.delayed(const Duration(milliseconds: 800));
  return [
    {
      'id': 'group-1',
      'name': 'Équilibre & Nutrition',
      'description': 'Partagez vos astuces pour manger sainement au quotidien.',
      'cover_url': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400',
      'member_count': 1240,
    },
    {
      'id': 'group-2',
      'name': 'Recettes Traditionnelles',
      'description': 'L\'art de la cuisine africaine authentique.',
      'cover_url': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
      'member_count': 850,
    },
    {
      'id': 'group-3',
      'name': 'Perte de Poids (Sénégal)',
      'description': 'Objectif forme et santé ensemble !',
      'cover_url': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
      'member_count': 2100,
    },
  ];
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
