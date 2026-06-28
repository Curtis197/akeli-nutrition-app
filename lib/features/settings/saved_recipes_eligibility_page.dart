import 'dart:ui';
import 'package:akeli/core/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_tabs_provider.dart';
import '../../providers/saved_recipe_progress_provider.dart';
import '../../providers/user_preferences_provider.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import '../../l10n/app_localizations.dart';

class SavedRecipesEligibilityPage extends ConsumerWidget {
  const SavedRecipesEligibilityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('SavedRecipesEligibilityPage build()');
    final l10n = AppLocalizations.of(context);
    
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null) {
      return Scaffold(body: Center(child: Text(l10n.savedRecipesEligibilityNotLoggedIn)));
    }

    final progressAsync = ref.watch(savedRecipeProgressProvider);
    final prefsAsync = ref.watch(userPreferencesProvider);
    final savedRecipesAsync = ref.watch(userSavedRecipesProvider(currentUser.id));

    return Scaffold(
      backgroundColor: AkeliColors.background,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 16),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AkeliColors.surface.withValues(alpha: 0.8),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 8,
                bottom: 8,
                left: 16,
                right: 16,
              ),
              child: Row(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: AkeliColors.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AkeliColors.onSurfaceVariant,
                      onPressed: () {
                        if (context.canPop()) context.pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.savedRecipesTitle,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AkeliColors.primary,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(l10n.homeErrorGeneric(e.toString()))),
        data: (progressData) {
          if (progressData == null) {
            return Center(child: Text(l10n.savedRecipesEligibilityNoData));
          }

          final isEligible = progressData.isEligible;
          
          return prefsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.homeErrorGeneric(e.toString()))),
            data: (prefs) {
              return savedRecipesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text(l10n.homeErrorGeneric(e.toString()))),
                data: (savedRecipes) {
                  return ListView(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
                      left: 16,
                      right: 16,
                      bottom: 32,
                    ),
                    children: [
                      Text(
                        l10n.savedRecipesEligibilityTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.savedRecipesEligibilityDesc,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AkeliColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.savedRecipesEligibilityProgress,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AkeliColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...progressData.progress.map((p) {
                        final isDone = p.savedCount >= p.targetCount;
                        final progressPercent = (p.savedCount / p.targetCount).clamp(0.0, 1.0);
                        
                        final categoryRecipes = savedRecipes
                            .where((r) => r.mealTypes.contains(p.mealType))
                            .toList();

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    p.mealType.toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${p.savedCount} / ${p.targetCount}',
                                    style: TextStyle(
                                      color: isDone ? Colors.green : AkeliColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: progressPercent,
                                backgroundColor: AkeliColors.surfaceContainerHighest,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isDone ? Colors.green : AkeliColors.primary,
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              if (!isDone)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    l10n.savedRecipesEligibilityMissing(p.targetCount - p.savedCount),
                                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                                  ),
                                ),
                              if (categoryRecipes.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 220,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: categoryRecipes.length,
                                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                                    itemBuilder: (context, index) {
                                      final recipe = categoryRecipes[index];
                                      return SizedBox(
                                        width: 160,
                                        child: AkeliRecipeCard(
                                          title: recipe.title,
                                          calories100g: recipe.calories100g?.round(),
                                          rating: recipe.averageRating,
                                          likes: recipe.likeCount,
                                          comments: recipe.commentCount,
                                          saves: recipe.saveCount,
                                          imageUrl: recipe.thumbnailUrl,
                                          isMinimalist: true,
                                          creatorId: recipe.creatorId,
                                          onTap: () {
                                            appLogger.userAction('Eligibility recipe tapped',
                                                screen: 'SavedRecipesEligibilityPage',
                                                metadata: {'recipeId': recipe.id});
                                            context.push(
                                              AkeliRoutes.recipeDetailPath(recipe.id),
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      Container(
                        decoration: BoxDecoration(
                          color: AkeliColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AkeliColors.surfaceContainerHighest),
                        ),
                        child: SwitchListTile(
                          title: Text(l10n.savedRecipesEligibilityToggleTitle),
                          subtitle: Text(
                            isEligible
                                ? l10n.savedRecipesEligibilityEnabled
                                : l10n.savedRecipesEligibilityBlocked,
                          ),
                          value: prefs.useSavedRecipesOnly,
                          onChanged: isEligible
                              ? (val) async {
                                  final updated = prefs.copyWith(useSavedRecipesOnly: val);
                                  await ref.read(userPreferencesProvider.notifier).save(updated);
                                }
                              : null,
                          activeThumbColor: AkeliColors.primary,
                          inactiveThumbColor: Colors.white,
                        ),
                      ),
                    ],
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
