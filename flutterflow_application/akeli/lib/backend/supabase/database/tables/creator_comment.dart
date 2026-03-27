import '../database.dart';

class CreatorCommentTable extends SupabaseTable<CreatorCommentRow> {
  @override
  String get tableName => 'creator_comment';

  @override
  CreatorCommentRow createRow(Map<String, dynamic> data) =>
      CreatorCommentRow(data);
}

class CreatorCommentRow extends SupabaseDataRow {
  CreatorCommentRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorCommentTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get text => getField<String>('text');
  set text(String? value) => setField<String>('text', value);

  DateTime? get timestamp => getField<DateTime>('timestamp');
  set timestamp(DateTime? value) => setField<DateTime>('timestamp', value);
}
