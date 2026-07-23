import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/settings/settings_page.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/core/locale_provider.dart';
import 'package:akeli/shared/models/user_profile.dart';
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
  final testProfile = UserProfile(
    id: 'test_user',
    username: 'Marie Akeli',
    email: 'marie@akeli.com',
    onboardingDone: true,
    beautyOnboardingDone: true,
    isCreator: false,
    createdAt: DateTime.now(),
  );

  testWidgets('SettingsPage renders Beauty menu options when appMode is Beauty', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
          userProfileProvider.overrideWith((ref) async => testProfile),
          isPremiumProvider.overrideWith((ref) => false),
          localeProvider.overrideWith(FakeLocaleNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Suivi Rituel Beauté'), findsOneWidget);
    expect(find.text('Remèdes & Recettes Favoris'), findsOneWidget);
    expect(find.text('Diagnostic Cheveux & Peau'), findsOneWidget);
    expect(find.text('Planification des Soins'), findsOneWidget);
  });

  testWidgets('SettingsPage renders Nutrition menu options when appMode is Nutrition', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeNutritionModeNotifier.new),
          userProfileProvider.overrideWith((ref) async => testProfile),
          isPremiumProvider.overrideWith((ref) => false),
          localeProvider.overrideWith(FakeLocaleNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: SettingsPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Suivi nutritionnel'), findsOneWidget);
    expect(find.text('Recettes Sauvegardées'), findsOneWidget);
    expect(find.text('Santé & Objectifs'), findsOneWidget);
    expect(find.text('Planning des repas'), findsOneWidget);
  });
}
