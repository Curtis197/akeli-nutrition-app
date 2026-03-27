import '../database.dart';

class PrivateConversationTable extends SupabaseTable<PrivateConversationRow> {
  @override
  String get tableName => 'private_conversation';

  @override
  PrivateConversationRow createRow(Map<String, dynamic> data) =>
      PrivateConversationRow(data);
}

class PrivateConversationRow extends SupabaseDataRow {
  PrivateConversationRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PrivateConversationTable();

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  int? get user1 => getField<int>('user_1');
  set user1(int? value) => setField<int>('user_1', value);

  int? get user2 => getField<int>('user_2');
  set user2(int? value) => setField<int>('user_2', value);
}
