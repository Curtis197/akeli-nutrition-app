import '../database.dart';

class RecipePerformanceLatestTable
    extends SupabaseTable<RecipePerformanceLatestRow> {
  @override
  String get tableName => 'recipe_performance_latest';

  @override
  RecipePerformanceLatestRow createRow(Map<String, dynamic> data) =>
      RecipePerformanceLatestRow(data);
}

class RecipePerformanceLatestRow extends SupabaseDataRow {
  RecipePerformanceLatestRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecipePerformanceLatestTable();

  int? get recipeId => getField<int>('recipe_id');
  set recipeId(int? value) => setField<int>('recipe_id', value);

  String? get recipeName => getField<String>('recipe_name');
  set recipeName(String? value) => setField<String>('recipe_name', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);

  int? get dailyConsumers => getField<int>('daily_consumers');
  set dailyConsumers(int? value) => setField<int>('daily_consumers', value);

  double? get dailyEarnings => getField<double>('daily_earnings');
  set dailyEarnings(double? value) => setField<double>('daily_earnings', value);

  String? get mealType => getField<String>('meal_type');
  set mealType(String? value) => setField<String>('meal_type', value);

  int? get uniqueUserCount => getField<int>('unique_user_count');
  set uniqueUserCount(int? value) => setField<int>('unique_user_count', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
