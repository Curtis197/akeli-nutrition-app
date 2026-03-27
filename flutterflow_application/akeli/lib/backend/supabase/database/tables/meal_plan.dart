import '../database.dart';

class MealPlanTable extends SupabaseTable<MealPlanRow> {
  @override
  String get tableName => 'meal_plan';

  @override
  MealPlanRow createRow(Map<String, dynamic> data) => MealPlanRow(data);
}

class MealPlanRow extends SupabaseDataRow {
  MealPlanRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MealPlanTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  bool? get ingredientsGenerated => getField<bool>('ingredients_generated');
  set ingredientsGenerated(bool? value) =>
      setField<bool>('ingredients_generated', value);

  bool? get shoppingListCreated => getField<bool>('shopping_list_created');
  set shoppingListCreated(bool? value) =>
      setField<bool>('shopping_list_created', value);

  bool? get mealGenerated => getField<bool>('meal_generated');
  set mealGenerated(bool? value) => setField<bool>('meal_generated', value);
}
