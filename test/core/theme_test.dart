import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/theme.dart';

void main() {
  group('AkeliColors', () {
    test('primary is deep teal #00504A', () {
      expect(AkeliColors.primary, const Color(0xFF00504A));
    });
    test('primaryContainer is #006A63', () {
      expect(AkeliColors.primaryContainer, const Color(0xFF006A63));
    });
    test('surface is warm cream #FCFAEF', () {
      expect(AkeliColors.surface, const Color(0xFFFCFAEF));
    });
    test('surfaceContainerHighest is #E4E3D8', () {
      expect(AkeliColors.surfaceContainerHighest, const Color(0xFFE4E3D8));
    });
    test('secondaryContainer is mint #C3EAE5', () {
      expect(AkeliColors.secondaryContainer, const Color(0xFFC3EAE5));
    });
  });
}
