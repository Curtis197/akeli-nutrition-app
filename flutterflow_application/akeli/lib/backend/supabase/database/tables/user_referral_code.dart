import '../database.dart';

class UserReferralCodeTable extends SupabaseTable<UserReferralCodeRow> {
  @override
  String get tableName => 'user_referral_code';

  @override
  UserReferralCodeRow createRow(Map<String, dynamic> data) =>
      UserReferralCodeRow(data);
}

class UserReferralCodeRow extends SupabaseDataRow {
  UserReferralCodeRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserReferralCodeTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get userId => getField<int>('user_id')!;
  set userId(int value) => setField<int>('user_id', value);

  String get code => getField<String>('code')!;
  set code(String value) => setField<String>('code', value);

  int? get totalClicks => getField<int>('total_clicks');
  set totalClicks(int? value) => setField<int>('total_clicks', value);

  int? get totalSubscriptions => getField<int>('total_subscriptions');
  set totalSubscriptions(int? value) =>
      setField<int>('total_subscriptions', value);

  double? get totalRevenueEarned => getField<double>('total_revenue_earned');
  set totalRevenueEarned(double? value) =>
      setField<double>('total_revenue_earned', value);

  bool? get isActive => getField<bool>('is_active');
  set isActive(bool? value) => setField<bool>('is_active', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
