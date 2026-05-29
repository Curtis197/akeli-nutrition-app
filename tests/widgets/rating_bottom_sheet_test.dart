// tests/widgets/rating_bottom_sheet_test.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/rating_bottom_sheet.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

class _MockRatingNotifier extends RatingNotifier {
  @override
  FutureOr<void> build() {}

  @override
  Future<void> submitRating(
    String mealPlanEntryId, {
    required int rating,
    int? ratingTaste,
    int? ratingEase,
    int? ratingSatiety,
  }) async {}
}

Widget _buildSheet() => ProviderScope(
      overrides: [ratingProvider.overrideWith(_MockRatingNotifier.new)],
      child: const MaterialApp(
        home: Scaffold(
          body: RatingBottomSheet(mealPlanEntryId: 'test-entry-id'),
        ),
      ),
    );

void main() {
  group('RatingBottomSheet', () {
    testWidgets('submit button is disabled initially', (tester) async {
      await tester.pumpWidget(_buildSheet());

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Soumettre'),
      );
      expect(btn.onPressed, isNull);
    });

    testWidgets('submit button enabled after tapping an overall star', (tester) async {
      await tester.pumpWidget(_buildSheet());

      await tester.tap(find.byKey(const Key('overall-star-4')));
      await tester.pump();

      final btn = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Soumettre'),
      );
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('renders three optional dimension rows', (tester) async {
      await tester.pumpWidget(_buildSheet());

      expect(find.text('Goût'), findsOneWidget);
      expect(find.text('Facilité'), findsOneWidget);
      expect(find.text('Satiété'), findsOneWidget);
    });

    testWidgets('Passer button is present and tappable', (tester) async {
      await tester.pumpWidget(_buildSheet());

      expect(find.widgetWithText(TextButton, 'Passer'), findsOneWidget);
      await tester.tap(find.widgetWithText(TextButton, 'Passer'));
      await tester.pump();
    });
  });
}
