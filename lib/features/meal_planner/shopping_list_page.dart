import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/mode_provider.dart';
import '../../widgets/mode_selector.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/shopping_row.dart';

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
    final l10n = AppLocalizations.of(context);
    final appMode = ref.watch(currentModeProvider);
    final isBeauty = appMode == AppMode.beauty;
    final accentColor = getAppModeColor(appMode);
    final title = isBeauty ? 'Liste d\'Achat Produits & Actifs' : l10n.shoppingListTitle;
    final emptySubtitle = isBeauty
        ? 'Aucun actif ni produit dans votre liste. Ajoutez des soins depuis vos remèdes.'
        : l10n.shoppingListEmpty;

    final listAsync = ref.watch(shoppingListProvider);
    final localeState = ref.watch(localeProvider);
    final isUsLocale = localeState.isUsLocale;
    final localeName = l10n.localeName;

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
            icon: Icon(Icons.arrow_back, color: accentColor),
            onPressed: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  context.go(AkeliRoutes.mealPlanner);
                }
              },
            style: IconButton.styleFrom(
              backgroundColor: Colors.transparent,
            ),
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: listAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Text(l10n.mealPlannerError(err.toString()), style: const TextStyle(color: AkeliColors.error)),
        ),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
              icon: isBeauty ? Icons.spa_outlined : Icons.shopping_cart_outlined,
              title: title,
              subtitle: emptySubtitle,
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
                              title: l10n.shoppingListAll,
                              isSelected: _filter == _ShoppingFilter.all,
                              onTap: () => setState(() {
                                _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'all'});
                                _filter = _ShoppingFilter.all;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterButton(
                              title: l10n.shoppingListChecked,
                              isSelected: _filter == _ShoppingFilter.bought,
                              onTap: () => setState(() {
                                _logger.userAction('Filter selected', screen: 'ShoppingListPage', metadata: {'filter': 'bought'});
                                _filter = _ShoppingFilter.bought;
                              }),
                            ),
                            const SizedBox(width: 8),
                            _FilterButton(
                              title: l10n.shoppingListRemaining,
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
                            Text(
                              l10n.shoppingListItems(filteredItems.length).toUpperCase(),
                              style: const TextStyle(
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
                        child: AkeliShoppingRow(
                          item: item,
                          isChecked: item.isChecked,
                          isUsLocale: isUsLocale,
                          locale: localeName,
                          onToggle: () {
                            ref.read(shoppingListProvider.notifier).toggleItem(item.id, !item.isChecked);
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


