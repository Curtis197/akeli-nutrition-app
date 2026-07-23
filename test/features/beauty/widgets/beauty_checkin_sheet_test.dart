import 'package:flutter/material.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/features/beauty/widgets/beauty_checkin_sheet.dart';

void main() {
  group('BeautyCheckinSheet Widget Tests', () {
    testWidgets('renders checkin sheet title and save button', (WidgetTester tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
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

      expect(find.text('Bilan Beauté & Évolution'), findsOneWidget);
      expect(find.byKey(const Key('save_beauty_checkin_button')), findsOneWidget);

      // Tap save button
      await tester.ensureVisible(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      expect(submittedData!['userId'], equals('test-user-123'));
      expect(submittedData!['hairLengthCm'], equals(30.0));
      expect(submittedData!['hairStrengthScore'], equals(8.0));
    });

    testWidgets(
        'tapping the "High" shedding-rate chip reaches the save payload as hairSheddingRate: "high"',
        (WidgetTester tester) async {
      Map<String, dynamic>? submittedData;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('fr'),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  submittedData = await BeautyCheckinSheet.show(
                    context,
                    userId: 'test-user-789',
                  );
                },
                child: const Text('Open Checkin'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Checkin'));
      await tester.pumpAndSettle();

      // Default is 'normal' (no chip selected) until the user picks one —
      // confirm the "High" chip exists and tap it.
      expect(find.byKey(const Key('shedding_rate_chip_high')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const Key('shedding_rate_chip_high')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('shedding_rate_chip_high')));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save_beauty_checkin_button')));
      await tester.pumpAndSettle();

      expect(submittedData, isNotNull);
      // Fails against the current code: there is no chip control at all, so
      // `hairSheddingRate` can never become anything but the hardcoded
      // default `'normal'`.
      expect(submittedData!['hairSheddingRate'], equals('high'));
    });
  });
}
