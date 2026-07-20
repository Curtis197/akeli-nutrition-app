import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/features/meal_planner/widgets/meal_planner_view_toggle.dart';
import 'package:akeli/providers/meal_plan_provider.dart';

Widget _wrap(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('MealPlannerViewToggle', () {
    testWidgets('tapping Jour calls onChanged with day', (tester) async {
      PlannerViewMode? changedTo;
      await tester.pumpWidget(_wrap(MealPlannerViewToggle(
        value: PlannerViewMode.week,
        onChanged: (mode) => changedTo = mode,
      )));

      await tester.tap(find.byKey(const Key('planner-view-toggle-day')));
      await tester.pump();

      expect(changedTo, PlannerViewMode.day);
    });

    testWidgets('tapping the already-active segment does not call onChanged', (tester) async {
      var callCount = 0;
      await tester.pumpWidget(_wrap(MealPlannerViewToggle(
        value: PlannerViewMode.week,
        onChanged: (_) => callCount++,
      )));

      await tester.tap(find.byKey(const Key('planner-view-toggle-week')));
      await tester.pump();

      expect(callCount, 0);
    });
  });
}
