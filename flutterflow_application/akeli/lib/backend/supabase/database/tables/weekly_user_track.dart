import '../database.dart';

class WeeklyUserTrackTable extends SupabaseTable<WeeklyUserTrackRow> {
  @override
  String get tableName => 'weekly_user_track';

  @override
  WeeklyUserTrackRow createRow(Map<String, dynamic> data) =>
      WeeklyUserTrackRow(data);
}

class WeeklyUserTrackRow extends SupabaseDataRow {
  WeeklyUserTrackRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WeeklyUserTrackTable();

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get mealPlanId => getField<int>('meal_plan_id');
  set mealPlanId(int? value) => setField<int>('meal_plan_id', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  int? get targetCalorie => getField<int>('target_calorie');
  set targetCalorie(int? value) => setField<int>('target_calorie', value);

  int? get consumedCalories => getField<int>('consumed_calories');
  set consumedCalories(int? value) => setField<int>('consumed_calories', value);

  int? get consumedCarb => getField<int>('consumed_carb');
  set consumedCarb(int? value) => setField<int>('consumed_carb', value);

  int? get consumedFat => getField<int>('consumed_fat');
  set consumedFat(int? value) => setField<int>('consumed_fat', value);

  int? get consumedProtein => getField<int>('consumed_protein');
  set consumedProtein(int? value) => setField<int>('consumed_protein', value);

  double? get caloriePercent => getField<double>('calorie_percent');
  set caloriePercent(double? value) =>
      setField<double>('calorie_percent', value);
}
