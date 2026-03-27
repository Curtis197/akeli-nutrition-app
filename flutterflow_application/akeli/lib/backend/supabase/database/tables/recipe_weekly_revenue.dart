import '../database.dart';

class RecipeWeeklyRevenueTable extends SupabaseTable<RecipeWeeklyRevenueRow> {
  @override
  String get tableName => 'recipe_weekly_revenue';

  @override
  RecipeWeeklyRevenueRow createRow(Map<String, dynamic> data) =>
      RecipeWeeklyRevenueRow(data);
}

class RecipeWeeklyRevenueRow extends SupabaseDataRow {
  RecipeWeeklyRevenueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecipeWeeklyRevenueTable();

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  DateTime? get weekStart => getField<DateTime>('week_start');
  set weekStart(DateTime? value) => setField<DateTime>('week_start', value);

  DateTime? get weekEnd => getField<DateTime>('week_end');
  set weekEnd(DateTime? value) => setField<DateTime>('week_end', value);

  int? get weekNumber => getField<int>('week_number');
  set weekNumber(int? value) => setField<int>('week_number', value);

  int? get year => getField<int>('year');
  set year(int? value) => setField<int>('year', value);

  int? get daysWithPerformance => getField<int>('days_with_performance');
  set daysWithPerformance(int? value) =>
      setField<int>('days_with_performance', value);

  int? get totalConsumers => getField<int>('total_consumers');
  set totalConsumers(int? value) => setField<int>('total_consumers', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  double? get avgDailyConsumers => getField<double>('avg_daily_consumers');
  set avgDailyConsumers(double? value) =>
      setField<double>('avg_daily_consumers', value);

  double? get avgDailyEarnings => getField<double>('avg_daily_earnings');
  set avgDailyEarnings(double? value) =>
      setField<double>('avg_daily_earnings', value);
}
