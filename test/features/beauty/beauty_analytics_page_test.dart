import 'package:flutter/material.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/beauty/beauty_analytics_page.dart';
import 'package:akeli/providers/beauty_plan_provider.dart';
import 'package:akeli/shared/models/beauty_log.dart';
import 'package:akeli/shared/models/beauty_plan.dart';

void main() {
  final testLogs = [
    BeautyLog(
      id: 'log-1',
      userId: 'user-1',
      hairLengthCm: 18.0,
      hairStrengthScore: 8.0,
      hairThicknessScore: 8.0,
      hairSheddingRate: 'low',
      skinHydrationLevel: 9.0,
      skinClarityScore: 8.0,
      checkinNotes: 'Super pousse ce mois-ci!',
      loggedAt: DateTime(2026, 7, 21),
    ),
    BeautyLog(
      id: 'log-0',
      userId: 'user-1',
      hairLengthCm: 15.0,
      hairStrengthScore: 7.0,
      hairThicknessScore: 7.0,
      hairSheddingRate: 'moderate',
      skinHydrationLevel: 7.0,
      skinClarityScore: 7.0,
      checkinNotes: 'Bilan initial',
      loggedAt: DateTime(2026, 6, 21),
    ),
  ];

  final testPlan = BeautyPlan(
    id: 'plan-1',
    userId: 'user-1',
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 31),
    createdAt: DateTime(2026, 7, 1),
    slots: const [
      BeautyPlanSlot(
        id: 'slot-1',
        planId: 'plan-1',
        dayNumber: 1,
        weekNumber: 1,
        dayOfWeek: 1,
        routineCategory: 'hair',
        stepStage: 'daily_hydration',
        frequencyTier: 'daily',
        recipeId: 'rec-1',
        isCompleted: true,
      ),
      BeautyPlanSlot(
        id: 'slot-2',
        planId: 'plan-1',
        dayNumber: 1,
        weekNumber: 1,
        dayOfWeek: 1,
        routineCategory: 'skin',
        stepStage: 'daily_hydration',
        frequencyTier: 'daily',
        recipeId: 'rec-2',
        isCompleted: false,
      ),
    ],
  );

  testWidgets('BeautyAnalyticsPage renders header, metrics, and logs history', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBeautyPlanProvider.overrideWith((ref) async => testPlan),
          beautyLogsProvider.overrideWith((ref) async => testLogs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: BeautyAnalyticsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Suivi Beauté & Rituals'), findsOneWidget);
    expect(find.text('Tableau de Bord Beauté 👑'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget); // 1 out of 2 slots completed
    expect(find.text('18.0 cm'), findsOneWidget);
    expect(find.text('+3.0 cm gagnés'), findsOneWidget);
    expect(find.text('9/10'), findsOneWidget);
    expect(find.text('Super pousse ce mois-ci!'), findsOneWidget);
    expect(find.text('Bilan initial'), findsOneWidget);
  });
}
