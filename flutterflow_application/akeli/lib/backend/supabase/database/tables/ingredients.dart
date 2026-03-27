import '../database.dart';

class IngredientsTable extends SupabaseTable<IngredientsRow> {
  @override
  String get tableName => 'ingredients';

  @override
  IngredientsRow createRow(Map<String, dynamic> data) => IngredientsRow(data);
}

class IngredientsRow extends SupabaseDataRow {
  IngredientsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => IngredientsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get unit => getField<String>('unit');
  set unit(String? value) => setField<String>('unit', value);

  double? get quantity => getField<double>('quantity');
  set quantity(double? value) => setField<double>('quantity', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  String? get category => getField<String>('category');
  set category(String? value) => setField<String>('category', value);

  String? get photoUrl => getField<String>('photo_url');
  set photoUrl(String? value) => setField<String>('photo_url', value);

  String? get type => getField<String>('type');
  set type(String? value) => setField<String>('type', value);

  int? get temporaryReceipeId => getField<int>('temporary_receipe_id');
  set temporaryReceipeId(int? value) =>
      setField<int>('temporary_receipe_id', value);

  int? get index => getField<int>('index');
  set index(int? value) => setField<int>('index', value);

  bool? get title => getField<bool>('title');
  set title(bool? value) => setField<bool>('title', value);

  int? get roundTypeIndex => getField<int>('round_type_index');
  set roundTypeIndex(int? value) => setField<int>('round_type_index', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
