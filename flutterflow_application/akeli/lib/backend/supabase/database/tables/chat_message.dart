import '../database.dart';

class ChatMessageTable extends SupabaseTable<ChatMessageRow> {
  @override
  String get tableName => 'chat_message';

  @override
  ChatMessageRow createRow(Map<String, dynamic> data) => ChatMessageRow(data);
}

class ChatMessageRow extends SupabaseDataRow {
  ChatMessageRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChatMessageTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get content => getField<String>('content');
  set content(String? value) => setField<String>('content', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);

  bool? get received => getField<bool>('received');
  set received(bool? value) => setField<bool>('received', value);

  List<int> get readBy => getListField<int>('read_by');
  set readBy(List<int>? value) => setListField<int>('read_by', value);
}
