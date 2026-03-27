import '../database.dart';

class NotificationGroupsTable extends SupabaseTable<NotificationGroupsRow> {
  @override
  String get tableName => 'notification_groups';

  @override
  NotificationGroupsRow createRow(Map<String, dynamic> data) =>
      NotificationGroupsRow(data);
}

class NotificationGroupsRow extends SupabaseDataRow {
  NotificationGroupsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NotificationGroupsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  String get notificationType => getField<String>('notification_type')!;
  set notificationType(String value) =>
      setField<String>('notification_type', value);

  String get groupKey => getField<String>('group_key')!;
  set groupKey(String value) => setField<String>('group_key', value);

  int? get count => getField<int>('count');
  set count(int? value) => setField<int>('count', value);

  String get latestTitle => getField<String>('latest_title')!;
  set latestTitle(String value) => setField<String>('latest_title', value);

  String get latestBody => getField<String>('latest_body')!;
  set latestBody(String value) => setField<String>('latest_body', value);

  dynamic get latestMetadata => getField<dynamic>('latest_metadata')!;
  set latestMetadata(dynamic value) =>
      setField<dynamic>('latest_metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  bool? get read => getField<bool>('read');
  set read(bool? value) => setField<bool>('read', value);

  String? get channel => getField<String>('channel');
  set channel(String? value) => setField<String>('channel', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);
}
