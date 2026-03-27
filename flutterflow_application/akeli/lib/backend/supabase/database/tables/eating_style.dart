import '../database.dart';

class EatingStyleTable extends SupabaseTable<EatingStyleRow> {
  @override
  String get tableName => 'eating_style';

  @override
  EatingStyleRow createRow(Map<String, dynamic> data) => EatingStyleRow(data);
}

class EatingStyleRow extends SupabaseDataRow {
  EatingStyleRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => EatingStyleTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);
}
