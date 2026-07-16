import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/auth/auth_page.dart';
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
  group('AuthPage', () {
    testWidgets('shows AKELI brand header', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pump();
      expect(find.text('AKELI'), findsOneWidget);
    });

    testWidgets('shows S\'inscrire and Se connecter tabs', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pump();
      expect(find.text("S'inscrire"), findsOneWidget);
      // AnimatedCrossFade keeps both children in the tree, so 'Se connecter'
      // appears in both the pill tab and the login form submit button.
      expect(find.text('Se connecter'), findsWidgets);
    });

    testWidgets('sign-up form validates empty email', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pumpAndSettle();
      // Scroll 'Commencer' into view — the form may extend below the test viewport.
      final submitBtn = find.text('Commencer');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();
      expect(find.text('Email requis'), findsOneWidget);
    });

    testWidgets('switching to login tab shows login heading', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pump();
      // Tap the first 'Se connecter' — the pill tab, not the login button.
      // AnimatedCrossFade keeps both in the tree so .first selects the tab.
      await tester.tap(find.text('Se connecter').first);
      await tester.pumpAndSettle();
      expect(find.text('Heureux de vous revoir !'), findsOneWidget);
    });

    testWidgets('shows native Google button on non-web platforms', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pumpAndSettle();
      expect(find.text('Continuer avec Google'), findsOneWidget);
    });

    testWidgets('forgot-password dialog shows localized copy and validates empty email',
        (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pumpAndSettle();
      // Switch to the login tab (first 'Se connecter' is the pill tab).
      await tester.tap(find.text('Se connecter').first);
      await tester.pumpAndSettle();
      final forgotLink = find.text('Mot de passe oublié ?');
      await tester.ensureVisible(forgotLink);
      await tester.tap(forgotLink);
      await tester.pumpAndSettle();

      expect(
        find.text('Entrez votre adresse email pour recevoir un lien de réinitialisation.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Envoyer'));
      await tester.pumpAndSettle();
      expect(find.text('Email requis'), findsOneWidget);

      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(find.text('Envoyer'), findsNothing);
    });
  });
}
