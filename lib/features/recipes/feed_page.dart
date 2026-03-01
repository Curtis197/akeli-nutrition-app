import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/recipe_card.dart';

class FeedPage extends ConsumerStatefulWidget {
  const FeedPage({super.key});

  @override
  ConsumerState<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends ConsumerState<FeedPage> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _offset = 0;
  static const _pageSize = 20;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSearching = _searchQuery.length >= 2;
    final feedAsync = isSearching
        ? ref.watch(searchRecipesProvider(
            SearchParams(query: _searchQuery, limit: _pageSize, offset: _offset)))
        : ref.watch(feedProvider(
            FeedParams(limit: _pageSize, offset: _offset)));

    final profileAsync = ref.watch(userProfileProvider);

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          floating: true,
          snap: true,
          title: Row(
            children: [
              profileAsync.when(
                data: (profile) => CircleAvatar(
                  radius: 18,
                  backgroundImage: profile?.avatarUrl != null
                      ? NetworkImage(profile!.avatarUrl!)
                      : null,
                  backgroundColor: AkeliColors.primary,
                  child: profile?.avatarUrl == null
                      ? Text(
                          (profile?.displayName?.isNotEmpty == true
                                  ? profile!.displayName![0]
                                  : 'A')
                              .toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                loading: () => const CircleAvatar(
                    radius: 18, backgroundColor: AkeliColors.primary),
                error: (_, __) => const CircleAvatar(
                    radius: 18, backgroundColor: AkeliColors.primary),
              ),
              const SizedBox(width: AkeliSpacing.sm),
              Expanded(
                child: Text(
                  profileAsync.when(
                    data: (p) => p?.displayName != null
                        ? 'Bonjour, ${p!.displayName} 👋'
                        : 'Bienvenue sur Akeli',
                    loading: () => 'Bienvenue sur Akeli',
                    error: (_, __) => 'Bienvenue sur Akeli',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline_rounded),
              onPressed: () => context.push(AkeliRoutes.aiChat),
              tooltip: 'Assistant IA',
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AkeliSpacing.md, 0, AkeliSpacing.md, AkeliSpacing.sm),
              child: SearchBar(
                controller: _searchCtrl,
                hintText: 'Rechercher une recette...',
                leading: const Icon(Icons.search_rounded),
                trailing: _searchQuery.isNotEmpty
                    ? [
                        IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      ]
                    : null,
                onChanged: (v) => setState(() => _searchQuery = v),
                elevation: const WidgetStatePropertyAll(1),
              ),
            ),
          ),
        ),

        // Content
        feedAsync.when(
          loading: () => SliverPadding(
            padding: const EdgeInsets.all(AkeliSpacing.md),
            sliver: SliverGrid.count(
              crossAxisCount: 2,
              crossAxisSpacing: AkeliSpacing.md,
              mainAxisSpacing: AkeliSpacing.md,
              childAspectRatio: 0.75,
              children: List.generate(
                  6, (_) => const RecipeCardSkeleton()),
            ),
          ),
          error: (err, _) => SliverFillRemaining(
            child: ErrorState(
              message: err.toString(),
              onRetry: () => ref.invalidate(feedProvider),
            ),
          ),
          data: (recipes) {
            if (recipes.isEmpty) {
              return SliverFillRemaining(
                child: EmptyState(
                  icon: Icons.restaurant_menu_rounded,
                  title: isSearching
                      ? 'Aucune recette trouvée'
                      : 'Pas encore de recettes',
                  subtitle: isSearching
                      ? 'Essayez d\'autres termes de recherche.'
                      : 'Explorez et découvrez des recettes africaines.',
                ),
              );
            }

            return SliverPadding(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              sliver: SliverGrid.builder(
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: AkeliSpacing.md,
                  mainAxisSpacing: AkeliSpacing.md,
                  childAspectRatio: 0.72,
                ),
                itemCount: recipes.length,
                itemBuilder: (context, index) {
                  final recipe = recipes[index];
                  return RecipeCard(
                    recipe: recipe,
                    onTap: () => context
                        .push(AkeliRoutes.recipeDetailPath(recipe.id)),
                    onLike: () => ref
                        .read(recipeLikeProvider.notifier)
                        .toggle(recipe.id, recipe.isLiked),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
