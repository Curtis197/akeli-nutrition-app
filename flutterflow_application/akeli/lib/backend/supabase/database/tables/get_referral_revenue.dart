import '../database.dart';

class GetReferralRevenueTable extends SupabaseTable<GetReferralRevenueRow> {
  @override
  String get tableName => 'get_referral_revenue';

  @override
  GetReferralRevenueRow createRow(Map<String, dynamic> data) =>
      GetReferralRevenueRow(data);
}

class GetReferralRevenueRow extends SupabaseDataRow {
  GetReferralRevenueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => GetReferralRevenueTable();

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  int? get receipeCount => getField<int>('receipe_count');
  set receipeCount(int? value) => setField<int>('receipe_count', value);

  int? get countMeal => getField<int>('count_meal');
  set countMeal(int? value) => setField<int>('count_meal', value);

  double? get revenueCents => getField<double>('revenue_cents');
  set revenueCents(double? value) => setField<double>('revenue_cents', value);
}
