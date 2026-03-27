import '../database.dart';

class MealTable extends SupabaseTable<MealRow> {
  @override
  String get tableName => 'meal';

  @override
  MealRow createRow(Map<String, dynamic> data) => MealRow(data);
}

class MealRow extends SupabaseDataRow {
  MealRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => MealTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  double? get adjustedCalories => getField<double>('adjusted_calories');
  set adjustedCalories(double? value) =>
      setField<double>('adjusted_calories', value);

  DateTime? get mealDate => getField<DateTime>('meal_date');
  set mealDate(DateTime? value) => setField<DateTime>('meal_date', value);

  String? get mealType => getField<String>('meal_type');
  set mealType(String? value) => setField<String>('meal_type', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get mealPlanId => getField<int>('meal_plan_id');
  set mealPlanId(int? value) => setField<int>('meal_plan_id', value);

  String? get day => getField<String>('day');
  set day(String? value) => setField<String>('day', value);

  bool? get consumed => getField<bool>('consumed');
  set consumed(bool? value) => setField<bool>('consumed', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  double? get adjustedProtein => getField<double>('adjusted_protein');
  set adjustedProtein(double? value) =>
      setField<double>('adjusted_protein', value);

  double? get adjustedCarbs => getField<double>('adjusted_carbs');
  set adjustedCarbs(double? value) => setField<double>('adjusted_carbs', value);

  double? get adjustedFat => getField<double>('adjusted_fat');
  set adjustedFat(double? value) => setField<double>('adjusted_fat', value);

  bool? get personal => getField<bool>('personal');
  set personal(bool? value) => setField<bool>('personal', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  bool? get generated => getField<bool>('generated');
  set generated(bool? value) => setField<bool>('generated', value);

  double? get scalingFactor => getField<double>('scaling_factor');
  set scalingFactor(double? value) => setField<double>('scaling_factor', value);
}
