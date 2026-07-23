import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/router.dart';
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

final _testProfile = UserProfile(
  id: 'test_user',
  username: 'Marie Akeli',
  email: 'marie@akeli.com',
  onboardingDone: true,
  beautyOnboardingDone: true,
  isCreator: false,
  createdAt: DateTime.now(),
);

Widget _appUnderTest(AppMode mode) {
  final router = GoRouter(
    initialLocation: '/settings-test',
    routes: [
      GoRoute(
        path: '/settings-test',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AkeliRoutes.mealSchedule,
        builder: (context, state) => const Scaffold(body: Text('MEAL_SCHEDULE_MARKER')),
      ),
      GoRoute(
        path: AkeliRoutes.mealPlanner,
        builder: (context, state) => const Scaffold(body: Text('MEAL_PLANNER_MARKER')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      currentModeProvider.overrideWith(
          mode == AppMode.beauty ? FakeBeautyModeNotifier.new : FakeNutritionModeNotifier.new),
      userProfileProvider.overrideWith((ref) async => _testProfile),
      isPremiumProvider.overrideWith((ref) => false),
      localeProvider.overrideWith(FakeLocaleNotifier.new),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('fr'),
    ),
  );
}

void main() {
  // SettingsPage's menu list is taller than the default 800x600 test
  // viewport. ensureVisible() scrolls the target into the scrollable's
  // viewport, but the resulting on-screen offset can still land under a
  // non-hit-testable overlay near the scroll boundary. Using a tall virtual
  // window avoids needing to scroll at all, which is the reliable fix.
  setUp(() async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first
      ..physicalSize = const Size(800, 2400)
      ..devicePixelRatio = 1.0;
  });

  tearDown(() {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.platformDispatcher.views.first.resetPhysicalSize();
    binding.platformDispatcher.views.first.resetDevicePixelRatio();
  });

  testWidgets(
      'tapping the meal-schedule settings item in Beauty mode navigates to the meal-planner route, not mealSchedule',
      (tester) async {
    await tester.pumpWidget(_appUnderTest(AppMode.beauty));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Planification des Soins'));
    await tester.pumpAndSettle();

    expect(find.text('MEAL_PLANNER_MARKER'), findsOneWidget);
    expect(find.text('MEAL_SCHEDULE_MARKER'), findsNothing);
  });

  testWidgets(
      'tapping the meal-schedule settings item in Nutrition mode still navigates to mealSchedule',
      (tester) async {
    await tester.pumpWidget(_appUnderTest(AppMode.nutrition));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Planning des repas'));
    await tester.pumpAndSettle();

    expect(find.text('MEAL_SCHEDULE_MARKER'), findsOneWidget);
    expect(find.text('MEAL_PLANNER_MARKER'), findsNothing);
  });
}
