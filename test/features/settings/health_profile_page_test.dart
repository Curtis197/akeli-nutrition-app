import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/settings/health_profile_page.dart';
import 'package:akeli/providers/health_profile_provider.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:akeli/core/locale_provider.dart';
import 'package:akeli/features/settings/models/health_profile_model.dart';
import 'package:akeli/l10n/app_localizations.dart';

class FakeHealthProfileNotifier extends HealthProfileNotifier {
  final HealthProfileModel _initial;
  FakeHealthProfileNotifier(this._initial);

  @override
  Future<HealthProfileModel> build() async => _initial;
}

class FakeNutritionModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.nutrition;
}

class FakeUsLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('en', 'US');
}

void main() {
  final testNutritionModel = HealthProfileModel(
    sex: 'female',
    birthDate: DateTime(1990, 5, 15),
    heightCm: 170.0, // 170cm == 5'7" via UnitConverter.cmToFeetIn
    weightKg: 70.0,
    targetWeightKg: 65.0,
    activityLevel: 'moderate',
    goalType: 'weight_loss',
    weightGoal: 'loss',
    muscleGoal: 'maintenance',
    targetDate: DateTime.now().add(const Duration(days: 84)),
  );

  testWidgets(
      'HealthProfilePage renders Nutrition age, goal-type and US-locale height fields when appMode is Nutrition',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeNutritionModeNotifier.new),
          healthProfileProvider
              .overrideWith(() => FakeHealthProfileNotifier(testNutritionModel)),
          localeProvider.overrideWith(FakeUsLocaleNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('en', 'US'),
          home: HealthProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Age / birth-date field must render (the deleted date picker row).
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);

    // Goal-type filter chips must render.
    expect(find.text('Weight loss'), findsOneWidget);

    // Weight-goal section label must render.
    expect(find.text('Weight goal'), findsOneWidget);

    // US-locale height must render as feet/inches (170cm == 5'7"),
    // not the blank-cm-field bug: the single _heightCtrl TextField is
    // never populated for US users, so its (missing) text would never
    // contain '5'/'7' either way — this asserts the real fix, not a
    // false positive.
    final textFields = tester.widgetList<TextField>(find.byType(TextField));
    final texts = textFields.map((tf) => tf.controller?.text).toList();
    expect(texts, contains('5'));
    expect(texts, contains('7'));
  });
}
