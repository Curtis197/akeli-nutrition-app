import 'package:akeli/core/router.dart';
import 'package:akeli/features/beauty/beauty_onboarding_page.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/shared/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Records the exact arguments BeautyOnboardingPage's submit handler passes
/// to completeBeautyOnboarding, without touching Supabase/auth at all —
/// this fully overrides the method body rather than calling super, so the
/// real UserProfileNotifier.build()'s dependency on currentUserProvider is
/// never exercised.
class _RecordingUserProfileNotifier extends UserProfileNotifier {
  bool wasCalled = false;
  Map<String, dynamic>? capturedArgs;

  @override
  Future<UserProfile?> build() async => null;

  @override
  Future<void> completeBeautyOnboarding({
    required String hairType,
    required String porosity,
    required String skinType,
    required String scalpType,
    required List<String> beautyGoals,
    List<String> skinConcerns = const [],
    double hairLengthCm = 15,
    double hairStrengthScore = 7,
    double hairThicknessScore = 7,
    String hairSheddingRate = 'moderate',
    double skinHydrationLevel = 7,
    double skinClarityScore = 7,
    String checkinNotes = 'Premier journal de bord initial',
  }) async {
    wasCalled = true;
    capturedArgs = {
      'hairType': hairType,
      'porosity': porosity,
      'skinType': skinType,
      'scalpType': scalpType,
      'beautyGoals': beautyGoals,
      'skinConcerns': skinConcerns,
      'hairLengthCm': hairLengthCm,
      'hairStrengthScore': hairStrengthScore,
      'hairThicknessScore': hairThicknessScore,
      'hairSheddingRate': hairSheddingRate,
      'skinHydrationLevel': skinHydrationLevel,
      'skinClarityScore': skinClarityScore,
      'checkinNotes': checkinNotes,
    };
  }
}

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

  testWidgets(
    'BeautyOnboardingPage completes all 5 wizard steps, taps the final submit '
    'button, calls completeBeautyOnboarding with the accumulated form data, '
    'and navigates away on success',
    (WidgetTester tester) async {
      final fakeNotifier = _RecordingUserProfileNotifier();

      final testRouter = GoRouter(
        initialLocation: '/beauty-onboarding-test',
        routes: [
          GoRoute(
            path: '/beauty-onboarding-test',
            builder: (context, state) => const BeautyOnboardingPage(),
          ),
          GoRoute(
            path: AkeliRoutes.home,
            builder: (context, state) => const Scaffold(body: Text('Home Placeholder')),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProfileNotifierProvider.overrideWith(() => fakeNotifier),
          ],
          child: MaterialApp.router(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('fr'),
            routerConfig: testRouter,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Hair — change porosity from its default 'medium' to 'high'.
      expect(find.text('Profil Beauté Botanique'), findsOneWidget);
      await tester.ensureVisible(find.text('Fortement Poreuse (Écailles ouvertes)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fortement Poreuse (Écailles ouvertes)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();

      // Step 2: Skin — uncheck the default 'dehydration' concern, check 'acne_imperfections'.
      expect(find.textContaining('Diagnostic Cutané Profond'), findsOneWidget);
      await tester.ensureVisible(find.text('💧 Déshydratation Profonde & Perte d\'Éclat'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('💧 Déshydratation Profonde & Perte d\'Éclat'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('🌋 Boutons & Imperfections'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🌋 Boutons & Imperfections'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();

      // Step 3: Goals — uncheck the default 'skin_moisture' goal, check 'skin_anti_spot'.
      expect(find.textContaining('Objectifs Beauté & Priorités'), findsOneWidget);
      await tester.ensureVisible(find.text('💧 Hydratation & Souplesse Cutanée'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('💧 Hydratation & Souplesse Cutanée'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('🌖 Atténuation des Taches & Hyperpigmentation'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🌖 Atténuation des Taches & Hyperpigmentation'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();

      // Step 4: First Beauty Log — leave every slider/field at its default value.
      expect(find.textContaining('Premier Bilan Initial'), findsOneWidget);
      await tester.tap(find.text('Étape Suivante ➔'));
      await tester.pumpAndSettle();

      // Step 5: Resume & Confirmation — tap the final submit button.
      expect(find.textContaining('Résumé & Confirmation'), findsOneWidget);
      await tester.tap(find.text('Confirmer & Générer Mon Plan 30 Jours ✨'));
      await tester.pumpAndSettle();

      // completeBeautyOnboarding was called exactly once, with the exact
      // accumulated form data (defaults except the 3 fields changed above).
      expect(fakeNotifier.wasCalled, isTrue);
      expect(
        fakeNotifier.capturedArgs,
        equals({
          'hairType': '4C',
          'porosity': 'high',
          'skinType': 'mixte_t',
          'scalpType': 'normal',
          'beautyGoals': ['hair_growth', 'hair_moisture', 'skin_glow', 'skin_anti_spot'],
          'skinConcerns': ['hyperpigmentation', 'acne_imperfections'],
          'hairLengthCm': 15.0,
          'hairStrengthScore': 7.0,
          'hairThicknessScore': 7.0,
          'hairSheddingRate': 'moderate',
          'skinHydrationLevel': 7.0,
          'skinClarityScore': 7.0,
          'checkinNotes': 'Bilan initial du profil beauté',
        }),
      );

      // A success navigation away from the onboarding wizard occurred.
      expect(find.text('Home Placeholder'), findsOneWidget);
      expect(find.byType(BeautyOnboardingPage), findsNothing);
    },
  );
}
