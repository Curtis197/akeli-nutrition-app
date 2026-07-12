import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_app_badge_control/flutter_app_badge_control.dart';
import '../core/logger.dart';
import 'notifications_provider.dart';

final _logger = appLogger;

abstract class BadgeController {
  Future<void> updateBadgeCount(int count);
  Future<void> removeBadge();
}

class _AppBadgeController implements BadgeController {
  @override
  Future<void> updateBadgeCount(int count) =>
      FlutterAppBadgeControl.updateBadgeCount(count);

  @override
  Future<void> removeBadge() => FlutterAppBadgeControl.removeBadge();
}

final badgeControllerProvider =
    Provider<BadgeController>((ref) => _AppBadgeController());

final badgeSyncProvider = Provider.autoDispose<void>((ref) {
  _logger.provider('badgeSyncProvider build()');
  ref.onDispose(() => _logger.provider('badgeSyncProvider disposed'));

  final controller = ref.watch(badgeControllerProvider);

  ref.listen<AsyncValue<int>>(unreadNotificationCountProvider, (previous, next) {
    next.when(
      data: (count) async {
        try {
          if (count == 0) {
            await controller.removeBadge();
          } else {
            await controller.updateBadgeCount(count);
          }
          _logger.provider('badgeSyncProvider → synced | count: $count');
        } catch (e, st) {
          _logger.provider('badgeSyncProvider → ERROR | $e', error: e, stackTrace: st);
        }
      },
      loading: () {},
      error: (e, st) => _logger.provider('badgeSyncProvider → error from unreadNotificationCountProvider | $e', error: e, stackTrace: st),
    );
  }, fireImmediately: true);
});
