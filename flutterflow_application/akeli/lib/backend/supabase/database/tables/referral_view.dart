import '../database.dart';

class ReferralViewTable extends SupabaseTable<ReferralViewRow> {
  @override
  String get tableName => 'referral_view';

  @override
  ReferralViewRow createRow(Map<String, dynamic> data) => ReferralViewRow(data);
}

class ReferralViewRow extends SupabaseDataRow {
  ReferralViewRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => ReferralViewTable();

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  int? get subscriptionCount => getField<int>('subscription_count');
  set subscriptionCount(int? value) =>
      setField<int>('subscription_count', value);
}
