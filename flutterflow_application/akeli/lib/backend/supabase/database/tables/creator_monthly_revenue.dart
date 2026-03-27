import '../database.dart';

class CreatorMonthlyRevenueTable
    extends SupabaseTable<CreatorMonthlyRevenueRow> {
  @override
  String get tableName => 'creator_monthly_revenue';

  @override
  CreatorMonthlyRevenueRow createRow(Map<String, dynamic> data) =>
      CreatorMonthlyRevenueRow(data);
}

class CreatorMonthlyRevenueRow extends SupabaseDataRow {
  CreatorMonthlyRevenueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorMonthlyRevenueTable();

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  DateTime? get monthStart => getField<DateTime>('month_start');
  set monthStart(DateTime? value) => setField<DateTime>('month_start', value);

  String? get monthKey => getField<String>('month_key');
  set monthKey(String? value) => setField<String>('month_key', value);

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

  int? get maxDailyConsumers => getField<int>('max_daily_consumers');
  set maxDailyConsumers(int? value) =>
      setField<int>('max_daily_consumers', value);

  int? get minDailyConsumers => getField<int>('min_daily_consumers');
  set minDailyConsumers(int? value) =>
      setField<int>('min_daily_consumers', value);
}
