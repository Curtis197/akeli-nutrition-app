import '../database.dart';

class UnitTable extends SupabaseTable<UnitRow> {
  @override
  String get tableName => 'unit';

  @override
  UnitRow createRow(Map<String, dynamic> data) => UnitRow(data);
}

class UnitRow extends SupabaseDataRow {
  UnitRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UnitTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
