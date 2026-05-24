import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/notifications/notifications_page.dart';
import 'package:akeli/providers/notifications_provider.dart';
import 'package:akeli/providers/auth_provider.dart';

Widget _testApp(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: buildLightTheme(),
        home: child,
      ),
    );

void main() {
  group('NotificationsPage', () {
    testWidgets('shows empty state when no notifications', (tester) async {
      await tester.pumpWidget(_testApp(
        const NotificationsPage(),
        overrides: [
          notificationsProvider.overrideWith((_) async => []),
          unreadNotificationCountProvider.overrideWith((_) async => 0),
          currentUserProvider.overrideWith((_) => null),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Aucune notification'), findsOneWidget);
    });

    testWidgets('shows chat card for message notification', (tester) async {
      final notif = {
        'id': 'n1',
        'type': 'message',
        'title': 'Marie Dupont',
        'body': 'Bonjour !',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {'conversation_id': 'c1', 'sender_id': 's1'},
      };
      await tester.pumpWidget(_testApp(
        const NotificationsPage(),
        overrides: [
          notificationsProvider.overrideWith((_) async => [notif]),
          unreadNotificationCountProvider.overrideWith((_) async => 1),
          currentUserProvider.overrideWith((_) => null),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Marie Dupont'), findsOneWidget);
      expect(find.text('Bonjour !'), findsOneWidget);
    });

    testWidgets('shows request card with Accept/Decline for conversation_request',
        (tester) async {
      final notif = {
        'id': 'n2',
        'type': 'conversation_request',
        'title': 'Jean Martin veut discuter',
        'body': 'Acceptez ou refusez la demande de conversation.',
        'is_read': false,
        'created_at': DateTime.now().toIso8601String(),
        'data': {'request_id': 'r1', 'requester_id': 'u1'},
      };
      await tester.pumpWidget(_testApp(
        const NotificationsPage(),
        overrides: [
          notificationsProvider.overrideWith((_) async => [notif]),
          unreadNotificationCountProvider.overrideWith((_) async => 1),
          currentUserProvider.overrideWith((_) => null),
        ],
      ));
      await tester.pumpAndSettle();
      expect(find.text('Jean Martin veut discuter'), findsOneWidget);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });
  });
}
