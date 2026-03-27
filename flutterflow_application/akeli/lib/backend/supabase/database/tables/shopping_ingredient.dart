import '../database.dart';

class ShoppingIngredientTable extends SupabaseTable<ShoppingIngredientRow> {
  @override
  String get tableName => 'shopping_ingredient';

  @override
  ShoppingIngredientRow createRow(Map<String, dynamic> data) =>
      ShoppingIngredientRow(data);
}

class ShoppingIngredientRow extends SupabaseDataRow {
  ShoppingIngredientRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ShoppingIngredientTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  double? get quantity => getField<double>('quantity');
  set quantity(double? value) => setField<double>('quantity', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get unit => getField<String>('unit');
  set unit(String? value) => setField<String>('unit', value);

  double? get price => getField<double>('price');
  set price(double? value) => setField<double>('price', value);

  int? get shoppingListId => getField<int>('shopping_list_id');
  set shoppingListId(int? value) => setField<int>('shopping_list_id', value);

  bool? get bought => getField<bool>('bought');
  set bought(bool? value) => setField<bool>('bought', value);

  String? get photoUrl => getField<String>('photo_url');
  set photoUrl(String? value) => setField<String>('photo_url', value);

  double? get item => getField<double>('item');
  set item(double? value) => setField<double>('item', value);
}
