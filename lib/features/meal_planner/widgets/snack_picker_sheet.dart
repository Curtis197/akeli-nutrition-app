import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../providers/recipe_provider.dart';
import '../../../shared/models/recipe.dart';

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

  @override
  Widget build(BuildContext context) {
    _logger.provider('SnackPickerSheet build() | query: $_query');
    final recipesAsync = ref.watch(feedProvider(const FeedParams(limit: 30)));

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
                      'Choisir une collation',
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
                  hintText: 'Rechercher une recette...',
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
              const SizedBox(height: 12),
              Expanded(
                child: recipesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text('Erreur: $e',
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
                              'Aucune recette trouvée',
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
                          onTap: () {
                            _logger.userAction('Recipe picked for snack',
                                screen: 'SnackPickerSheet',
                                metadata: {'recipeId': recipe.id, 'title': recipe.title});
                            Navigator.of(context).pop(recipe.id);
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
                      if (recipe.calories != null) ...[
                        const Icon(Icons.local_fire_department,
                            size: 13, color: AkeliColors.accentAmber),
                        const SizedBox(width: 2),
                        Text(
                          '${recipe.calories!.toInt()} kcal',
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
