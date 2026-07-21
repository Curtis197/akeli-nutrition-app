import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/widgets/color_set_modal.dart';

void main() {
  group('ColorSetModal Widget Tests', () {
    testWidgets('renders color presets and allows selection', (WidgetTester tester) async {
      ColorSetPreset? selectedPreset;

      await tester.pumpWidget(
        MaterialApp(
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
      );

      // Open modal
      await tester.tap(find.text('Open Color Selector'));
      await tester.pumpAndSettle();

      expect(find.text('Personnaliser le Thème de Couleurs'), findsOneWidget);
      expect(find.text('Rose & Gold (Beauty)'), findsOneWidget);

      // Select Rose & Gold preset
      await tester.tap(find.text('Rose & Gold (Beauty)'));
      await tester.pumpAndSettle();

      // Tap apply button
      await tester.tap(find.byKey(const Key('apply_color_set_button')));
      await tester.pumpAndSettle();

      expect(selectedPreset, isNotNull);
      expect(selectedPreset!.name, equals('Rose & Gold (Beauty)'));
      expect(selectedPreset!.primary, equals(const Color(0xFF8A3B58)));
    });
  });
}
