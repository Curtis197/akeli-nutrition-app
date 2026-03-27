import '../database.dart';

class CreatorCommunityPostLikeTable
    extends SupabaseTable<CreatorCommunityPostLikeRow> {
  @override
  String get tableName => 'creator_community_post_like';

  @override
  CreatorCommunityPostLikeRow createRow(Map<String, dynamic> data) =>
      CreatorCommunityPostLikeRow(data);
}

class CreatorCommunityPostLikeRow extends SupabaseDataRow {
  CreatorCommunityPostLikeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorCommunityPostLikeTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get postId => getField<String>('post_id')!;
  set postId(String value) => setField<String>('post_id', value);

  String get creatorId => getField<String>('creator_id')!;
  set creatorId(String value) => setField<String>('creator_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);
}
