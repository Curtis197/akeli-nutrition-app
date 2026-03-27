import '../database.dart';

class MealConsumedTable extends SupabaseTable<MealConsumedRow> {
  @override
  String get tableName => 'meal_consumed';

  @override
  MealConsumedRow createRow(Map<String, dynamic> data) => MealConsumedRow(data);
}

class MealConsumedRow extends SupabaseDataRow {
  MealConsumedRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MealConsumedTable();

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get mealPlanId => getField<int>('meal_plan_id');
  set mealPlanId(int? value) => setField<int>('meal_plan_id', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);

  String? get day => getField<String>('day');
  set day(String? value) => setField<String>('day', value);

  int? get mealsPlanned => getField<int>('meals_planned');
  set mealsPlanned(int? value) => setField<int>('meals_planned', value);

  int? get mealConsumed => getField<int>('meal_consumed');
  set mealConsumed(int? value) => setField<int>('meal_consumed', value);
}
