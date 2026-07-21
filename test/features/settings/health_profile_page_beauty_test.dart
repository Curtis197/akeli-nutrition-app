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

class FakeBeautyModeNotifier extends ModeNotifier {
  @override
  AppMode build() => AppMode.beauty;
}

class FakeLocaleNotifier extends LocaleNotifier {
  @override
  Locale build() => const Locale('fr');
}

void main() {
  const testBeautyModel = HealthProfileModel(
    hairType: 'Type 4C - Crépu très dense',
    porosity: 'Moyenne',
    skinType: 'Peau Mixte (Zone T brillante)',
    sensitiveScalp: true,
    beautyGoals: ['Pousse & Longueur', 'Éclat du Teint'],
    skinConcerns: ['Hyperpigmentation & Taches'],
  );

  testWidgets('HealthProfilePage renders Beauty parameters when appMode is Beauty', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentModeProvider.overrideWith(FakeBeautyModeNotifier.new),
          healthProfileProvider.overrideWith(() => FakeHealthProfileNotifier(testBeautyModel)),
          localeProvider.overrideWith(FakeLocaleNotifier.new),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HealthProfilePage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Diagnostic & Profil Beauté 🌸'), findsOneWidget);
    expect(find.text('Empreinte Capillaire 👑'), findsOneWidget);
    expect(find.text('Diagnostic Cutané Profond ✨'), findsOneWidget);
    expect(find.text('Objectifs Rituel Beauté 🌸'), findsOneWidget);
    expect(find.text('Type 4C - Crépu très dense'), findsOneWidget);
    expect(find.text('Cuir Chevelu Sensible / Réactif'), findsOneWidget);
  });
}
