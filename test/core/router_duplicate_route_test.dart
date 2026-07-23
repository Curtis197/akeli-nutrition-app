// test/core/router_duplicate_route_test.dart
//
// FINDING #4 (Medium) — duplicate GoRoute registration for /onboarding.
// This is a source-hygiene defect (go_router takes the first match, so
// behavior is unaffected), so it's verified with a direct source check
// rather than a runtime GoRouter test.
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('lib/core/router.dart registers AkeliRoutes.onboarding exactly once', () {
    final source = File('lib/core/router.dart').readAsStringSync();
    final matches = 'path: AkeliRoutes.onboarding,'.allMatches(source).length;
    expect(
      matches,
      1,
      reason: 'Expected exactly one "path: AkeliRoutes.onboarding," GoRoute registration, found $matches',
    );
  });

  test('lib/core/router.dart still registers AkeliRoutes.beautyOnboarding exactly once (sanity check)', () {
    final source = File('lib/core/router.dart').readAsStringSync();
    final matches = 'path: AkeliRoutes.beautyOnboarding,'.allMatches(source).length;
    expect(matches, 1);
  });
}
