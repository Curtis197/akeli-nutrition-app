import '../database.dart';

class CreatorDietSpecialtyTable extends SupabaseTable<CreatorDietSpecialtyRow> {
  @override
  String get tableName => 'creator_diet_specialty';

  @override
  CreatorDietSpecialtyRow createRow(Map<String, dynamic> data) =>
      CreatorDietSpecialtyRow(data);
}

class CreatorDietSpecialtyRow extends SupabaseDataRow {
  CreatorDietSpecialtyRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorDietSpecialtyTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);
}
