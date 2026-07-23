import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/shared/widgets/color_set_modal.dart';
import 'package:akeli/providers/color_set_provider.dart';

class MockColorSetNotifier extends ColorSetNotifier {
  @override
  ColorSetPreset build() => ColorSetModal.presets.first;

  @override
  Future<void> selectPreset(ColorSetPreset preset) async {
    state = preset;
  }
}

void main() {
  group('ColorSetModal Widget Tests', () {
    testWidgets('renders color presets and allows selection', (WidgetTester tester) async {
      ColorSetPreset? selectedPreset;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            colorSetProvider.overrideWith(MockColorSetNotifier.new),
          ],
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    selectedPreset = await ColorSetModal.show(context);
                  },
                  child: const Text('Open Color Selector'),
                ),
              ),
            ),
          ),
        ),
      );

      // Open modal
      await tester.tap(find.text('Open Color Selector'));
      await tester.pumpAndSettle();

      expect(find.text('Personnaliser le Thème de Couleurs'), findsOneWidget);
      expect(find.text('Rose & Gold (Beauty)'), findsOneWidget);

      // Select Rose & Gold preset
      await tester.tap(find.text('Rose & Gold (Beauty)'));
      await tester.pumpAndSettle();

      // Tap apply button (ensure visible in scroll view first)
      await tester.ensureVisible(find.byKey(const Key('apply_color_set_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('apply_color_set_button')));
      await tester.pumpAndSettle();

      expect(selectedPreset, isNotNull);
      expect(selectedPreset!.id, equals('rose_beauty'));
      expect(selectedPreset!.primary, equals(const Color(0xFF8A3B58)));
    });
  });
}
