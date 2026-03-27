import '../database.dart';

class WeeklySummaryTable extends SupabaseTable<WeeklySummaryRow> {
  @override
  String get tableName => 'weekly_summary';

  @override
  WeeklySummaryRow createRow(Map<String, dynamic> data) =>
      WeeklySummaryRow(data);
}

class WeeklySummaryRow extends SupabaseDataRow {
  WeeklySummaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => WeeklySummaryTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  DateTime? get weekStart => getField<DateTime>('week_start');
  set weekStart(DateTime? value) => setField<DateTime>('week_start', value);

  int? get mealsPlanned => getField<int>('meals_planned');
  set mealsPlanned(int? value) => setField<int>('meals_planned', value);

  int? get mealsConsumed => getField<int>('meals_consumed');
  set mealsConsumed(int? value) => setField<int>('meals_consumed', value);

  double? get totalCalories => getField<double>('total_calories');
  set totalCalories(double? value) => setField<double>('total_calories', value);

  dynamic? get macros => getField<dynamic>('macros');
  set macros(dynamic? value) => setField<dynamic>('macros', value);

  dynamic? get dailyStats => getField<dynamic>('daily_stats');
  set dailyStats(dynamic? value) => setField<dynamic>('daily_stats', value);

  String? get aiComment => getField<String>('ai_comment');
  set aiComment(String? value) => setField<String>('ai_comment', value);

  String? get userUuid => getField<String>('user_uuid');
  set userUuid(String? value) => setField<String>('user_uuid', value);

  DateTime? get weekEnd => getField<DateTime>('week_end');
  set weekEnd(DateTime? value) => setField<DateTime>('week_end', value);

  int? get updatedWeight => getField<int>('updated_weight');
  set updatedWeight(int? value) => setField<int>('updated_weight', value);
}
