import '../database.dart';

class TestLogTable extends SupabaseTable<TestLogRow> {
  @override
  String get tableName => 'test_log';

  @override
  TestLogRow createRow(Map<String, dynamic> data) => TestLogRow(data);
}

class TestLogRow extends SupabaseDataRow {
  TestLogRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TestLogTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get source => getField<String>('source');
  set source(String? value) => setField<String>('source', value);

  String? get message => getField<String>('message');
  set message(String? value) => setField<String>('message', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  double? get numberTestdouble => getField<double>('number_test(double)');
  set numberTestdouble(double? value) =>
      setField<double>('number_test(double)', value);

  int? get numberTestint => getField<int>('number_test(int)');
  set numberTestint(int? value) => setField<int>('number_test(int)', value);
}
