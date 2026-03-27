import '../database.dart';

class DietTypeTable extends SupabaseTable<DietTypeRow> {
  @override
  String get tableName => 'diet_type';

  @override
  DietTypeRow createRow(Map<String, dynamic> data) => DietTypeRow(data);
}

class DietTypeRow extends SupabaseDataRow {
  DietTypeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DietTypeTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);
}
