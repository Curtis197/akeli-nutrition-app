import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:akeli/providers/badge_sync_provider.dart';
import 'package:akeli/providers/notifications_provider.dart';

class MockBadgeController extends Mock implements BadgeController {}

void main() {
  late MockBadgeController mockController;
  ProviderContainer? container;

  setUp(() {
    mockController = MockBadgeController();
    when(() => mockController.updateBadgeCount(any())).thenAnswer((_) async {});
    when(() => mockController.removeBadge()).thenAnswer((_) async {});
  });

  tearDown(() {
    container?.dispose();
  });

  test('badgeSyncProvider calls updateBadgeCount when unread count is positive', () async {
    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) async => 3),
      ],
    );

    container!.read(badgeSyncProvider);
    await Future.delayed(Duration.zero);

    verify(() => mockController.updateBadgeCount(3)).called(1);
    verifyNever(() => mockController.removeBadge());
  });

  test('badgeSyncProvider calls removeBadge when unread count is zero', () async {
    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) async => 0),
      ],
    );

    container!.read(badgeSyncProvider);
    await Future.delayed(Duration.zero);

    verify(() => mockController.removeBadge()).called(1);
    verifyNever(() => mockController.updateBadgeCount(any()));
  });

  test('badgeSyncProvider does not throw when the controller call fails', () async {
    when(() => mockController.updateBadgeCount(any())).thenThrow(Exception('platform error'));

    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) async => 5),
      ],
    );

    expect(() => container!.read(badgeSyncProvider), returnsNormally);
    await Future.delayed(Duration.zero);

    verify(() => mockController.updateBadgeCount(5)).called(1);
  });

  test('badgeSyncProvider handles error from unreadNotificationCountProvider', () async {
    container = ProviderContainer(
      overrides: [
        badgeControllerProvider.overrideWithValue(mockController),
        unreadNotificationCountProvider.overrideWith((ref) => Future<int>.error(Exception('boom'))),
      ],
    );

    container!.read(badgeSyncProvider);
    await Future.delayed(Duration.zero);

    verifyNever(() => mockController.updateBadgeCount(any()));
    verifyNever(() => mockController.removeBadge());
  });
}
