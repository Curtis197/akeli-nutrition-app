import '../database.dart';

class ReferralTable extends SupabaseTable<ReferralRow> {
  @override
  String get tableName => 'referral';

  @override
  ReferralRow createRow(Map<String, dynamic> data) => ReferralRow(data);
}

class ReferralRow extends SupabaseDataRow {
  ReferralRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReferralTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get authId => getField<String>('auth_id');
  set authId(String? value) => setField<String>('auth_id', value);

  String? get code => getField<String>('code');
  set code(String? value) => setField<String>('code', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get firebaseAuthId => getField<String>('firebase_auth_id');
  set firebaseAuthId(String? value) =>
      setField<String>('firebase_auth_id', value);

  String? get url => getField<String>('url');
  set url(String? value) => setField<String>('url', value);
}
