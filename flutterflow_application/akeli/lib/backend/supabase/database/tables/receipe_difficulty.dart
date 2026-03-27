import '../database.dart';

class ReceipeDifficultyTable extends SupabaseTable<ReceipeDifficultyRow> {
  @override
  String get tableName => 'receipe_difficulty';

  @override
  ReceipeDifficultyRow createRow(Map<String, dynamic> data) =>
      ReceipeDifficultyRow(data);
}

class ReceipeDifficultyRow extends SupabaseDataRow {
  ReceipeDifficultyRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReceipeDifficultyTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
