import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../core/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';

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
            icon: const Icon(Icons.arrow_back, color: AkeliColors.primary),
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
          l10n.shoppingListTitle,
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
              icon: Icons.shopping_cart_outlined,
              title: l10n.shoppingListTitle,
              subtitle: l10n.shoppingListEmpty,
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

          final locale = Localizations.localeOf(context).languageCode;

          // Calculate pricing summaries
          final totalCostUsed = items.fold<double>(0, (sum, item) => sum + item.estimatedPrice);
          final costPaidUsed = items.where((item) => item.isChecked).fold<double>(0, (sum, item) => sum + item.estimatedPrice);
          final costLeftUsed = totalCostUsed - costPaidUsed;

          final totalCostBought = items.fold<double>(0, (sum, item) => sum + item.estimatedPriceBought);
          final costPaidBought = items.where((item) => item.isChecked).fold<double>(0, (sum, item) => sum + item.estimatedPriceBought);
          final costLeftBought = totalCostBought - costPaidBought;

          // Get currency symbols from the first item, default to EUR
          final currency = items.isNotEmpty ? items.first.currency : 'EUR';
          final currencySymbol = items.isNotEmpty ? items.first.currencySymbol : '€';
          
          String formatPrice(double val) {
            if (currency == 'EUR') {
              return '${val.toStringAsFixed(2).replaceAll('.', ',')} €';
            } else {
              return '$currencySymbol${val.toStringAsFixed(2)}';
            }
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Column(
                    children: [
                      // Pricing Summary Card
                      if (totalCostUsed > 0) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AkeliColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              // Cart Cost (To Buy) Row (Main highlight)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        locale == 'en' ? 'Cart Cost (To Buy)' : 'Coût du panier (À acheter)',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AkeliColors.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        locale == 'en' ? 'Recipe portion: ${formatPrice(totalCostUsed)}' : 'Consommé : ${formatPrice(totalCostUsed)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w400,
                                          color: AkeliColors.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    formatPrice(totalCostBought),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AkeliColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Divider(height: 1, thickness: 1),
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.shoppingListCostPaid,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AkeliColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatPrice(costPaidBought),
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: AkeliColors.onSurface,
                                          ),
                                        ),
                                        Text(
                                          '(${formatPrice(costPaidUsed)})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: AkeliColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 1,
                                    height: 44,
                                    color: AkeliColors.outlineVariant.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          l10n.shoppingListCostLeft,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AkeliColors.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          formatPrice(costLeftBought),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: costLeftBought > 0 ? AkeliColors.secondary : AkeliColors.onSurfaceVariant,
                                          ),
                                        ),
                                        Text(
                                          '(${formatPrice(costLeftUsed)})',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w400,
                                            color: AkeliColors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
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


