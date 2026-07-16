import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/features/settings/account_page.dart';
import 'package:akeli/providers/auth_provider.dart';
import 'package:akeli/core/theme.dart';

User _user({required List<String> providers}) => User(
      id: 'test-user-id',
      appMetadata: {'provider': providers.first, 'providers': providers},
      userMetadata: const {},
      aud: 'authenticated',
      email: 'test@example.com',
      createdAt: '2026-01-01T00:00:00Z',
    );

User _userWithoutProvidersMetadata() => const User(
      id: 'test-user-id',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      email: 'test@example.com',
      createdAt: '2026-01-01T00:00:00Z',
    );

Widget _testApp(Widget child, {required User? user}) => ProviderScope(
      overrides: [currentUserProvider.overrideWithValue(user)],
      child: MaterialApp(
        theme: buildLightTheme(),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('fr'), Locale('en')],
        locale: const Locale('en'),
        home: child,
      ),
    );

void main() {
  group('AccountPage password section visibility', () {
    testWidgets('shows password section for email users', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _user(providers: ['email'])),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsOneWidget);
    });

    testWidgets('hides password section for Google-only users', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _user(providers: ['google'])),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsNothing);
    });

    testWidgets('shows password section for email+google users', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _user(providers: ['email', 'google'])),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsOneWidget);
    });

    testWidgets('shows password section when providers metadata is absent', (tester) async {
      await tester.pumpWidget(
        _testApp(const AccountPage(), user: _userWithoutProvidersMetadata()),
      );
      await tester.pump();
      expect(find.text('PASSWORD'), findsOneWidget);
    });
  });
}
