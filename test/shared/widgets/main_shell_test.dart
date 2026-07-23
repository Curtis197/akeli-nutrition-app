// test/shared/widgets/main_shell_test.dart
//
// FINDING #5 (Medium) — main_shell.dart:47 hardcodes 'Routines'/'Remèdes'.
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations_en.dart';
import 'package:akeli/l10n/app_localizations_fr.dart';
import 'package:akeli/shared/widgets/main_shell.dart';

void main() {
  group('mainShellTabLabels (Finding #5)', () {
    test('beauty-mode tab labels are fully localized in English — no hardcoded French', () {
      final l10n = AppLocalizationsEn();
      final labels = mainShellTabLabels(l10n, true);
      expect(labels, [l10n.navHome, l10n.mainShellTabRoutines, l10n.mainShellTabRemedies, l10n.navCommunity]);
      expect(labels, isNot(contains('Remèdes')));
    });

    test('beauty-mode tab labels are fully localized in French', () {
      final l10n = AppLocalizationsFr();
      final labels = mainShellTabLabels(l10n, true);
      expect(labels, [l10n.navHome, l10n.mainShellTabRoutines, l10n.mainShellTabRemedies, l10n.navCommunity]);
    });

    test('nutrition-mode tab labels are unaffected', () {
      final l10n = AppLocalizationsEn();
      final labels = mainShellTabLabels(l10n, false);
      expect(labels, [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity]);
    });
  });
}
