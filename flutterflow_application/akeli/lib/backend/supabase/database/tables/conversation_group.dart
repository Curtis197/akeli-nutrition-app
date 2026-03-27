import '../database.dart';

class ConversationGroupTable extends SupabaseTable<ConversationGroupRow> {
  @override
  String get tableName => 'conversation_group';

  @override
  ConversationGroupRow createRow(Map<String, dynamic> data) =>
      ConversationGroupRow(data);
}

class ConversationGroupRow extends SupabaseDataRow {
  ConversationGroupRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ConversationGroupTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  int? get conversationId => getField<int>('conversation_id');
  set conversationId(int? value) => setField<int>('conversation_id', value);
}
