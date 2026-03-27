import '../database.dart';

class DifficultyTable extends SupabaseTable<DifficultyRow> {
  @override
  String get tableName => 'difficulty';

  @override
  DifficultyRow createRow(Map<String, dynamic> data) => DifficultyRow(data);
}

class DifficultyRow extends SupabaseDataRow {
  DifficultyRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DifficultyTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);
}
