import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/features/auth/auth_page.dart';
import 'package:akeli/core/theme.dart';

Widget _testApp(Widget child) => ProviderScope(
      child: MaterialApp(
        theme: buildLightTheme(),
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
      expect(find.text('Se connecter'), findsOneWidget);
    });

    testWidgets('sign-up form validates empty email', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pump();
      // Tap the Commencer button without filling fields
      final submitBtn = find.text('Commencer');
      await tester.tap(submitBtn);
      await tester.pump();
      expect(find.text('Email requis'), findsOneWidget);
    });

    testWidgets('switching to login tab shows login heading', (tester) async {
      await tester.pumpWidget(_testApp(const AuthPage()));
      await tester.pump();
      // Tap 'Se connecter' tab
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.text('Heureux de vous revoir !'), findsOneWidget);
    });
  });
}
