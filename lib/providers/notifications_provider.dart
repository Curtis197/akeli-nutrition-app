import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/supabase_client.dart';
import 'auth_provider.dart';

final _logger = appLogger;

// ---------------------------------------------------------------------------
// notificationsProvider
// Fetches the 50 most recent notifications for the current user.
// ---------------------------------------------------------------------------

final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    _logger.provider('notificationsProvider → [] (no user)');
    return [];
  }

  _logger.provider('notificationsProvider build() | userId: ${user.id}');
  ref.onDispose(() => _logger.provider('notificationsProvider disposed'));

  final client = ref.watch(supabaseClientProvider);

  _logger.db(
      'BEFORE | table: notification | op: SELECT | userId: ${user.id}');
  try {
    final data = await client
        .from('notification')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(50);

    final rows = List<Map<String, dynamic>>.from(data as List);
    _logger.db('AFTER | table: notification | rows: ${rows.length}');

    if (rows.isEmpty) {
      _logger.rls(
          'Zero rows | table: notification | userId: ${user.id} | possible RLS block');
    }

    _logger.provider(
        'notificationsProvider → data | count: ${rows.length}');
    return rows;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls(
          'Permission denied | table: notification | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      _logger.db(
          'ERROR | table: notification | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    _logger.provider('notificationsProvider → error | ${e.message}');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// unreadNotificationCountProvider
// Returns the count of unread notifications. Used for the bell badge and,
// via badgeSyncProvider, the OS app-icon badge. Same is_read = false
// definition as the STEP 4b query in supabase/functions/send-push-notification
// — keep both in sync if either changes.
// ---------------------------------------------------------------------------

final unreadNotificationCountProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;

  _logger.provider(
      'unreadNotificationCountProvider build() | userId: ${user.id}');
  ref.onDispose(
      () => _logger.provider('unreadNotificationCountProvider disposed'));

  final client = ref.watch(supabaseClientProvider);

  _logger.db(
      'BEFORE | table: notification | op: SELECT unread count | userId: ${user.id}');
  try {
    final response = await client
        .from('notification')
        .select()
        .eq('user_id', user.id)
        .eq('is_read', false)
        .count(CountOption.exact);

    final count = response.count;
    _logger.db('AFTER | table: notification | unread count: $count');
    _logger.provider(
        'unreadNotificationCountProvider → data | count: $count');
    return count;
  } on PostgrestException catch (e, st) {
    _logger.db(
        'ERROR | table: notification | unread count | code: ${e.code}',
        error: e,
        stackTrace: st);
    _logger.provider(
        'unreadNotificationCountProvider → error | ${e.message}');
    return 0;
  }
});

// ---------------------------------------------------------------------------
// markAllNotificationsRead
// Called from NotificationsPage.initState(). Updates is_read = true for all
// unread notifications, then invalidates both providers.
// ---------------------------------------------------------------------------

Future<void> markAllNotificationsRead(WidgetRef ref) async {
  final user = ref.read(currentUserProvider);
  if (user == null) return;

  final client = ref.read(supabaseClientProvider);

  _logger.db(
      'BEFORE | table: notification | op: UPDATE is_read | userId: ${user.id}');
  try {
    await client
        .from('notification')
        .update({'is_read': true})
        .eq('user_id', user.id)
        .eq('is_read', false);

    _logger.db(
        'AFTER | table: notification | op: UPDATE is_read | success');
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      _logger.rls(
          'Permission denied | table: notification | UPDATE | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      _logger.db(
          'ERROR | table: notification | UPDATE is_read | code: ${e.code}',
          error: e,
          stackTrace: st);
    }
  }

  ref.invalidate(notificationsProvider);
  ref.invalidate(unreadNotificationCountProvider);
}
