import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/widgets/empty_state.dart';

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final Map<String, bool> _checkedState = {};
  final Set<String> _expandedCategories = {};

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Liste de courses'),
        actions: [
          listAsync.whenOrNull(
            data: (items) => items.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareList(items),
                    tooltip: 'Partager',
                  )
                : null,
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => ErrorState(
          message: err.toString(),
          onRetry: () => ref.invalidate(shoppingListProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Liste vide',
              subtitle:
                  'Votre liste de courses apparaîtra ici une fois votre plan alimentaire généré.',
            );
          }

          // Sync checked state
          for (final item in items) {
            _checkedState.putIfAbsent(item.ingredientId, () => item.isChecked);
          }

          final grouped = _groupByCategory(items);
          final checkedCount =
              _checkedState.values.where((v) => v).length;
          final totalCalc =
              '${checkedCount}/${items.length} items cochés';

          return Column(
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(AkeliSpacing.md),
                color: AkeliColors.primary.withOpacity(0.05),
                child: Row(
                  children: [
                    const Icon(Icons.shopping_basket_outlined,
                        color: AkeliColors.primary),
                    const SizedBox(width: AkeliSpacing.sm),
                    Text(totalCalc,
                        style: Theme.of(context).textTheme.labelLarge),
                    const Spacer(),
                    if (checkedCount > 0)
                      TextButton.icon(
                        icon: const Icon(Icons.clear_all_rounded, size: 18),
                        label: const Text('Vider ✓'),
                        style: TextButton.styleFrom(
                            foregroundColor: AkeliColors.error),
                        onPressed: () => _clearChecked(),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  children: grouped.entries.map((entry) {
                    final category = entry.key;
                    final catItems = entry.value;
                    final isExpanded =
                        _expandedCategories.contains(category);
                    final checkedInCat = catItems
                        .where((i) =>
                            _checkedState[i.ingredientId] == true)
                        .length;

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: AkeliSpacing.sm),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => isExpanded
                                ? _expandedCategories.remove(category)
                                : _expandedCategories.add(category)),
                            child: Padding(
                              padding: const EdgeInsets.all(AkeliSpacing.md),
                              child: Row(
                                children: [
                                  Icon(
                                    isExpanded
                                        ? Icons.expand_less_rounded
                                        : Icons.expand_more_rounded,
                                    color: AkeliColors.primary,
                                  ),
                                  const SizedBox(width: AkeliSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      category,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall,
                                    ),
                                  ),
                                  Text(
                                    '$checkedInCat/${catItems.length}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelMedium
                                        ?.copyWith(
                                            color: AkeliColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isExpanded) ...[
                            const Divider(height: 1),
                            ...catItems.map(
                              (item) => _ShoppingItemTile(
                                item: item,
                                isChecked:
                                    _checkedState[item.ingredientId] ?? false,
                                onChanged: (v) => setState(() =>
                                    _checkedState[item.ingredientId] = v),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, List<ShoppingItem>> _groupByCategory(
      List<ShoppingItem> items) {
    final map = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final cat = item.category ?? 'Autres';
      map.putIfAbsent(cat, () => []).add(item);
    }
    // Auto-expand all categories initially
    if (_expandedCategories.isEmpty) {
      _expandedCategories.addAll(map.keys);
    }
    return map;
  }

  void _clearChecked() {
    setState(() {
      for (final key in _checkedState.keys) {
        if (_checkedState[key] == true) {
          _checkedState[key] = false;
        }
      }
    });
  }

  void _shareList(List<ShoppingItem> items) {
    // Share functionality placeholder
    final text = items
        .map((i) =>
            '${_checkedState[i.ingredientId] == true ? '✓' : '□'} ${i.name} — ${i.quantity.toStringAsFixed(1)} ${i.unit}')
        .join('\n');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage en cours de développement')),
    );
  }
}

class _ShoppingItemTile extends StatelessWidget {
  final ShoppingItem item;
  final bool isChecked;
  final ValueChanged<bool> onChanged;

  const _ShoppingItemTile({
    required this.item,
    required this.isChecked,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      value: isChecked,
      onChanged: (v) => onChanged(v ?? false),
      title: Text(
        item.name,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              decoration: isChecked ? TextDecoration.lineThrough : null,
              color: isChecked ? AkeliColors.textSecondary : null,
            ),
      ),
      subtitle: Text(
        '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AkeliColors.textSecondary,
            ),
      ),
      activeColor: AkeliColors.primary,
      dense: true,
    );
  }
}
