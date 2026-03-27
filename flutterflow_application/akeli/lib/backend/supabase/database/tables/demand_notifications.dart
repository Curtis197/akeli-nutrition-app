import '../database.dart';

class DemandNotificationsTable extends SupabaseTable<DemandNotificationsRow> {
  @override
  String get tableName => 'demand_notifications';

  @override
  DemandNotificationsRow createRow(Map<String, dynamic> data) =>
      DemandNotificationsRow(data);
}

class DemandNotificationsRow extends SupabaseDataRow {
  DemandNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DemandNotificationsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  int get demandId => getField<int>('demand_id')!;
  set demandId(int value) => setField<int>('demand_id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  int get senderUserId => getField<int>('sender_user_id')!;
  set senderUserId(int value) => setField<int>('sender_user_id', value);

  String get senderName => getField<String>('sender_name')!;
  set senderName(String value) => setField<String>('sender_name', value);

  String get title => getField<String>('title')!;
  set title(String value) => setField<String>('title', value);

  String get body => getField<String>('body')!;
  set body(String value) => setField<String>('body', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  String get notificationType => getField<String>('notification_type')!;
  set notificationType(String value) =>
      setField<String>('notification_type', value);

  bool? get read => getField<bool>('read');
  set read(bool? value) => setField<bool>('read', value);
}
