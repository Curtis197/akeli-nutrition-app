import '../database.dart';

class ConversationDemandDeleteTable
    extends SupabaseTable<ConversationDemandDeleteRow> {
  @override
  String get tableName => 'conversation_demand_delete';

  @override
  ConversationDemandDeleteRow createRow(Map<String, dynamic> data) =>
      ConversationDemandDeleteRow(data);
}

class ConversationDemandDeleteRow extends SupabaseDataRow {
  ConversationDemandDeleteRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationDemandDeleteTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);

  int? get destinedUserId => getField<int>('destined_user_id');
  set destinedUserId(int? value) => setField<int>('destined_user_id', value);
}
