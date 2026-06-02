import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:akeli/core/notification_handler.dart';

class MockGoRouter extends Mock implements GoRouter {}

RemoteMessage _makeMessage(Map<String, String> data) {
  return RemoteMessage(data: data);
}

void main() {
  late MockGoRouter router;

  setUp(() {
    router = MockGoRouter();
  });

  test('message type routes to DM chat', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(
      _makeMessage({'type': 'message', 'conversation_id': 'conv-123'}),
      router,
    );
    verify(() => router.push('/dm/conv-123')).called(1);
  });

  test('group_message type routes to group detail', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(
      _makeMessage({'type': 'group_message', 'group_id': 'grp-456'}),
      router,
    );
    verify(() => router.push('/group/grp-456/detail')).called(1);
  });

  test('conversation_request type routes to notifications', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(
      _makeMessage({'type': 'conversation_request'}),
      router,
    );
    verify(() => router.push('/notifications')).called(1);
  });

  test('meal_reminder type routes to meal planner', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(
      _makeMessage({'type': 'meal_reminder', 'date': '2026-06-02'}),
      router,
    );
    verify(() => router.push('/meal-planner')).called(1);
  });

  test('unknown type falls back to notifications', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(
      _makeMessage({'type': 'unknown_type'}),
      router,
    );
    verify(() => router.push('/notifications')).called(1);
  });

  test('missing type falls back to notifications', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(_makeMessage({}), router);
    verify(() => router.push('/notifications')).called(1);
  });

  test('message type with missing conversation_id falls back to notifications', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(_makeMessage({'type': 'message'}), router);
    verify(() => router.push('/notifications')).called(1);
  });

  test('group_message type with missing group_id falls back to notifications', () {
    when(() => router.push(any())).thenAnswer((_) async => null);
    handleNotificationTap(_makeMessage({'type': 'group_message'}), router);
    verify(() => router.push('/notifications')).called(1);
  });
}
