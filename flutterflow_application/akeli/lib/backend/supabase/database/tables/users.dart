import '../database.dart';

class UsersTable extends SupabaseTable<UsersRow> {
  @override
  String get tableName => 'users';

  @override
  UsersRow createRow(Map<String, dynamic> data) => UsersRow(data);
}

class UsersRow extends SupabaseDataRow {
  UsersRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UsersTable();

  int get id => getField<int>('id')!;
  set id(int value) => setField<int>('id', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  String? get userName => getField<String>('user_name');
  set userName(String? value) => setField<String>('user_name', value);

  String? get userMail => getField<String>('user_mail');
  set userMail(String? value) => setField<String>('user_mail', value);

  String? get profilImageUrl => getField<String>('profil_image_url');
  set profilImageUrl(String? value) =>
      setField<String>('profil_image_url', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  bool? get public => getField<bool>('public');
  set public(bool? value) => setField<bool>('public', value);

  String? get language => getField<String>('language');
  set language(String? value) => setField<String>('language', value);

  String? get userId => getField<String>('user_id');
  set userId(String? value) => setField<String>('user_id', value);

  bool? get freePlan => getField<bool>('free_plan');
  set freePlan(bool? value) => setField<bool>('free_plan', value);

  bool? get paidPlan => getField<bool>('paid_plan');
  set paidPlan(bool? value) => setField<bool>('paid_plan', value);

  bool? get cgu => getField<bool>('CGU');
  set cgu(bool? value) => setField<bool>('CGU', value);

  bool? get confidentiality => getField<bool>('confidentiality');
  set confidentiality(bool? value) => setField<bool>('confidentiality', value);
}
