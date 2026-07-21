import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/beauty/widgets/beauty_checkin_sheet.dart';

void main() {
  group('BeautyCheckinSheet Widget Tests', () {
    testWidgets('renders checkin sheet title and save button', (WidgetTester tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  submittedData = await BeautyCheckinSheet.show(
                    context,
                    userId: 'test-user-123',
                    initialHairLengthCm: 30.0,
                    initialHairStrengthScore: 8.0,
                  );
                },
                child: const Text('Open Checkin'),
              ),
            ),
          ),
        ),
      );

      // Tap to open bottom sheet
      await tester.tap(find.text('Open Checkin'));
      await tester.pumpAndSettle();

      expect(find.text('Beauty Check-In & Evolution'), findsOneWidget);
      expect(find.byKey(const Key('save_beauty_checkin_button')), findsOneWidget);

      // Tap save button
      await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['user_id'], equals('test-user-123'));
      expect(submittedData!['hair_length_cm'], equals(30.0));
      expect(submittedData!['hair_strength_score'], equals(8.0));
    });
  });
}
