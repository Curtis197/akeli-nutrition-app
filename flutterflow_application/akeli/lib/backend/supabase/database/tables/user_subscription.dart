import '../database.dart';

class UserSubscriptionTable extends SupabaseTable<UserSubscriptionRow> {
  @override
  String get tableName => 'user_subscription';

  @override
  UserSubscriptionRow createRow(Map<String, dynamic> data) =>
      UserSubscriptionRow(data);
}

class UserSubscriptionRow extends SupabaseDataRow {
  UserSubscriptionRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserSubscriptionTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  String? get plan => getField<String>('plan');
  set plan(String? value) => setField<String>('plan', value);

  DateTime? get startDate => getField<DateTime>('start_date');
  set startDate(DateTime? value) => setField<DateTime>('start_date', value);

  DateTime? get endDate => getField<DateTime>('end_date');
  set endDate(DateTime? value) => setField<DateTime>('end_date', value);

  bool? get active => getField<bool>('active');
  set active(bool? value) => setField<bool>('active', value);

  String? get firebaseAuthId => getField<String>('firebase_auth_id');
  set firebaseAuthId(String? value) =>
      setField<String>('firebase_auth_id', value);

  int? get referralId => getField<int>('referral_id');
  set referralId(int? value) => setField<int>('referral_id', value);

  DateTime? get lastConnection => getField<DateTime>('last_connection');
  set lastConnection(DateTime? value) =>
      setField<DateTime>('last_connection', value);
}
