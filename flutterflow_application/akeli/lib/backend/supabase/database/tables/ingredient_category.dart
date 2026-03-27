import '../database.dart';

class IngredientCategoryTable extends SupabaseTable<IngredientCategoryRow> {
  @override
  String get tableName => 'ingredient_category';

  @override
  IngredientCategoryRow createRow(Map<String, dynamic> data) =>
      IngredientCategoryRow(data);
}

class IngredientCategoryRow extends SupabaseDataRow {
  IngredientCategoryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => IngredientCategoryTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
