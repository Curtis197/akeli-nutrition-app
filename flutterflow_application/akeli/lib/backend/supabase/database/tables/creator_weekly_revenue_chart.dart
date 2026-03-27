import '../database.dart';

class CreatorWeeklyRevenueChartTable
    extends SupabaseTable<CreatorWeeklyRevenueChartRow> {
  @override
  String get tableName => 'creator_weekly_revenue_chart';

  @override
  CreatorWeeklyRevenueChartRow createRow(Map<String, dynamic> data) =>
      CreatorWeeklyRevenueChartRow(data);
}

class CreatorWeeklyRevenueChartRow extends SupabaseDataRow {
  CreatorWeeklyRevenueChartRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorWeeklyRevenueChartTable();

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  DateTime? get weekStart => getField<DateTime>('week_start');
  set weekStart(DateTime? value) => setField<DateTime>('week_start', value);

  DateTime? get weekEnd => getField<DateTime>('week_end');
  set weekEnd(DateTime? value) => setField<DateTime>('week_end', value);

  int? get weekNumber => getField<int>('week_number');
  set weekNumber(int? value) => setField<int>('week_number', value);

  int? get year => getField<int>('year');
  set year(int? value) => setField<int>('year', value);

  DateTime? get date => getField<DateTime>('date');
  set date(DateTime? value) => setField<DateTime>('date', value);

  int? get dayNumber => getField<int>('day_number');
  set dayNumber(int? value) => setField<int>('day_number', value);

  String? get dayName => getField<String>('day_name');
  set dayName(String? value) => setField<String>('day_name', value);

  double? get revenue => getField<double>('revenue');
  set revenue(double? value) => setField<double>('revenue', value);

  int? get dailyConsumers => getField<int>('daily_consumers');
  set dailyConsumers(int? value) => setField<int>('daily_consumers', value);

  double? get barHeightPercent => getField<double>('bar_height_percent');
  set barHeightPercent(double? value) =>
      setField<double>('bar_height_percent', value);
}
