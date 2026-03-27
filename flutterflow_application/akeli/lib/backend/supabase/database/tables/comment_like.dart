import '../database.dart';

class CommentLikeTable extends SupabaseTable<CommentLikeRow> {
  @override
  String get tableName => 'comment_like';

  @override
  CommentLikeRow createRow(Map<String, dynamic> data) => CommentLikeRow(data);
}

class CommentLikeRow extends SupabaseDataRow {
  CommentLikeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CommentLikeTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  int? get receipeCommentId => getField<int>('receipe_comment_id');
  set receipeCommentId(int? value) =>
      setField<int>('receipe_comment_id', value);
}
