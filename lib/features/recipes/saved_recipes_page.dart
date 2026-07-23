import 'package:akeli/core/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/profile_tabs_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/mode_provider.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import 'domain/entities/recipe_tracking.dart';

class SavedRecipesPage extends ConsumerWidget {
  const SavedRecipesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appMode = ref.watch(currentModeProvider);
    final isBeauty = appMode == AppMode.beauty;
    final accentColor = getAppModeColor(appMode);
    final title = isBeauty ? 'Mes Remèdes & Soins Favoris' : l10n.savedRecipesTitle;
    final emptySubtitle = isBeauty ? 'Aucun soin sauvegardé pour le moment.' : l10n.savedRecipesEmpty;

    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text(l10n.savedRecipesEligibilityNotLoggedIn)));
    }

    final savedRecipesAsync = ref.watch(userSavedRecipesProvider(currentUser.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AkeliColors.surface,
        iconTheme: IconThemeData(color: accentColor),
        elevation: 0,
      ),
      backgroundColor: AkeliColors.background,
      body: savedRecipesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: AkeliColors.error),
              const SizedBox(height: 8),
              Text(l10n.mealPlannerError(err.toString()),
                  style: const TextStyle(color: AkeliColors.onSurface),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
        data: (recipes) {
            // Client-side mode filter — stopgap until userSavedRecipesProvider
            // (lib/providers/profile_tabs_provider.dart) filters server-side.
            final modeFilteredRecipes = recipes
                .where((recipe) => recipe.mode == (isBeauty ? 'beauty' : 'nutrition'))
                .toList();
            if (modeFilteredRecipes.isEmpty) {
              return Center(
                child: Text(
                  emptySubtitle,
                  style: const TextStyle(color: AkeliColors.outline, fontSize: 16),
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: modeFilteredRecipes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final recipe = modeFilteredRecipes[index];
              return AkeliRecipeCard(
                title: recipe.title,
                calories100g: recipe.calories100g?.round(),
                rating: recipe.averageRating,
                likes: recipe.likeCount,
                comments: recipe.commentCount,
                saves: recipe.saveCount,
                imageUrl: recipe.thumbnailUrl,
                creatorId: recipe.creatorId,
                onTap: () {
                  appLogger.userAction('Saved recipe tapped',
                      screen: 'SavedRecipesPage',
                      metadata: {'recipeId': recipe.id});
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
