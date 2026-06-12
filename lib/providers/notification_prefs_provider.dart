import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/supabase_client.dart';
import 'auth_provider.dart';

class NotificationPrefs {
  final bool pushEnabled;
  final bool chatEnabled;
  final bool mealRemindersEnabled;
  final bool dmRequestsEnabled;

  const NotificationPrefs({
    this.pushEnabled = true,
    this.chatEnabled = true,
    this.mealRemindersEnabled = false,
    this.dmRequestsEnabled = true,
  });

  factory NotificationPrefs.fromJson(Map<String, dynamic> json) {
    return NotificationPrefs(
      pushEnabled: json['push'] as bool? ?? true,
      chatEnabled: json['chat'] as bool? ?? true,
      mealRemindersEnabled: json['meal_reminders'] as bool? ?? false,
      dmRequestsEnabled: json['dm_requests'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'push': pushEnabled,
        'chat': chatEnabled,
        'meal_reminders': mealRemindersEnabled,
        'dm_requests': dmRequestsEnabled,
      };

  NotificationPrefs copyWith({
    bool? pushEnabled,
    bool? chatEnabled,
    bool? mealRemindersEnabled,
    bool? dmRequestsEnabled,
  }) {
    return NotificationPrefs(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      chatEnabled: chatEnabled ?? this.chatEnabled,
      mealRemindersEnabled: mealRemindersEnabled ?? this.mealRemindersEnabled,
      dmRequestsEnabled: dmRequestsEnabled ?? this.dmRequestsEnabled,
    );
  }
}

// ---------------------------------------------------------------------------
// notificationPrefsLoader — loads current prefs from user_profile
// ---------------------------------------------------------------------------

final notificationPrefsLoader =
    FutureProvider.autoDispose<NotificationPrefs>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    appLogger.provider('notificationPrefsLoader → default (no user)');
    return const NotificationPrefs();
  }

  appLogger.provider('notificationPrefsLoader build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('notificationPrefsLoader disposed'));

  final client = ref.watch(supabaseClientProvider);

  appLogger.db(
      'BEFORE | table: user_profile | op: SELECT notification_prefs | userId: ${user.id}');
  try {
    final data = await client
        .from('user_profile')
        .select('notification_prefs')
        .eq('id', user.id)
        .single();

    appLogger.db('AFTER | table: user_profile | op: SELECT notification_prefs');
    final prefs = NotificationPrefs.fromJson(
        (data['notification_prefs'] as Map<String, dynamic>?) ?? {});
    appLogger.provider('notificationPrefsLoader → data | $prefs');
    return prefs;
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls(
          'Permission denied | table: user_profile | userId: ${user.id}',
          error: e,
          stackTrace: st);
    } else {
      appLogger.db(
          'ERROR | table: user_profile | notification_prefs | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
    }
    return const NotificationPrefs();
  }
});

// ---------------------------------------------------------------------------
// NotificationPrefsNotifier — holds live toggle state + persists on save()
// ---------------------------------------------------------------------------

class NotificationPrefsNotifier extends StateNotifier<NotificationPrefs> {
  final Ref _ref;

  NotificationPrefsNotifier(this._ref, NotificationPrefs initial)
      : super(initial) {
    appLogger.provider('NotificationPrefsNotifier init | state: ${initial.toJson()}');
  }

  void setPush(bool value) {
    appLogger.userAction('Push notifications toggled: $value',
        screen: 'NotificationSettingsPage');
    state = state.copyWith(pushEnabled: value);
  }

  void setChat(bool value) {
    appLogger.userAction('Chat notifications toggled: $value',
        screen: 'NotificationSettingsPage');
    state = state.copyWith(chatEnabled: value);
  }

  void setMealReminders(bool value) {
    appLogger.userAction('Meal reminders toggled: $value',
        screen: 'NotificationSettingsPage');
    state = state.copyWith(mealRemindersEnabled: value);
  }

  void setDmRequests(bool value) {
    appLogger.userAction('DM requests notifications toggled: $value',
        screen: 'NotificationSettingsPage');
    state = state.copyWith(dmRequestsEnabled: value);
  }

  void syncFromDb(NotificationPrefs prefs) {
    appLogger.provider('NotificationPrefsNotifier.syncFromDb() | ${prefs.toJson()}');
    state = prefs;
  }

  Future<void> save() async {
    final user = _ref.read(currentUserProvider);
    if (user == null) {
      appLogger.provider('NotificationPrefsNotifier.save() | no user — skipped');
      return;
    }

    final client = _ref.read(supabaseClientProvider);
    final payload = state.toJson();

    appLogger.db(
        'BEFORE | table: user_profile | op: UPDATE notification_prefs | userId: ${user.id}');
    try {
      await client
          .from('user_profile')
          .update({'notification_prefs': payload})
          .eq('id', user.id);

      appLogger.db(
          'AFTER | table: user_profile | op: UPDATE notification_prefs | success');
      appLogger.provider('NotificationPrefsNotifier saved | ${state.toJson()}');
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        appLogger.rls(
            'Permission denied | table: user_profile | UPDATE notification_prefs | userId: ${user.id}',
            error: e,
            stackTrace: st);
      } else {
        appLogger.db(
            'ERROR | table: user_profile | UPDATE notification_prefs | code: ${e.code} | ${e.message}',
            error: e,
            stackTrace: st);
      }
      rethrow;
    }
  }
}

final notificationPrefsProvider = StateNotifierProvider.autoDispose<
    NotificationPrefsNotifier, NotificationPrefs>((ref) {
  // ref.read (not watch) avoids making this provider a dependency of
  // notificationPrefsLoader. If we used ref.watch, the provider would be
  // invalidated and recreated when the FutureProvider resolves, which can
  // mark widgets dirty mid-build-frame → "wrong build scope" assertion.
  final initial =
      ref.read(notificationPrefsLoader).valueOrNull ?? const NotificationPrefs();
  final notifier = NotificationPrefsNotifier(ref, initial);

  // When the loader resolves after this notifier is created, push the real
  // DB values into state. ref.listen callbacks fire after the build frame.
  ref.listen<AsyncValue<NotificationPrefs>>(
    notificationPrefsLoader,
    (_, next) => next.whenData(notifier.syncFromDb),
  );

  return notifier;
});
