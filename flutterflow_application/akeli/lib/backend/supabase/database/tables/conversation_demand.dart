import '../database.dart';

class ConversationDemandTable extends SupabaseTable<ConversationDemandRow> {
  @override
  String get tableName => 'conversation_demand';

  @override
  ConversationDemandRow createRow(Map<String, dynamic> data) =>
      ConversationDemandRow(data);
}

class ConversationDemandRow extends SupabaseDataRow {
  ConversationDemandRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationDemandTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  bool? get accepted => getField<bool>('accepted');
  set accepted(bool? value) => setField<bool>('accepted', value);

  bool? get grouped => getField<bool>('grouped');
  set grouped(bool? value) => setField<bool>('grouped', value);

  int? get destinedUser => getField<int>('destined_user');
  set destinedUser(int? value) => setField<int>('destined_user', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);
}
