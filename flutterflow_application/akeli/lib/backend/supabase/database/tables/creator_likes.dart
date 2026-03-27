import '../database.dart';

class CreatorLikesTable extends SupabaseTable<CreatorLikesRow> {
  @override
  String get tableName => 'creator_likes';

  @override
  CreatorLikesRow createRow(Map<String, dynamic> data) => CreatorLikesRow(data);
}

class CreatorLikesRow extends SupabaseDataRow {
  CreatorLikesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorLikesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);
}
