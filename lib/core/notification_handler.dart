import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'logger.dart';
import 'router.dart';

final _logger = appLogger;

// Must be top-level — Flutter isolates this in a separate context for background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Notification row is already inserted server-side. Log only — no UI updates here.
  _logger.i('FCM background message | type: ${message.data['type']} | id: ${message.messageId}');
}

void handleNotificationTap(RemoteMessage message, GoRouter router) {
  final type = message.data['type'] as String?;
  _logger.userAction('Notification tapped | type: $type', screen: 'NotificationTap');

  if (type == 'message') {
    final conversationId = message.data['conversation_id'] as String?;
    if (conversationId != null) {
      router.push(AkeliRoutes.dmChatPath(conversationId));
      return;
    }
  } else if (type == 'group_message') {
    final groupId = message.data['group_id'] as String?;
    if (groupId != null) {
      router.push(AkeliRoutes.groupDetailPath(groupId));
      return;
    }
  } else if (type == 'meal_reminder') {
    router.push(AkeliRoutes.mealPlanner);
    return;
  } else if (type == 'conversation_request') {
    router.push(AkeliRoutes.notifications);
    return;
  } else if (type == 'link') {
    final route = message.data['route'] as String?;
    if (route != null) {
      router.push(route);
      return;
    }
  }

  // Fallback — unknown type, missing type, or missing data keys
  router.push(AkeliRoutes.notifications);
}
