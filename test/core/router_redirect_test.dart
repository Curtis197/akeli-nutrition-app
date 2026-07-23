// test/core/router_redirect_test.dart
//
// FINDING #1 (Critical) — router infinite redirect loop.
// See docs/BEAUTY_MODE_BRANCH_REVIEW_2026-07-23.md Area G.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/providers/mode_provider.dart';

void main() {
  group('computeAkeliRedirect — pure unit tests', () {
    test('unauthenticated user is redirected to /auth', () {
      final result = computeAkeliRedirect(
        isAuthenticated: false,
        isRecovery: false,
        currentPath: AkeliRoutes.home,
        hasProfile: false,
        onboardingDone: false,
        beautyOnboardingDone: false,
        currentMode: AppMode.nutrition,
      );
      expect(result, AkeliRoutes.auth);
    });

    test('password recovery event redirects to /reset-password regardless of path', () {
      final result = computeAkeliRedirect(
        isAuthenticated: true,
        isRecovery: true,
        currentPath: AkeliRoutes.home,
        hasProfile: true,
        onboardingDone: true,
        beautyOnboardingDone: true,
        currentMode: AppMode.nutrition,
      );
      expect(result, AkeliRoutes.resetPassword);
    });

    test('nutrition onboarding incomplete redirects to /onboarding', () {
      final result = computeAkeliRedirect(
        isAuthenticated: true,
        isRecovery: false,
        currentPath: AkeliRoutes.home,
        hasProfile: true,
        onboardingDone: false,
        beautyOnboardingDone: false,
        currentMode: AppMode.nutrition,
      );
      expect(result, AkeliRoutes.onboarding);
    });

    test('fully onboarded nutrition user on home gets no redirect', () {
      final result = computeAkeliRedirect(
        isAuthenticated: true,
        isRecovery: false,
        currentPath: AkeliRoutes.home,
        hasProfile: true,
        onboardingDone: true,
        beautyOnboardingDone: false,
        currentMode: AppMode.nutrition,
      );
      expect(result, isNull);
    });

    test('beauty user who completed both onboardings gets no redirect', () {
      final result = computeAkeliRedirect(
        isAuthenticated: true,
        isRecovery: false,
        currentPath: AkeliRoutes.home,
        hasProfile: true,
        onboardingDone: true,
        beautyOnboardingDone: true,
        currentMode: AppMode.beauty,
      );
      expect(result, isNull);
    });

    group('FINDING #1 regression — stale beauty mode + incomplete nutrition onboarding', () {
      const onboardingDone = false;
      const beautyOnboardingDone = false;
      const currentMode = AppMode.beauty;

      test('from /onboarding: stays put (no bounce to beauty onboarding)', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.onboarding,
          hasProfile: true,
          onboardingDone: onboardingDone,
          beautyOnboardingDone: beautyOnboardingDone,
          currentMode: currentMode,
        );
        expect(result, isNull);
      });

      test('from /onboarding/beauty: bounces back to /onboarding', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyOnboarding,
          hasProfile: true,
          onboardingDone: onboardingDone,
          beautyOnboardingDone: beautyOnboardingDone,
          currentMode: currentMode,
        );
        expect(result, AkeliRoutes.onboarding);
      });

      test('from /home: bounces to /onboarding', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.home,
          hasProfile: true,
          onboardingDone: onboardingDone,
          beautyOnboardingDone: beautyOnboardingDone,
          currentMode: currentMode,
        );
        expect(result, AkeliRoutes.onboarding);
      });
    });

    group('FINDING #3 regression — beauty gate keyed to destination route, not just currentMode', () {
      test('nutrition-mode user cannot bypass the gate by deep-linking to /beauty-analytics', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyAnalytics,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: false,
          currentMode: AppMode.nutrition,
        );
        expect(result, AkeliRoutes.beautyOnboarding);
      });

      test('same deep link is allowed once beauty onboarding is actually done', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyAnalytics,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: true,
          currentMode: AppMode.nutrition,
        );
        expect(result, isNull);
      });

      test('gate is not restricted to the nutrition/beauty binary — health mode is also gated by route', () {
        final result = computeAkeliRedirect(
          isAuthenticated: true,
          isRecovery: false,
          currentPath: AkeliRoutes.beautyAnalytics,
          hasProfile: true,
          onboardingDone: true,
          beautyOnboardingDone: false,
          currentMode: AppMode.health,
        );
        expect(result, AkeliRoutes.beautyOnboarding);
      });
    });
  });

  group('FINDING #1 regression — integration test', () {
    testWidgets(
      'beauty-mode user with incomplete nutrition onboarding does not crash with GoException',
      (tester) async {
        final router = GoRouter(
          initialLocation: AkeliRoutes.onboarding,
          redirect: (context, state) => computeAkeliRedirect(
            isAuthenticated: true,
            isRecovery: false,
            currentPath: state.uri.path,
            hasProfile: true,
            onboardingDone: false,
            beautyOnboardingDone: false,
            currentMode: AppMode.beauty,
          ),
          routes: [
            GoRoute(path: AkeliRoutes.onboarding, builder: (c, s) => const Scaffold(body: Text('onboarding'))),
            GoRoute(path: AkeliRoutes.beautyOnboarding, builder: (c, s) => const Scaffold(body: Text('beauty-onboarding'))),
            GoRoute(path: AkeliRoutes.home, builder: (c, s) => const Scaffold(body: Text('home'))),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pumpAndSettle();

        // Desired behavior: no crash, and successfully renders the onboarding page.
        expect(tester.takeException(), isNull);
        expect(find.text('onboarding'), findsOneWidget);
      },
    );
  });
}
