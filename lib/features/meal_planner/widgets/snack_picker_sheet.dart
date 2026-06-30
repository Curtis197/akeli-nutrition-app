import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/recipe_provider.dart';
import '../../../shared/models/recipe.dart';
import '../personal_meal_bottom_sheet.dart';

sealed class SnackSelection {}

class RecipeSnackSelection extends SnackSelection {
  final String recipeId;
  final double weightG;
  RecipeSnackSelection(this.recipeId, {this.weightG = 150.0});
}

class CustomSnackSelection extends SnackSelection {
  final String name;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  CustomSnackSelection({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
  });
}

class SnackPickerSheet extends ConsumerStatefulWidget {
  const SnackPickerSheet({super.key});

  @override
  ConsumerState<SnackPickerSheet> createState() => _SnackPickerSheetState();
}

class _SnackPickerSheetState extends ConsumerState<SnackPickerSheet> {
  final _logger = appLogger;
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _logger.provider('SnackPickerSheet initState()');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _logger.provider('SnackPickerSheet dispose()');
    super.dispose();
  }

  Future<double?> _showWeightPicker(BuildContext ctx, Recipe recipe) async {
    double weight = 150;
    _logger.userAction('Weight picker opened', screen: 'SnackPickerSheet',
        metadata: {'recipeId': recipe.id});
    return showDialog<double>(
      context: ctx,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AkeliRadius.xl),
          ),
          title: Text(
            recipe.title,
            style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(ctx).snackPickerEstimatedQty,
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      color: AkeliColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                recipe.calories100g != null
                    ? '${weight.toInt()} g • ${(recipe.calories100g! * weight / 100.0).round()} kcal'
                    : '${weight.toInt()} g',
                style: Theme.of(ctx).textTheme.headlineMedium?.copyWith(
                      color: AkeliColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Slider(
                value: weight,
                min: 25,
                max: 600,
                divisions: 23,
                activeColor: AkeliColors.primary,
                onChanged: (v) => setDialogState(() => weight = v),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('25 g',
                      style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.onSurfaceVariant,
                          )),
                  Text('600 g',
                      style: Theme.of(ctx).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.onSurfaceVariant,
                          )),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                _logger.userAction('Weight picker cancelled', screen: 'SnackPickerSheet');
                Navigator.of(dialogCtx).pop();
              },
              child: Text(AppLocalizations.of(dialogCtx).commonCancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AkeliColors.primary),
              onPressed: () {
                _logger.userAction('Weight confirmed', screen: 'SnackPickerSheet',
                    metadata: {'weightG': weight});
                Navigator.of(dialogCtx).pop(weight);
              },
              child: Text(AppLocalizations.of(dialogCtx).commonAdd),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPersonalSnack() async {
    _logger.userAction('Collation personnelle tapped', screen: 'SnackPickerSheet');
    final result = await showModalBottomSheet<PersonalMealCreatedResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PersonalMealBottomSheet(entryId: null),
    );
    if (result != null && mounted) {
      _logger.userAction('Personal snack created', screen: 'SnackPickerSheet',
          metadata: {'name': result.name});
      Navigator.of(context).pop(CustomSnackSelection(
        name: result.name,
        calories: result.calories,
        proteinG: result.proteinG,
        carbsG: result.carbsG,
        fatG: result.fatG,
      ));
    } else if (result == null) {
      _logger.userAction('Personal snack dismissed', screen: 'SnackPickerSheet');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('SnackPickerSheet build() | query: $_query');
    final recipesAsync = ref.watch(feedProvider(const FeedParams(limit: 30, mealType: 'snack')));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AkeliColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AkeliColors.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 4, 8, 8),
                child: Row(
                  children: [
                    Text(
                      l10n.snackPickerTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _logger.userAction('SnackPickerSheet close', screen: 'SnackPickerSheet');
                        Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchBar(
                  controller: _searchCtrl,
                  hintText: l10n.feedSearchHint,
                  onChanged: (v) {
                    _logger.userAction('SnackPickerSheet search changed', screen: 'SnackPickerSheet');
                    setState(() => _query = v);
                  },
                  leading: const Icon(Icons.search),
                  elevation: const WidgetStatePropertyAll(0),
                  backgroundColor: WidgetStatePropertyAll(
                    AkeliColors.surfaceContainerHighest.withValues(alpha: 0.15),
                  ),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.md)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: OutlinedButton.icon(
                  onPressed: _openPersonalSnack,
                  icon: const Icon(Icons.edit_note),
                  label: Text(l10n.snackPickerPersonal),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AkeliColors.primary,
                    side: BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.md)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: recipesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(l10n.mealPlannerError(e.toString()),
                        style: const TextStyle(color: AkeliColors.error)),
                  ),
                  data: (recipes) {
                    final filtered = _query.isEmpty
                        ? recipes
                        : recipes
                            .where((r) => r.title
                                .toLowerCase()
                                .contains(_query.toLowerCase()))
                            .toList();
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off,
                                size: 48, color: AkeliColors.outline),
                            const SizedBox(height: 12),
                            Text(
                              l10n.snackPickerNoResults,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      color: AkeliColors.onSurfaceVariant),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final recipe = filtered[index];
                        return _RecipePickerTile(
                          recipe: recipe,
                          onTap: () async {
                            final weightG = await _showWeightPicker(context, recipe);
                            if (weightG != null && context.mounted) {
                              _logger.userAction('Recipe picked for snack',
                                  screen: 'SnackPickerSheet',
                                  metadata: {'recipeId': recipe.id, 'weightG': weightG});
                              Navigator.of(context).pop(
                                RecipeSnackSelection(recipe.id, weightG: weightG),
                              );
                            }
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RecipePickerTile extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onTap;

  const _RecipePickerTile({required this.recipe, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AkeliRadius.md),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AkeliRadius.md),
          border: Border.all(
            color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AkeliRadius.sm),
              child: recipe.thumbnailUrl != null
                  ? Image.network(
                      recipe.thumbnailUrl!,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (recipe.calories100g != null) ...[
                        const Icon(Icons.local_fire_department,
                            size: 13, color: AkeliColors.accentAmber),
                        const SizedBox(width: 2),
                        Text(
                          '${recipe.calories100g!.toInt()} kcal/100g',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AkeliColors.onSurfaceVariant),
                        ),
                        const SizedBox(width: 8),
                      ],
                      const Icon(Icons.timer_outlined,
                          size: 13, color: AkeliColors.outline),
                      const SizedBox(width: 2),
                      Text(
                        '${recipe.totalTimeMin} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AkeliColors.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AkeliColors.outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 56,
        height: 56,
        color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.15),
        child:
            const Icon(Icons.restaurant, color: AkeliColors.outline, size: 24),
      );
}
