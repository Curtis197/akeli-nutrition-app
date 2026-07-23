import 'package:flutter/material.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/beauty/widgets/today_beauty_routines_widget.dart';
import 'package:akeli/providers/beauty_plan_provider.dart';
import 'package:akeli/shared/models/beauty_plan.dart';

void main() {
  group('TodayBeautyRoutinesWidget Tests', () {
    testWidgets('renders today routines header and slots', (WidgetTester tester) async {
      final now = DateTime.now();

      final mockPlan = BeautyPlan(
        id: 'plan-1',
        userId: 'user-1',
        startDate: now,
        endDate: now.add(const Duration(days: 30)),
        createdAt: now,
        slots: [
          BeautyPlanSlot(
            id: 'slot-today-1',
            planId: 'plan-1',
            dayOfWeek: now.weekday,
            // dayNumber is a plan-relative offset from startDate (day 1 =
            // startDate itself), not the calendar day-of-month — startDate
            // is `now` above, so day 1 is today.
            dayNumber: 1,
            routineCategory: 'hair',
            stepStage: 'Soin Hydratant Matinal',
            frequencyTier: 'daily',
            recipeId: 'r-1',
            isCompleted: false,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBeautyPlanProvider.overrideWith((ref) async => mockPlan),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('fr'),
            home: Scaffold(
              body: SingleChildScrollView(
                child: TodayBeautyRoutinesWidget(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Vos Rituels du Jour 👑'), findsOneWidget);
      expect(find.text('Planning (30j)'), findsOneWidget);
      expect(find.text('Soin Hydratant Matinal'), findsOneWidget);
    });
  });
}
