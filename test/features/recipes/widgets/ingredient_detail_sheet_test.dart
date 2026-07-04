import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/recipes/widgets/ingredient_detail_sheet.dart';
import 'package:akeli/providers/ingredient_provider.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:akeli/shared/models/recipe_usage.dart';

const _ingredient = RecipeIngredient(
  id: 'ri1',
  ingredientId: 'ing1',
  name: 'Rice',
  quantity: 200,
  unit: 'g',
  isOptional: false,
);

Widget _wrap(Widget child, {required List<Override> overrides}) => ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('en'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('IngredientDetailSheet -- recipe usage section', () {
    testWidgets('renders a recipe card when mealPlanId is provided and recipes resolve', (tester) async {
      await tester.pumpWidget(_wrap(
        const IngredientDetailSheet(ingredient: _ingredient, mealPlanId: 'plan1'),
        overrides: [
          ingredientDetailProvider.overrideWith((ref, id) async => null),
          ingredientRecipesInPlanProvider.overrideWith((ref, args) async => const [
                RecipeUsage(id: 'r1', title: 'Jollof Rice', prepTimeMin: 10, cookTimeMin: 30),
              ]),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Jollof Rice'), findsOneWidget);
      expect(find.byKey(const Key('recipe-usage-card')), findsOneWidget);
    });

    testWidgets('omits the section when the recipe list is empty', (tester) async {
      await tester.pumpWidget(_wrap(
        const IngredientDetailSheet(ingredient: _ingredient, mealPlanId: 'plan1'),
        overrides: [
          ingredientDetailProvider.overrideWith((ref, id) async => null),
          ingredientRecipesInPlanProvider.overrideWith((ref, args) async => const []),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe-usage-card')), findsNothing);
    });

    testWidgets('omits the section entirely when mealPlanId is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const IngredientDetailSheet(ingredient: _ingredient),
        overrides: [
          ingredientDetailProvider.overrideWith((ref, id) async => null),
        ],
      ));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('recipe-usage-card')), findsNothing);
    });
  });
}
