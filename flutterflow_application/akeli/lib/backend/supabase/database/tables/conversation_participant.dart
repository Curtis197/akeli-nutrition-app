import '../database.dart';

class ConversationParticipantTable
    extends SupabaseTable<ConversationParticipantRow> {
  @override
  String get tableName => 'conversation_participant';

  @override
  ConversationParticipantRow createRow(Map<String, dynamic> data) =>
      ConversationParticipantRow(data);
}

class ConversationParticipantRow extends SupabaseDataRow {
  ConversationParticipantRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationParticipantTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);
}
