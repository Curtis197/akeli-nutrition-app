import '../database.dart';

class ConversationGroupByNameTable
    extends SupabaseTable<ConversationGroupByNameRow> {
  @override
  String get tableName => 'conversation_group_by_name';

  @override
  ConversationGroupByNameRow createRow(Map<String, dynamic> data) =>
      ConversationGroupByNameRow(data);
}

class ConversationGroupByNameRow extends SupabaseDataRow {
  ConversationGroupByNameRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationGroupByNameTable();

  int? get requesterId => getField<int>('requester_id');
  set requesterId(int? value) => setField<int>('requester_id', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);

  String? get groupName => getField<String>('group_name');
  set groupName(String? value) => setField<String>('group_name', value);
}
