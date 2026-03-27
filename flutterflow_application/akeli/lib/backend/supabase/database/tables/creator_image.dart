import '../database.dart';

class CreatorImageTable extends SupabaseTable<CreatorImageRow> {
  @override
  String get tableName => 'creator_image';

  @override
  CreatorImageRow createRow(Map<String, dynamic> data) => CreatorImageRow(data);
}

class CreatorImageRow extends SupabaseDataRow {
  CreatorImageRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorImageTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get url => getField<String>('url');
  set url(String? value) => setField<String>('url', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);
}
