import '../database.dart';

class CreatorCommunityMemberTable
    extends SupabaseTable<CreatorCommunityMemberRow> {
  @override
  String get tableName => 'creator_community_member';

  @override
  CreatorCommunityMemberRow createRow(Map<String, dynamic> data) =>
      CreatorCommunityMemberRow(data);
}

class CreatorCommunityMemberRow extends SupabaseDataRow {
  CreatorCommunityMemberRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorCommunityMemberTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get groupId => getField<String>('group_id')!;
  set groupId(String value) => setField<String>('group_id', value);

  String get creatorId => getField<String>('creator_id')!;
  set creatorId(String value) => setField<String>('creator_id', value);

  String? get role => getField<String>('role');
  set role(String? value) => setField<String>('role', value);

  bool? get notificationsEnabled => getField<bool>('notifications_enabled');
  set notificationsEnabled(bool? value) =>
      setField<bool>('notifications_enabled', value);

  DateTime? get lastReadAt => getField<DateTime>('last_read_at');
  set lastReadAt(DateTime? value) => setField<DateTime>('last_read_at', value);

  DateTime? get joinedAt => getField<DateTime>('joined_at');
  set joinedAt(DateTime? value) => setField<DateTime>('joined_at', value);
}
