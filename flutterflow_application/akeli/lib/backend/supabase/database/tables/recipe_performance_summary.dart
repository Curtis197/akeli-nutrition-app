import '../database.dart';

class RecipePerformanceSummaryTable
    extends SupabaseTable<RecipePerformanceSummaryRow> {
  @override
  String get tableName => 'recipe_performance_summary';

  @override
  RecipePerformanceSummaryRow createRow(Map<String, dynamic> data) =>
      RecipePerformanceSummaryRow(data);
}

class RecipePerformanceSummaryRow extends SupabaseDataRow {
  RecipePerformanceSummaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecipePerformanceSummaryTable();

  int? get recipeId => getField<int>('recipe_id');
  set recipeId(int? value) => setField<int>('recipe_id', value);

  String? get recipeName => getField<String>('recipe_name');
  set recipeName(String? value) => setField<String>('recipe_name', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  int? get likeCount => getField<int>('like_count');
  set likeCount(int? value) => setField<int>('like_count', value);

  int? get commentCount => getField<int>('comment_count');
  set commentCount(int? value) => setField<int>('comment_count', value);

  int? get mealConsumed => getField<int>('meal_consumed');
  set mealConsumed(int? value) => setField<int>('meal_consumed', value);

  int? get daysWithData => getField<int>('days_with_data');
  set daysWithData(int? value) => setField<int>('days_with_data', value);

  int? get totalConsumers => getField<int>('total_consumers');
  set totalConsumers(int? value) => setField<int>('total_consumers', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  double? get avgDailyConsumers => getField<double>('avg_daily_consumers');
  set avgDailyConsumers(double? value) =>
      setField<double>('avg_daily_consumers', value);

  int? get maxDailyConsumers => getField<int>('max_daily_consumers');
  set maxDailyConsumers(int? value) =>
      setField<int>('max_daily_consumers', value);

  DateTime? get lastConsumedDate => getField<DateTime>('last_consumed_date');
  set lastConsumedDate(DateTime? value) =>
      setField<DateTime>('last_consumed_date', value);

  int? get consumersLast7d => getField<int>('consumers_last_7d');
  set consumersLast7d(int? value) => setField<int>('consumers_last_7d', value);

  double? get earningsLast7d => getField<double>('earnings_last_7d');
  set earningsLast7d(double? value) =>
      setField<double>('earnings_last_7d', value);

  int? get consumersLast30d => getField<int>('consumers_last_30d');
  set consumersLast30d(int? value) =>
      setField<int>('consumers_last_30d', value);

  double? get earningsLast30d => getField<double>('earnings_last_30d');
  set earningsLast30d(double? value) =>
      setField<double>('earnings_last_30d', value);
}
