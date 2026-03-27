import '../database.dart';

class DirectConversationsWithOtherUserTable
    extends SupabaseTable<DirectConversationsWithOtherUserRow> {
  @override
  String get tableName => 'direct_conversations_with_other_user';

  @override
  DirectConversationsWithOtherUserRow createRow(Map<String, dynamic> data) =>
      DirectConversationsWithOtherUserRow(data);
}

class DirectConversationsWithOtherUserRow extends SupabaseDataRow {
  DirectConversationsWithOtherUserRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DirectConversationsWithOtherUserTable();

  int? get requesterId => getField<int>('requester_id');
  set requesterId(int? value) => setField<int>('requester_id', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);

  String? get otherUserName => getField<String>('other_user_name');
  set otherUserName(String? value) =>
      setField<String>('other_user_name', value);

  int? get otherUserId => getField<int>('other_user_id');
  set otherUserId(int? value) => setField<int>('other_user_id', value);
}
