import '../database.dart';

class CreatorFoodSpecialtyTable extends SupabaseTable<CreatorFoodSpecialtyRow> {
  @override
  String get tableName => 'creator_food_specialty';

  @override
  CreatorFoodSpecialtyRow createRow(Map<String, dynamic> data) =>
      CreatorFoodSpecialtyRow(data);
}

class CreatorFoodSpecialtyRow extends SupabaseDataRow {
  CreatorFoodSpecialtyRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorFoodSpecialtyTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);
}
