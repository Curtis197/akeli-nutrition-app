import '../database.dart';

class NotificationTemplatesTable
    extends SupabaseTable<NotificationTemplatesRow> {
  @override
  String get tableName => 'notification_templates';

  @override
  NotificationTemplatesRow createRow(Map<String, dynamic> data) =>
      NotificationTemplatesRow(data);
}

class NotificationTemplatesRow extends SupabaseDataRow {
  NotificationTemplatesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NotificationTemplatesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get type => getField<String>('type')!;
  set type(String value) => setField<String>('type', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  dynamic get titleTemplate => getField<dynamic>('title_template')!;
  set titleTemplate(dynamic value) =>
      setField<dynamic>('title_template', value);

  dynamic get bodyTemplate => getField<dynamic>('body_template')!;
  set bodyTemplate(dynamic value) => setField<dynamic>('body_template', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get channel => getField<String>('channel');
  set channel(String? value) => setField<String>('channel', value);
}
