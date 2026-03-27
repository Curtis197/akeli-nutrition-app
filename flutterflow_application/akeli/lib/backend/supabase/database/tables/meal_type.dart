import '../database.dart';

class MealTypeTable extends SupabaseTable<MealTypeRow> {
  @override
  String get tableName => 'meal_type';

  @override
  MealTypeRow createRow(Map<String, dynamic> data) => MealTypeRow(data);
}

class MealTypeRow extends SupabaseDataRow {
  MealTypeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MealTypeTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get type => getField<String>('type');
  set type(String? value) => setField<String>('type', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
