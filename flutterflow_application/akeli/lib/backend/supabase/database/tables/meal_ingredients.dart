import '../database.dart';

class MealIngredientsTable extends SupabaseTable<MealIngredientsRow> {
  @override
  String get tableName => 'meal_ingredients';

  @override
  MealIngredientsRow createRow(Map<String, dynamic> data) =>
      MealIngredientsRow(data);
}

class MealIngredientsRow extends SupabaseDataRow {
  MealIngredientsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MealIngredientsTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get mealId => getField<int>('meal_id');
  set mealId(int? value) => setField<int>('meal_id', value);

  String? get ingredientId => getField<String>('ingredient_id');
  set ingredientId(String? value) => setField<String>('ingredient_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get unit => getField<String>('unit');
  set unit(String? value) => setField<String>('unit', value);

  double? get baseQuantity => getField<double>('base_quantity');
  set baseQuantity(double? value) => setField<double>('base_quantity', value);

  double? get adjustedQuantity => getField<double>('adjusted_quantity');
  set adjustedQuantity(double? value) =>
      setField<double>('adjusted_quantity', value);

  double? get scalingFactor => getField<double>('scaling_factor');
  set scalingFactor(double? value) => setField<double>('scaling_factor', value);

  String? get photoUrl => getField<String>('photo_url');
  set photoUrl(String? value) => setField<String>('photo_url', value);

  bool? get title => getField<bool>('title');
  set title(bool? value) => setField<bool>('title', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);
}
