import '../database.dart';

class MessageReadTable extends SupabaseTable<MessageReadRow> {
  @override
  String get tableName => 'message_read';

  @override
  MessageReadRow createRow(Map<String, dynamic> data) => MessageReadRow(data);
}

class MessageReadRow extends SupabaseDataRow {
  MessageReadRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MessageReadTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get chatMessageId => getField<int>('chat_message_id');
  set chatMessageId(int? value) => setField<int>('chat_message_id', value);
}
