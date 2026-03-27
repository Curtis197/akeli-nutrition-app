import '../database.dart';

class CreatorWeeklyRevenueTable extends SupabaseTable<CreatorWeeklyRevenueRow> {
  @override
  String get tableName => 'creator_weekly_revenue';

  @override
  CreatorWeeklyRevenueRow createRow(Map<String, dynamic> data) =>
      CreatorWeeklyRevenueRow(data);
}

class CreatorWeeklyRevenueRow extends SupabaseDataRow {
  CreatorWeeklyRevenueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorWeeklyRevenueTable();

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  DateTime? get weekStart => getField<DateTime>('week_start');
  set weekStart(DateTime? value) => setField<DateTime>('week_start', value);

  DateTime? get weekEnd => getField<DateTime>('week_end');
  set weekEnd(DateTime? value) => setField<DateTime>('week_end', value);

  double? get weekNumber => getField<double>('week_number');
  set weekNumber(double? value) => setField<double>('week_number', value);

  double? get year => getField<double>('year');
  set year(double? value) => setField<double>('year', value);

  int? get daysWithRevenue => getField<int>('days_with_revenue');
  set daysWithRevenue(int? value) => setField<int>('days_with_revenue', value);

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
