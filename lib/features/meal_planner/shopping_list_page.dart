import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/widgets/empty_state.dart';

enum _ShoppingFilter { all, bought, remaining }

class ShoppingListPage extends ConsumerStatefulWidget {
  const ShoppingListPage({super.key});

  @override
  ConsumerState<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends ConsumerState<ShoppingListPage> {
  final _logger = appLogger;
  _ShoppingFilter _filter = _ShoppingFilter.all;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListProvider);

    _logger.provider('ShoppingListPage build() | listAsync.isLoading: ${listAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      appBar: AppBar(
        backgroundColor: AkeliColors.surface.withValues(alpha: 0.8),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AkeliColors.primary),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: const Text(
          'Ma Liste',
          style: TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: AkeliColors.primary),
              onPressed: () {
                _logger.userAction('More options tapped', screen: 'ShoppingListPage');
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text('Erreur: $err', style: const TextStyle(color: AkeliColors.error)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Liste vide',
              subtitle: 'Votre liste de courses apparaîtra ici une fois votre plan alimentaire généré.',
            );
          }

          // Filter items
          final filteredItems = items.where((item) {
            switch (_filter) {
              case _ShoppingFilter.all:
                return true;
              case _ShoppingFilter.bought:
                return item.isChecked;
              case _ShoppingFilter.remaining:
                return !item.isChecked;
            }
          }).toList();

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      // Filters
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AkeliColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _FilterButton(
                              title: 'Tous',
                              isSelected: _filter == _ShoppingFilter.all,
                              onTap: () => setState(() {
                                _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'all'});
                                _filter = _ShoppingFilter.all;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterButton(
                              title: 'Achetés',
                              isSelected: _filter == _ShoppingFilter.bought,
                              onTap: () => setState(() {
                                _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'bought'});
                                _filter = _ShoppingFilter.bought;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterButton(
                              title: 'Restants',
                              isSelected: _filter == _ShoppingFilter.remaining,
                              onTap: () => setState(() {
                                _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'remaining'});
                                _filter = _ShoppingFilter.remaining;
                              }),
                            ),
                          ],
                        ),
                      ),
                      
                      // Count Banner
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Column(
                          children: [
                            Text(
                              '${filteredItems.length}',
                              style: const TextStyle(
                                fontSize: 60,
                                fontWeight: FontWeight.w900,
                                color: AkeliColors.primary,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'INGRÉDIENTS TOTAL',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AkeliColors.onSurfaceVariant,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Ingredient List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = filteredItems[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _ShoppingItemRow(
                          item: item,
                          isChecked: item.isChecked,
                          onToggle: () {
                            ref.read(shoppingListProvider.notifier).toggleItem(item.ingredientId, !item.isChecked);
                          },
                        ),
                      );
                    },
                    childCount: filteredItems.length,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AkeliColors.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AkeliColors.primaryContainer.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              fontSize: 14,
              color: isSelected ? AkeliColors.onPrimary : AkeliColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShoppingItemRow extends StatelessWidget {
  final ShoppingItem item;
  final bool isChecked;
  final VoidCallback onToggle;

  const _ShoppingItemRow({
    required this.item,
    required this.isChecked,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final qtyText = '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}';

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isChecked ? AkeliColors.surfaceContainerLow : AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isChecked
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
        ),
        child: Opacity(
          opacity: isChecked ? 0.6 : 1.0,
          child: Row(
            children: [
              // Checkbox circle
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isChecked ? AkeliColors.primary : Colors.transparent,
                  border: isChecked ? null : Border.all(color: AkeliColors.outlineVariant, width: 2),
                ),
                child: isChecked
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 16),
              
              // Ingredient name
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isChecked ? AkeliColors.onSurfaceVariant : AkeliColors.onSurface,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Quantity badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isChecked ? AkeliColors.surfaceContainerHighest : AkeliColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  qtyText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurfaceVariant,
                    decoration: isChecked ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

