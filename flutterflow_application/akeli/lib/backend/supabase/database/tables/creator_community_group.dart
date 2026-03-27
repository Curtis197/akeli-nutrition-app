import '../database.dart';

class CreatorCommunityGroupTable
    extends SupabaseTable<CreatorCommunityGroupRow> {
  @override
  String get tableName => 'creator_community_group';

  @override
  CreatorCommunityGroupRow createRow(Map<String, dynamic> data) =>
      CreatorCommunityGroupRow(data);
}

class CreatorCommunityGroupRow extends SupabaseDataRow {
  CreatorCommunityGroupRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorCommunityGroupTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get name => getField<String>('name')!;
  set name(String value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get imageUrl => getField<String>('image_url');
  set imageUrl(String? value) => setField<String>('image_url', value);

  String? get groupType => getField<String>('group_type');
  set groupType(String? value) => setField<String>('group_type', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  String? get createdByCreatorId => getField<String>('created_by_creator_id');
  set createdByCreatorId(String? value) =>
      setField<String>('created_by_creator_id', value);

  int? get memberCount => getField<int>('member_count');
  set memberCount(int? value) => setField<int>('member_count', value);

  int? get postCount => getField<int>('post_count');
  set postCount(int? value) => setField<int>('post_count', value);

  bool? get isPublic => getField<bool>('is_public');
  set isPublic(bool? value) => setField<bool>('is_public', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  List<String> get tags => getListField<String>('tags');
  set tags(List<String>? value) => setListField<String>('tags', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
