import '../database.dart';

class ShoppingListTotalsTable extends SupabaseTable<ShoppingListTotalsRow> {
  @override
  String get tableName => 'shopping_list_totals';

  @override
  ShoppingListTotalsRow createRow(Map<String, dynamic> data) =>
      ShoppingListTotalsRow(data);
}

class ShoppingListTotalsRow extends SupabaseDataRow {
  ShoppingListTotalsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ShoppingListTotalsTable();

  int? get shoppingListId => getField<int>('shopping_list_id');
  set shoppingListId(int? value) => setField<int>('shopping_list_id', value);

  String? get ingredientName => getField<String>('ingredient_name');
  set ingredientName(String? value) =>
      setField<String>('ingredient_name', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get unit => getField<String>('unit');
  set unit(String? value) => setField<String>('unit', value);

  double? get totalItemsToBuy => getField<double>('total_items_to_buy');
  set totalItemsToBuy(double? value) =>
      setField<double>('total_items_to_buy', value);

  double? get boughtItems => getField<double>('bought_items');
  set boughtItems(double? value) => setField<double>('bought_items', value);

  double? get leftToBuy => getField<double>('left_to_buy');
  set leftToBuy(double? value) => setField<double>('left_to_buy', value);

  double? get totalQuantityNeeded => getField<double>('total_quantity_needed');
  set totalQuantityNeeded(double? value) =>
      setField<double>('total_quantity_needed', value);

  double? get boughtQuantity => getField<double>('bought_quantity');
  set boughtQuantity(double? value) =>
      setField<double>('bought_quantity', value);
}
