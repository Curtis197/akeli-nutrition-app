import '../database.dart';

class UserReferralTable extends SupabaseTable<UserReferralRow> {
  @override
  String get tableName => 'user_referral';

  @override
  UserReferralRow createRow(Map<String, dynamic> data) => UserReferralRow(data);
}

class UserReferralRow extends SupabaseDataRow {
  UserReferralRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserReferralTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  int get referrerId => getField<int>('referrer_id')!;
  set referrerId(int value) => setField<int>('referrer_id', value);

  int? get refereeId => getField<int>('referee_id');
  set refereeId(int? value) => setField<int>('referee_id', value);

  String get referralCode => getField<String>('referral_code')!;
  set referralCode(String value) => setField<String>('referral_code', value);

  String? get status => getField<String>('status');
  set status(String? value) => setField<String>('status', value);

  double? get revenueEarned => getField<double>('revenue_earned');
  set revenueEarned(double? value) => setField<double>('revenue_earned', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get subscribedAt => getField<DateTime>('subscribed_at');
  set subscribedAt(DateTime? value) =>
      setField<DateTime>('subscribed_at', value);

  DateTime? get expiredAt => getField<DateTime>('expired_at');
  set expiredAt(DateTime? value) => setField<DateTime>('expired_at', value);

  String? get ipAddress => getField<String>('ip_address');
  set ipAddress(String? value) => setField<String>('ip_address', value);

  String? get userAgent => getField<String>('user_agent');
  set userAgent(String? value) => setField<String>('user_agent', value);

  String? get utmSource => getField<String>('utm_source');
  set utmSource(String? value) => setField<String>('utm_source', value);

  String? get utmMedium => getField<String>('utm_medium');
  set utmMedium(String? value) => setField<String>('utm_medium', value);

  String? get utmCampaign => getField<String>('utm_campaign');
  set utmCampaign(String? value) => setField<String>('utm_campaign', value);
}
