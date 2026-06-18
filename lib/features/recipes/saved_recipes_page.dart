import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/profile_tabs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import 'domain/entities/recipe_tracking.dart';

class SavedRecipesPage extends ConsumerWidget {
  const SavedRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final savedRecipesAsync = ref.watch(userSavedRecipesProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recettes Sauvegardées', style: TextStyle(color: AkeliColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AkeliColors.surface,
        iconTheme: const IconThemeData(color: AkeliColors.primary),
        elevation: 0,
      ),
      backgroundColor: AkeliColors.background,
      body: savedRecipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AkeliColors.outline))),
        data: (recipes) {
          if (recipes.isEmpty) {
            return const Center(
              child: Text(
                'Aucune recette sauvegardée',
                style: TextStyle(color: AkeliColors.outline, fontSize: 16),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: recipes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final recipe = recipes[index];
              return AkeliRecipeCard(
                title: recipe.title,
                calories100g: recipe.calories100g?.round(),
                rating: recipe.averageRating,
                likes: recipe.likeCount,
                comments: recipe.commentCount,
                saves: recipe.saveCount,
                imageUrl: recipe.thumbnailUrl,
                onTap: () {
                  context.push(
                    AkeliRoutes.recipeDetailPath(recipe.id),
                    extra: TrackingSource.feed,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
