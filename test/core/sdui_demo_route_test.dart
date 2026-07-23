// test/core/sdui_demo_route_test.dart
//
// FINDING #2 (Critical, optional sub-task) — SDUI is dead code. This adds a
// brand-new, additive `/sdui-demo` route (no existing route is touched or
// replaced) so the subsystem is finally reachable, and proves it renders.
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/sdui/services/layout_cache_service.dart';
import 'package:akeli/core/sdui/widgets/dynamic_layout_page.dart';
import 'package:akeli/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});

    // Avoid the path_provider platform channel: point Hive at a plain temp dir.
    final tempDir = await Directory.systemTemp.createTemp('akeli_sdui_demo_test');
    Hive.init(tempDir.path);
    await Hive.openBox('layout_cache');
    await Hive.openBox('mode_state');

    // DynamicLayoutPage's LayoutFetchService reads Supabase.instance.client
    // eagerly in a field initializer — it must be initialized even though
    // this test never reaches the network path (cache hit short-circuits it).
    await Supabase.initialize(
      url: 'https://sdui-demo-route-test.supabase.co',
      anonKey: 'test-anon-key-not-real',
    );

    // Pre-seed the cache so fetchLayout() resolves from Hive only — no real
    // network call is made, keeping this test fast and deterministic.
    await LayoutCacheService().cacheLayout(
      mode: 'nutrition',
      layoutId: 'demo-route-test-layout',
      layoutJson: {
        'components': [
          {'type': 'hero_banner', 'config': {'title': 'Demo', 'subtitle': 'SDUI'}},
        ],
      },
    );
  });

  testWidgets('a standalone GoRouter rendering /sdui-demo shows DynamicLayoutPage without throwing', (tester) async {
    final router = GoRouter(
      initialLocation: '/sdui-demo',
      routes: [
        GoRoute(
          path: '/sdui-demo',
          builder: (context, state) => const DynamicLayoutPage(mode: 'nutrition'),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.byType(DynamicLayoutPage), findsOneWidget);
  });
}
