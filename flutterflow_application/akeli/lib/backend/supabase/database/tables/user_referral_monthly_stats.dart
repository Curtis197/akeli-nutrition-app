import '../database.dart';

class UserReferralMonthlyStatsTable
    extends SupabaseTable<UserReferralMonthlyStatsRow> {
  @override
  String get tableName => 'user_referral_monthly_stats';

  @override
  UserReferralMonthlyStatsRow createRow(Map<String, dynamic> data) =>
      UserReferralMonthlyStatsRow(data);
}

class UserReferralMonthlyStatsRow extends SupabaseDataRow {
  UserReferralMonthlyStatsRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserReferralMonthlyStatsTable();

  int? get referrerId => getField<int>('referrer_id');
  set referrerId(int? value) => setField<int>('referrer_id', value);

  DateTime? get monthStart => getField<DateTime>('month_start');
  set monthStart(DateTime? value) => setField<DateTime>('month_start', value);

  String? get monthKey => getField<String>('month_key');
  set monthKey(String? value) => setField<String>('month_key', value);

  int? get referralsCount => getField<int>('referrals_count');
  set referralsCount(int? value) => setField<int>('referrals_count', value);

  int? get successfulReferrals => getField<int>('successful_referrals');
  set successfulReferrals(int? value) =>
      setField<int>('successful_referrals', value);

  double? get totalRevenue => getField<double>('total_revenue');
  set totalRevenue(double? value) => setField<double>('total_revenue', value);

  String? get monthLabelFr => getField<String>('month_label_fr');
  set monthLabelFr(String? value) => setField<String>('month_label_fr', value);
}
