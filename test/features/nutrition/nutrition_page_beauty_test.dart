import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/nutrition/nutrition_page.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/core/locale_provider.dart';
import 'package:akeli/shared/models/user_profile.dart';
import 'package:akeli/providers/beauty_plan_provider.dart';
import 'package:akeli/shared/models/beauty_log.dart';
import 'package:akeli/shared/models/beauty_plan.dart';
import 'package:akeli/providers/nutrition_provider.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/l10n/app_localizations.dart';

class FakeBeautyModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.beauty;
}

class FakeNutritionModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.nutrition;
}

class FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('fr');
}

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
    ],
  );

  final testProfile = UserProfile(
    id: 'test_user',
    username: 'Marie Akeli',
    email: 'marie@akeli.com',
    onboardingDone: true,
    beautyOnboardingDone: true,
    isCreator: false,
    createdAt: DateTime.now(),
  );

  testWidgets('NutritionPage renders BeautyAnalyticsPage when mode is Beauty', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
          userProfileProvider.overrideWith((ref) async => testProfile),
          isPremiumProvider.overrideWith((ref) => false),
          localeProvider.overrideWith(FakeLocaleNotifier.new),
          activeBeautyPlanProvider.overrideWith((ref) async => testPlan),
          beautyLogsProvider.overrideWith((ref) async => testLogs),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: NutritionPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Suivi Beauté & Rituals'), findsOneWidget);
    expect(find.text('Tableau de Bord Beauté 👑'), findsOneWidget);
    expect(find.text('18.0 cm'), findsOneWidget);
  });

  testWidgets('NutritionPage renders daily nutrition logs when mode is Nutrition', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeNutritionModeNotifier.new),
          userProfileProvider.overrideWith((ref) async => testProfile),
          isPremiumProvider.overrideWith((ref) => false),
          localeProvider.overrideWith(FakeLocaleNotifier.new),
          dailyNutritionForDateProvider.overrideWith((ref, date) async => null as DailyNutrition?),
          activeNutritionPlanProvider.overrideWith((ref) async => null),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: NutritionPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // In Nutrition mode, title is "Nutrition"
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Aujourd\'hui'), findsNWidgets(2));
    expect(find.text('Semaine'), findsOneWidget);
  });
}
