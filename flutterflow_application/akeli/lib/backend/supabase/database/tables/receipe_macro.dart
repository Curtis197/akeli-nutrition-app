import '../database.dart';

class ReceipeMacroTable extends SupabaseTable<ReceipeMacroRow> {
  @override
  String get tableName => 'receipe_macro';

  @override
  ReceipeMacroRow createRow(Map<String, dynamic> data) => ReceipeMacroRow(data);
}

class ReceipeMacroRow extends SupabaseDataRow {
  ReceipeMacroRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReceipeMacroTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get type => getField<String>('type');
  set type(String? value) => setField<String>('type', value);

  double? get quantity => getField<double>('quantity');
  set quantity(double? value) => setField<double>('quantity', value);

  String? get unit => getField<String>('unit');
  set unit(String? value) => setField<String>('unit', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get temporaryReceipeId => getField<int>('temporary_receipe_id');
  set temporaryReceipeId(int? value) =>
      setField<int>('temporary_receipe_id', value);
}
