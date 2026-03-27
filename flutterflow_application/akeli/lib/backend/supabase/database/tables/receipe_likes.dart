import '../database.dart';

class ReceipeLikesTable extends SupabaseTable<ReceipeLikesRow> {
  @override
  String get tableName => 'receipe_likes';

  @override
  ReceipeLikesRow createRow(Map<String, dynamic> data) => ReceipeLikesRow(data);
}

class ReceipeLikesRow extends SupabaseDataRow {
  ReceipeLikesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReceipeLikesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get receipeId => getField<int>('receipe_id');
  set receipeId(int? value) => setField<int>('receipe_id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);
}
