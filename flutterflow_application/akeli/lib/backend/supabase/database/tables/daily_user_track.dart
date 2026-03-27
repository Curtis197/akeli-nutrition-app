import '../database.dart';

class DailyUserTrackTable extends SupabaseTable<DailyUserTrackRow> {
  @override
  String get tableName => 'daily_user_track';

  @override
  DailyUserTrackRow createRow(Map<String, dynamic> data) =>
      DailyUserTrackRow(data);
}

class DailyUserTrackRow extends SupabaseDataRow {
  DailyUserTrackRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => DailyUserTrackTable();

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);

  int? get targetCalorie => getField<int>('target_calorie');
  set targetCalorie(int? value) => setField<int>('target_calorie', value);

  int? get mealPlanned => getField<int>('meal_planned');
  set mealPlanned(int? value) => setField<int>('meal_planned', value);

  int? get mealConsumed => getField<int>('meal_consumed');
  set mealConsumed(int? value) => setField<int>('meal_consumed', value);

  int? get consumedCalories => getField<int>('consumed_calories');
  set consumedCalories(int? value) => setField<int>('consumed_calories', value);

  int? get consumedCarbs => getField<int>('consumed_carbs');
  set consumedCarbs(int? value) => setField<int>('consumed_carbs', value);

  int? get consumedFat => getField<int>('consumed_fat');
  set consumedFat(int? value) => setField<int>('consumed_fat', value);

  int? get consumedProtein => getField<int>('consumed_protein');
  set consumedProtein(int? value) => setField<int>('consumed_protein', value);

  double? get caloriePercent => getField<double>('calorie_percent');
  set caloriePercent(double? value) =>
      setField<double>('calorie_percent', value);

  bool? get allMealConsumed => getField<bool>('all_meal_consumed');
  set allMealConsumed(bool? value) =>
      setField<bool>('all_meal_consumed', value);
}
