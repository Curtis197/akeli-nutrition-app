import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BeautyOnboardingPage renders 4-step wizard with First Beauty Log baseline correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BeautyOnboardingPage(),
        ),
      ),
    );

    // Step 1
    expect(find.text('Profil Beauté Botanique'), findsOneWidget);
    expect(find.textContaining('Empreinte Capillaire'), findsOneWidget);
    expect(find.textContaining('4C — Crépu Très Serré'), findsOneWidget);
    expect(find.text('Étape Suivante ➔'), findsOneWidget);

    // Tap Next → Step 2
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Diagnostic Cutané Profond'), findsOneWidget);

    // Tap Next → Step 3
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Objectifs Beauté & Priorités'), findsOneWidget);

    // Tap Next → Step 4 (First Beauty Log Check-in)
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Premier Bilan Initial'), findsOneWidget);
    expect(find.textContaining('Longueur Actuelle des Cheveux'), findsOneWidget);
    expect(find.text('Valider mon Premier Bilan & Plan ✨'), findsOneWidget);
  });
}
