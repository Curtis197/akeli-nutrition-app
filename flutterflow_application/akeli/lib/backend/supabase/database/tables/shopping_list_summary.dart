import '../database.dart';

class ShoppingListSummaryTable extends SupabaseTable<ShoppingListSummaryRow> {
  @override
  String get tableName => 'shopping_list_summary';

  @override
  ShoppingListSummaryRow createRow(Map<String, dynamic> data) =>
      ShoppingListSummaryRow(data);
}

class ShoppingListSummaryRow extends SupabaseDataRow {
  ShoppingListSummaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ShoppingListSummaryTable();

  int? get shoppingListId => getField<int>('shopping_list_id');
  set shoppingListId(int? value) => setField<int>('shopping_list_id', value);

  int? get totalUniqueIngredients => getField<int>('total_unique_ingredients');
  set totalUniqueIngredients(int? value) =>
      setField<int>('total_unique_ingredients', value);

  double? get totalItemsToBuy => getField<double>('total_items_to_buy');
  set totalItemsToBuy(double? value) =>
      setField<double>('total_items_to_buy', value);

  double? get totalBoughtItems => getField<double>('total_bought_items');
  set totalBoughtItems(double? value) =>
      setField<double>('total_bought_items', value);

  double? get totalLeftToBuy => getField<double>('total_left_to_buy');
  set totalLeftToBuy(double? value) =>
      setField<double>('total_left_to_buy', value);

  double? get completionPercentage => getField<double>('completion_percentage');
  set completionPercentage(double? value) =>
      setField<double>('completion_percentage', value);
}
