import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BeautyOnboardingPage renders 5-step wizard with Step 5 Resume & Confirmation correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: Locale('fr'),
          home: BeautyOnboardingPage(),
        ),
      ),
    );

    // Step 1: Hair
    expect(find.text('Profil Beauté Botanique'), findsOneWidget);
    expect(find.textContaining('Empreinte Capillaire'), findsOneWidget);
    expect(find.textContaining('4C — Crépu Très Serré'), findsOneWidget);
    expect(find.text('Étape Suivante ➔'), findsOneWidget);

    // Tap Next → Step 2: Skin
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Diagnostic Cutané Profond'), findsOneWidget);

    // Tap Next → Step 3: Goals
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Objectifs Beauté & Priorités'), findsOneWidget);

    // Tap Next → Step 4: First Beauty Log Check-in
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Premier Bilan Initial'), findsOneWidget);
    expect(find.textContaining('Longueur Actuelle des Cheveux'), findsOneWidget);

    // Tap Next → Step 5: Resume & Confirmation
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Résumé & Confirmation'), findsOneWidget);
    expect(find.textContaining('👑 Profil Capillaire'), findsOneWidget);
    expect(find.textContaining('✨ Diagnostic Cutané'), findsOneWidget);
    expect(find.textContaining('📊 Mesures du Premier Bilan'), findsOneWidget);
    expect(find.text('Confirmer & Générer Mon Plan 30 Jours ✨'), findsOneWidget);
  });
}
