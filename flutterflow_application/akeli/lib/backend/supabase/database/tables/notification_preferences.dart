import '../database.dart';

class NotificationPreferencesTable
    extends SupabaseTable<NotificationPreferencesRow> {
  @override
  String get tableName => 'notification_preferences';

  @override
  NotificationPreferencesRow createRow(Map<String, dynamic> data) =>
      NotificationPreferencesRow(data);
}

class NotificationPreferencesRow extends SupabaseDataRow {
  NotificationPreferencesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NotificationPreferencesTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  bool? get chatNotifications => getField<bool>('chat_notifications');
  set chatNotifications(bool? value) =>
      setField<bool>('chat_notifications', value);

  bool? get mealReminders => getField<bool>('meal_reminders');
  set mealReminders(bool? value) => setField<bool>('meal_reminders', value);

  bool? get emailNotifications => getField<bool>('email_notifications');
  set emailNotifications(bool? value) =>
      setField<bool>('email_notifications', value);

  bool? get pushNotifications => getField<bool>('push_notifications');
  set pushNotifications(bool? value) =>
      setField<bool>('push_notifications', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  bool? get groupingEnabled => getField<bool>('grouping_enabled');
  set groupingEnabled(bool? value) => setField<bool>('grouping_enabled', value);

  bool? get groupingWindowMinutes => getField<bool>('grouping_window_minutes');
  set groupingWindowMinutes(bool? value) =>
      setField<bool>('grouping_window_minutes', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  bool? get demandNotifications => getField<bool>('demand_notifications');
  set demandNotifications(bool? value) =>
      setField<bool>('demand_notifications', value);
}
