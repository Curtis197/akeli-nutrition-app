import '../database.dart';

class UserFanTable extends SupabaseTable<UserFanRow> {
  @override
  String get tableName => 'user_fan';

  @override
  UserFanRow createRow(Map<String, dynamic> data) => UserFanRow(data);
}

class UserFanRow extends SupabaseDataRow {
  UserFanRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserFanTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get userAuthId => getField<String>('user_auth_id');
  set userAuthId(String? value) => setField<String>('user_auth_id', value);
}
