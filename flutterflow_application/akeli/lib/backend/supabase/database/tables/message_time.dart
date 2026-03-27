import '../database.dart';

class MessageTimeTable extends SupabaseTable<MessageTimeRow> {
  @override
  String get tableName => 'message_time';

  @override
  MessageTimeRow createRow(Map<String, dynamic> data) => MessageTimeRow(data);
}

class MessageTimeRow extends SupabaseDataRow {
  MessageTimeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MessageTimeTable();

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get localCreatedAt => getField<DateTime>('local_created_at');
  set localCreatedAt(DateTime? value) =>
      setField<DateTime>('local_created_at', value);
}
