import '../database.dart';

class FoodRegionTable extends SupabaseTable<FoodRegionRow> {
  @override
  String get tableName => 'food region';

  @override
  FoodRegionRow createRow(Map<String, dynamic> data) => FoodRegionRow(data);
}

class FoodRegionRow extends SupabaseDataRow {
  FoodRegionRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => FoodRegionTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get receipeCreated => getField<int>('receipe_created');
  set receipeCreated(int? value) => setField<int>('receipe_created', value);

  int? get mealConsumed => getField<int>('meal_consumed');
  set mealConsumed(int? value) => setField<int>('meal_consumed', value);
}
