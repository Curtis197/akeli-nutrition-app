import '../database.dart';

class TagsTable extends SupabaseTable<TagsRow> {
  @override
  String get tableName => 'tags';

  @override
  TagsRow createRow(Map<String, dynamic> data) => TagsRow(data);
}

class TagsRow extends SupabaseDataRow {
  TagsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TagsTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get color => getField<String>('color');
  set color(String? value) => setField<String>('color', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  int? get receipeCreated => getField<int>('receipe_created');
  set receipeCreated(int? value) => setField<int>('receipe_created', value);

  int? get mealConsumed => getField<int>('meal_consumed');
  set mealConsumed(int? value) => setField<int>('meal_consumed', value);
}
