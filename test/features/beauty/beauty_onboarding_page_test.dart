import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BeautyOnboardingPage renders 3-step wizard correctly with Rosewood theme, hair dropdown, and deep skin profile', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: BeautyOnboardingPage(),
        ),
      ),
    );

    // Verify Step 1 elements
    expect(find.text('Profil Beauté Botanique'), findsOneWidget);
    expect(find.textContaining('Empreinte Capillaire'), findsOneWidget);
    expect(find.textContaining('4C — Crépu Très Serré'), findsOneWidget);
    expect(find.text('Étape Suivante ➔'), findsOneWidget);

    // Tap Next to navigate to Step 2
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();

    // Verify Step 2 elements
    expect(find.textContaining('Diagnostic Cutané Profond'), findsOneWidget);
    expect(find.textContaining('Peau Mixte'), findsOneWidget);

    // Tap Next to navigate to Step 3
    await tester.tap(find.text('Étape Suivante ➔'));
    await tester.pumpAndSettle();

    // Verify Step 3 elements
    expect(find.textContaining('Objectifs Beauté & Priorités'), findsOneWidget);
    expect(find.text('Générer Mon Plan 30 Jours ✨'), findsOneWidget);
  });
}
