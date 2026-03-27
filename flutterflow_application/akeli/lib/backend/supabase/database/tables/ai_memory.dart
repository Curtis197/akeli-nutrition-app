import '../database.dart';

class AiMemoryTable extends SupabaseTable<AiMemoryRow> {
  @override
  String get tableName => 'ai_memory';

  @override
  AiMemoryRow createRow(Map<String, dynamic> data) => AiMemoryRow(data);
}

class AiMemoryRow extends SupabaseDataRow {
  AiMemoryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AiMemoryTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  String get category => getField<String>('category')!;
  set category(String value) => setField<String>('category', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  String? get confidence => getField<String>('confidence');
  set confidence(String? value) => setField<String>('confidence', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
