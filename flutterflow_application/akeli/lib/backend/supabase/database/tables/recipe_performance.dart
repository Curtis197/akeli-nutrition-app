import '../database.dart';

class RecipePerformanceTable extends SupabaseTable<RecipePerformanceRow> {
  @override
  String get tableName => 'recipe_performance';

  @override
  RecipePerformanceRow createRow(Map<String, dynamic> data) =>
      RecipePerformanceRow(data);
}

class RecipePerformanceRow extends SupabaseDataRow {
  RecipePerformanceRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecipePerformanceTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get receipeId => getField<int>('receipe_id')!;
  set receipeId(int value) => setField<int>('receipe_id', value);

  DateTime get date => getField<DateTime>('date')!;
  set date(DateTime value) => setField<DateTime>('date', value);

  int? get dailyConsumers => getField<int>('daily_consumers');
  set dailyConsumers(int? value) => setField<int>('daily_consumers', value);

  double? get dailyEarnings => getField<double>('daily_earnings');
  set dailyEarnings(double? value) => setField<double>('daily_earnings', value);

  String? get mealType => getField<String>('meal_type');
  set mealType(String? value) => setField<String>('meal_type', value);

  List<int> get uniqueUsers => getListField<int>('unique_users');
  set uniqueUsers(List<int>? value) => setListField<int>('unique_users', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
