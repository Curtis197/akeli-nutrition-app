import '../database.dart';

class TestIndexTable extends SupabaseTable<TestIndexRow> {
  @override
  String get tableName => 'test_index';

  @override
  TestIndexRow createRow(Map<String, dynamic> data) => TestIndexRow(data);
}

class TestIndexRow extends SupabaseDataRow {
  TestIndexRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TestIndexTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
