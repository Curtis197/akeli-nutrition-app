import '../database.dart';

class CreatorCommunityPostTable extends SupabaseTable<CreatorCommunityPostRow> {
  @override
  String get tableName => 'creator_community_post';

  @override
  CreatorCommunityPostRow createRow(Map<String, dynamic> data) =>
      CreatorCommunityPostRow(data);
}

class CreatorCommunityPostRow extends SupabaseDataRow {
  CreatorCommunityPostRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorCommunityPostTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get creatorId => getField<String>('creator_id')!;
  set creatorId(String value) => setField<String>('creator_id', value);

  String get content => getField<String>('content')!;
  set content(String value) => setField<String>('content', value);

  bool? get isPinned => getField<bool>('is_pinned');
  set isPinned(bool? value) => setField<bool>('is_pinned', value);

  bool? get isEdited => getField<bool>('is_edited');
  set isEdited(bool? value) => setField<bool>('is_edited', value);

  DateTime? get editedAt => getField<DateTime>('edited_at');
  set editedAt(DateTime? value) => setField<DateTime>('edited_at', value);

  int? get likeCount => getField<int>('like_count');
  set likeCount(int? value) => setField<int>('like_count', value);

  int? get replyCount => getField<int>('reply_count');
  set replyCount(int? value) => setField<int>('reply_count', value);

  String? get parentPostId => getField<String>('parent_post_id');
  set parentPostId(String? value) => setField<String>('parent_post_id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
