import '../database.dart';

class NotificationTriggersTable extends SupabaseTable<NotificationTriggersRow> {
  @override
  String get tableName => 'notification_triggers';

  @override
  NotificationTriggersRow createRow(Map<String, dynamic> data) =>
      NotificationTriggersRow(data);
}

class NotificationTriggersRow extends SupabaseDataRow {
  NotificationTriggersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => NotificationTriggersTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get templateType => getField<String>('template_type')!;
  set templateType(String value) => setField<String>('template_type', value);

  String get triggerType => getField<String>('trigger_type')!;
  set triggerType(String value) => setField<String>('trigger_type', value);

  String? get cronExpression => getField<String>('cron_expression');
  set cronExpression(String? value) =>
      setField<String>('cron_expression', value);

  String? get eventSource => getField<String>('event_source');
  set eventSource(String? value) => setField<String>('event_source', value);

  dynamic? get conditionLogic => getField<dynamic>('condition_logic');
  set conditionLogic(dynamic? value) =>
      setField<dynamic>('condition_logic', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
