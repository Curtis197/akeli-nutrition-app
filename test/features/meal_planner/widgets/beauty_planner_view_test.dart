import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/meal_planner/widgets/beauty_planner_view.dart';
import 'package:akeli/providers/beauty_plan_provider.dart';
import 'package:akeli/shared/models/beauty_plan.dart';

void main() {
  group('BeautyPlannerView Widget Tests', () {
    testWidgets('renders empty state when beauty plan is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBeautyPlanProvider.overrideWith((ref) => Future.value(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BeautyPlannerView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Aucun Plan de Soin Actif'), findsOneWidget);
      expect(find.text('Générer Mon Plan Beauté'), findsOneWidget);
    });

    testWidgets('renders monthly routines when beauty plan is loaded', (WidgetTester tester) async {
      final mockPlan = BeautyPlan(
        id: 'plan-1',
        userId: 'user-1',
        startDate: DateTime(2026, 8, 1),
        endDate: DateTime(2026, 8, 31),
        createdAt: DateTime.now(),
        slots: [
          BeautyPlanSlot(
            id: 'slot-1',
            planId: 'plan-1',
            dayOfWeek: 1,
            dayNumber: 1,
            routineCategory: 'hair',
            stepStage: 'daily_hydration',
            frequencyTier: 'daily',
            recipeId: 'rec-1',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBeautyPlanProvider.overrideWith((ref) => Future.value(mockPlan)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: BeautyPlannerView(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Mon Plan de Soins Mensuel'), findsOneWidget);
      expect(find.text('💧 Soins Quotidiens (Hydratation)'), findsOneWidget);
    });
  });
}
