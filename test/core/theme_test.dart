import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/mode_provider.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;
  group('AkeliColors', () {
    test('primary is deep teal #00504A', () {
      expect(AkeliColors.primary, const Color(0xFF00504A));
    });
    test('primaryContainer is #006A63', () {
      expect(AkeliColors.primaryContainer, const Color(0xFF006A63));
    });
    test('surface is white #FFFFFF', () {
      expect(AkeliColors.surface, const Color(0xFFFFFFFF));
    });
    test('surfaceContainerHighest is #E4E3D8', () {
      expect(AkeliColors.surfaceContainerHighest, const Color(0xFFE4E3D8));
    });
    test('secondaryContainer is mint #C3EAE5', () {
      expect(AkeliColors.secondaryContainer, const Color(0xFFC3EAE5));
    });
  });

  group('getAppModeColor customPrimary override (Finding #6 — Area F dependency)', () {
    test('returns customPrimary when provided, overriding the mode default', () {
      const custom = Color(0xFF123456);
      expect(getAppModeColor(AppMode.beauty, customPrimary: custom), custom);
    });

    test('falls back to the mode default when customPrimary is null', () {
      expect(getAppModeColor(AppMode.beauty), const Color(0xFF8A3B58));
    });
  });
}
