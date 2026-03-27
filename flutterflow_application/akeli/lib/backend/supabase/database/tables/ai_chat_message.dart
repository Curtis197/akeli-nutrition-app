import '../database.dart';

class AiChatMessageTable extends SupabaseTable<AiChatMessageRow> {
  @override
  String get tableName => 'ai_chat_message';

  @override
  AiChatMessageRow createRow(Map<String, dynamic> data) =>
      AiChatMessageRow(data);
}

class AiChatMessageRow extends SupabaseDataRow {
  AiChatMessageRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiChatMessageTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  String? get conversationId => getField<String>('conversation_id');
  set conversationId(String? value) =>
      setField<String>('conversation_id', value);

  DateTime? get messageTime => getField<DateTime>('message_time');
  set messageTime(DateTime? value) => setField<DateTime>('message_time', value);
}
