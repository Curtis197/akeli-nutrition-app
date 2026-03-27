import '../database.dart';

class ChatConversationTable extends SupabaseTable<ChatConversationRow> {
  @override
  String get tableName => 'chat_conversation';

  @override
  ChatConversationRow createRow(Map<String, dynamic> data) =>
      ChatConversationRow(data);
}

class ChatConversationRow extends SupabaseDataRow {
  ChatConversationRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChatConversationTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  bool? get grouped => getField<bool>('grouped');
  set grouped(bool? value) => setField<bool>('grouped', value);

  String? get lastMessageContent => getField<String>('last_message_content');
  set lastMessageContent(String? value) =>
      setField<String>('last_message_content', value);

  DateTime? get lastMessageTime => getField<DateTime>('last_message_time');
  set lastMessageTime(DateTime? value) =>
      setField<DateTime>('last_message_time', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get creatorId => getField<int>('creator_id');
  set creatorId(int? value) => setField<int>('creator_id', value);

  int? get adminUserId => getField<int>('admin_user_id');
  set adminUserId(int? value) => setField<int>('admin_user_id', value);

  List<int> get conversationParticipantId =>
      getListField<int>('conversation_participant_id');
  set conversationParticipantId(List<int>? value) =>
      setListField<int>('conversation_participant_id', value);
}
