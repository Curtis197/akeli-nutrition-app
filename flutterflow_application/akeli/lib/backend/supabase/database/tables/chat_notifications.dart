import '../database.dart';

class ChatNotificationsTable extends SupabaseTable<ChatNotificationsRow> {
  @override
  String get tableName => 'chat_notifications';

  @override
  ChatNotificationsRow createRow(Map<String, dynamic> data) =>
      ChatNotificationsRow(data);
}

class ChatNotificationsRow extends SupabaseDataRow {
  ChatNotificationsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ChatNotificationsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  int get conversationId => getField<int>('conversation_id')!;
  set conversationId(int value) => setField<int>('conversation_id', value);

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

  int? get latestMessageId => getField<int>('latest_message_id');
  set latestMessageId(int? value) => setField<int>('latest_message_id', value);

  String? get latestMessagePreview =>
      getField<String>('latest_message_preview');
  set latestMessagePreview(String? value) =>
      setField<String>('latest_message_preview', value);

  int? get unreadCount => getField<int>('unread_count');
  set unreadCount(int? value) => setField<int>('unread_count', value);

  bool? get read => getField<bool>('read');
  set read(bool? value) => setField<bool>('read', value);
}
