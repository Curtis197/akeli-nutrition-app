import '../database.dart';

class ShoppingListTable extends SupabaseTable<ShoppingListRow> {
  @override
  String get tableName => 'shopping_list';

  @override
  ShoppingListRow createRow(Map<String, dynamic> data) => ShoppingListRow(data);
}

class ShoppingListRow extends SupabaseDataRow {
  ShoppingListRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ShoppingListTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get mealPlanId => getField<int>('meal_plan_id');
  set mealPlanId(int? value) => setField<int>('meal_plan_id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  bool? get completed => getField<bool>('completed');
  set completed(bool? value) => setField<bool>('completed', value);
}
