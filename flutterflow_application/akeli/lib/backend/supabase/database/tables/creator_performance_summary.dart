import '../database.dart';

class CreatorPerformanceSummaryTable
    extends SupabaseTable<CreatorPerformanceSummaryRow> {
  @override
  String get tableName => 'creator_performance_summary';

  @override
  CreatorPerformanceSummaryRow createRow(Map<String, dynamic> data) =>
      CreatorPerformanceSummaryRow(data);
}

class CreatorPerformanceSummaryRow extends SupabaseDataRow {
  CreatorPerformanceSummaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorPerformanceSummaryTable();

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  int? get totalDailyConsumers => getField<int>('total_daily_consumers');
  set totalDailyConsumers(int? value) =>
      setField<int>('total_daily_consumers', value);

  int? get publishedRecipes => getField<int>('published_recipes');
  set publishedRecipes(int? value) => setField<int>('published_recipes', value);

  int? get draftRecipes => getField<int>('draft_recipes');
  set draftRecipes(int? value) => setField<int>('draft_recipes', value);

  int? get totalRecipes => getField<int>('total_recipes');
  set totalRecipes(int? value) => setField<int>('total_recipes', value);

  double? get totalLikes => getField<double>('total_likes');
  set totalLikes(double? value) => setField<double>('total_likes', value);

  double? get currentMonthRevenue => getField<double>('current_month_revenue');
  set currentMonthRevenue(double? value) =>
      setField<double>('current_month_revenue', value);

  int? get currentMonthConsumers => getField<int>('current_month_consumers');
  set currentMonthConsumers(int? value) =>
      setField<int>('current_month_consumers', value);

  int? get currentMonthDaysActive => getField<int>('current_month_days_active');
  set currentMonthDaysActive(int? value) =>
      setField<int>('current_month_days_active', value);

  double? get previousMonthRevenue =>
      getField<double>('previous_month_revenue');
  set previousMonthRevenue(double? value) =>
      setField<double>('previous_month_revenue', value);

  int? get previousMonthConsumers => getField<int>('previous_month_consumers');
  set previousMonthConsumers(int? value) =>
      setField<int>('previous_month_consumers', value);

  int? get previousMonthDaysActive =>
      getField<int>('previous_month_days_active');
  set previousMonthDaysActive(int? value) =>
      setField<int>('previous_month_days_active', value);

  double? get last7DaysRevenue => getField<double>('last_7_days_revenue');
  set last7DaysRevenue(double? value) =>
      setField<double>('last_7_days_revenue', value);

  int? get last7DaysConsumers => getField<int>('last_7_days_consumers');
  set last7DaysConsumers(int? value) =>
      setField<int>('last_7_days_consumers', value);

  double? get last30DaysRevenue => getField<double>('last_30_days_revenue');
  set last30DaysRevenue(double? value) =>
      setField<double>('last_30_days_revenue', value);

  int? get last30DaysConsumers => getField<int>('last_30_days_consumers');
  set last30DaysConsumers(int? value) =>
      setField<int>('last_30_days_consumers', value);

  int? get recipesPublishedThisMonth =>
      getField<int>('recipes_published_this_month');
  set recipesPublishedThisMonth(int? value) =>
      setField<int>('recipes_published_this_month', value);

  int? get recipesPublishedLastMonth =>
      getField<int>('recipes_published_last_month');
  set recipesPublishedLastMonth(int? value) =>
      setField<int>('recipes_published_last_month', value);
}
