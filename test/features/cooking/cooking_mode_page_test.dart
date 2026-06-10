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
      // NOTE: passes via portrait _TimerWidget until OrientationBuilder is wired (Task 8)
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
      // NOTE: passes via portrait conditional until OrientationBuilder is wired (Task 8)
      _setLandscape(tester);
      addTearDown(() => _resetView(tester));

      await tester.pumpWidget(_wrap(
        CookingModePage(recipe: _recipe(withTimer: false)),
      ));
      await tester.pump();

      expect(find.text('03:00'), findsNothing);
    });
  });
}
