import '../database.dart';

class CreatorRevenueTable extends SupabaseTable<CreatorRevenueRow> {
  @override
  String get tableName => 'creator_revenue';

  @override
  CreatorRevenueRow createRow(Map<String, dynamic> data) =>
      CreatorRevenueRow(data);
}

class CreatorRevenueRow extends SupabaseDataRow {
  CreatorRevenueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorRevenueTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get creatorId => getField<String>('creator_id')!;
  set creatorId(String value) => setField<String>('creator_id', value);

  DateTime get date => getField<DateTime>('date')!;
  set date(DateTime value) => setField<DateTime>('date', value);

  int? get dailyConsumers => getField<int>('daily_consumers');
  set dailyConsumers(int? value) => setField<int>('daily_consumers', value);

  double? get dailyEarnings => getField<double>('daily_earnings');
  set dailyEarnings(double? value) => setField<double>('daily_earnings', value);

  List<int> get uniqueUsers => getListField<int>('unique_users');
  set uniqueUsers(List<int>? value) => setListField<int>('unique_users', value);

  dynamic? get recipesConsumed => getField<dynamic>('recipes_consumed');
  set recipesConsumed(dynamic? value) =>
      setField<dynamic>('recipes_consumed', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
