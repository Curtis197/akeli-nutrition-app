import '../database.dart';

class ReceipeTagsTable extends SupabaseTable<ReceipeTagsRow> {
  @override
  String get tableName => 'receipe_tags';

  @override
  ReceipeTagsRow createRow(Map<String, dynamic> data) => ReceipeTagsRow(data);
}

class ReceipeTagsRow extends SupabaseDataRow {
  ReceipeTagsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReceipeTagsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  String? get color => getField<String>('color');
  set color(String? value) => setField<String>('color', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get temporaryReceipeId => getField<int>('temporary_receipe_id');
  set temporaryReceipeId(int? value) =>
      setField<int>('temporary_receipe_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
