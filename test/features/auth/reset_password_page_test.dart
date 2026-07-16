import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/auth/reset_password_page.dart';
import 'package:akeli/core/theme.dart';

Widget _testApp(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('fr'),
        home: child,
      ),
    );

void main() {
  group('ResetPasswordPage', () {
    testWidgets('shows localized title', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pump();
      expect(find.text('Réinitialiser votre mot de passe'), findsOneWidget);
    });

    testWidgets('empty submit shows required error', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pumpAndSettle();
      final submit = find.text('Mettre à jour le mot de passe');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Le mot de passe est requis'), findsOneWidget);
    });

    testWidgets('rejects passwords shorter than 8 characters', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'abc123');
      final submit = find.text('Mettre à jour le mot de passe');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Le mot de passe doit faire au moins 8 caractères'),
        findsOneWidget,
      );
    });

    testWidgets('rejects mismatched confirmation', (tester) async {
      await tester.pumpWidget(_testApp(const ResetPasswordPage()));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'longpassword1');
      await tester.enterText(find.byType(TextFormField).last, 'different1');
      final submit = find.text('Mettre à jour le mot de passe');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(
        find.text('Les mots de passe ne correspondent pas'),
        findsOneWidget,
      );
    });
  });
}
