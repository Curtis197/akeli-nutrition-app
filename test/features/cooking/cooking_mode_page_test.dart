import 'package:akeli/core/theme.dart';
import 'package:akeli/features/cooking/cooking_mode_page.dart';
import 'package:akeli/shared/models/recipe.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── helpers ────────────────────────────────────────────────────────────────

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(theme: buildLightTheme(), home: child),
    );

void _setLandscape(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 400);
  tester.view.devicePixelRatio = 1.0;
}

void _setPortrait(WidgetTester tester) {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
}

void _resetView(WidgetTester tester) {
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

Recipe _recipe({
  int stepCount = 3,
  bool withTimer = false,
  bool withImage = false,
  bool withIngredients = false,
}) {
  final ingredients = withIngredients
      ? [
          const RecipeIngredient(
              ingredientId: 'i1',
              name: 'Oignons',
              quantity: 2.0,
              unit: 'pcs',
              isOptional: false),
          const RecipeIngredient(
              ingredientId: 'i2',
              name: 'Huile',
              quantity: 2.0,
              unit: 'cs',
              isOptional: false),
        ]
      : <RecipeIngredient>[];

  final steps = List.generate(
    stepCount,
    (i) => RecipeStep(
      stepNumber: i + 1,
      instruction: 'Instruction étape ${i + 1}',
      durationMin: withTimer ? 3 : null,
      imageUrl: withImage ? 'https://example.com/img.jpg' : null,
      ingredientIds: withIngredients ? ['i1', 'i2'] : [],
    ),
  );

  return Recipe(
    id: 'r1',
    creatorId: 'c1',
    title: 'Test',
    imageUrls: const [],
    prepTimeMin: 5,
    cookTimeMin: 10,
    servings: 2,
    difficulty: 'easy',
    averageRating: 0,
    averageRatingTaste: 0,
    averageRatingEase: 0,
    averageRatingSatiety: 0,
    ratingCount: 0,
    commentCount: 0,
    likeCount: 0,
    saveCount: 0,
    isSaved: false,
    isLiked: false,
    isPublished: true,
    ingredients: ingredients,
    steps: steps,
    tagIds: const [],
    createdAt: DateTime(2026),
  );
}

// ── tests ───────────────────────────────────────────────────────────────────

void main() {
  group('CookingModePage landscape', () {
    testWidgets('top bar shows step counter in landscape', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(CookingModePage(recipe: _recipe())));
      await tester.pump();

      expect(find.text('Étape 1 / 3'), findsOneWidget);
    });

    testWidgets('shows timer pill in landscape when step has duration', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(withTimer: true)),
      ));
      await tester.pump();

      // Timer pill displays MM:SS format
      expect(find.text('03:00'), findsOneWidget);
      // Play icon present (timer not yet running)
      expect(find.byIcon(Icons.play_arrow_rounded), findsWidgets);
    });

    testWidgets('no timer pill in landscape when step has no duration', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(withTimer: false)),
      ));
      await tester.pump();

      expect(find.text('03:00'), findsNothing);
    });

    testWidgets('chevron-right icon advances to next step', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(CookingModePage(recipe: _recipe())));
      await tester.pump();

      expect(find.text('Étape 1 / 3'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Étape 2 / 3'), findsOneWidget);
    });

    testWidgets('chevron-left icon goes to previous step', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(), initialStepIndex: 1),
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.chevron_left_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Étape 1 / 3'), findsOneWidget);
    });

    testWidgets('last step shows check icon instead of chevron', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(stepCount: 1)),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsNothing);
    });

    testWidgets('info icon hidden when step has no ingredients', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(withIngredients: false)),
      ));
      await tester.pump();

      expect(find.byIcon(Icons.info_outline_rounded), findsNothing);
    });

    testWidgets('tapping info icon opens and closes the panel', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(withIngredients: true)),
      ));
      await tester.pump();

      // Panel closed — ingredient names not visible/hittable
      expect(find.text('Oignons  2 pcs').hitTestable(), findsNothing);

      // Open
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Oignons  2 pcs').hitTestable(), findsOneWidget);

      // Close
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Oignons  2 pcs').hitTestable(), findsNothing);
    });

    testWidgets('info panel closes when navigating to next step', (tester) async {
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(withIngredients: true)),
      ));
      await tester.pump();

      // Open panel
      await tester.tap(find.byIcon(Icons.info_outline_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Oignons  2 pcs').hitTestable(), findsOneWidget);

      // Navigate
      await tester.tap(find.byIcon(Icons.chevron_right_rounded).first);
      await tester.pumpAndSettle();
      expect(find.text('Oignons  2 pcs').hitTestable(), findsNothing);
    });
  });

  group('CookingModePage portrait', () {
    testWidgets('portrait layout shows Suivant and Précédent buttons', (tester) async {
      _setPortrait(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(CookingModePage(recipe: _recipe())));
      await tester.pump();

      expect(find.text('Suivant'), findsOneWidget);
      expect(find.text('Précédent'), findsOneWidget);
    });

    testWidgets('portrait last step shows Terminer button', (tester) async {
      _setPortrait(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(stepCount: 1)),
      ));
      await tester.pump();

      expect(find.text('Terminer'), findsOneWidget);
    });
  });
}
