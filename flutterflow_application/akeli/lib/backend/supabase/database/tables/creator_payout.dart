import '../database.dart';

class CreatorPayoutTable extends SupabaseTable<CreatorPayoutRow> {
  @override
  String get tableName => 'creator_payout';

  @override
  CreatorPayoutRow createRow(Map<String, dynamic> data) =>
      CreatorPayoutRow(data);
}

class CreatorPayoutRow extends SupabaseDataRow {
  CreatorPayoutRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorPayoutTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get creatorId => getField<String>('creator_id')!;
  set creatorId(String value) => setField<String>('creator_id', value);

  DateTime get periodStart => getField<DateTime>('period_start')!;
  set periodStart(DateTime value) => setField<DateTime>('period_start', value);

  DateTime get periodEnd => getField<DateTime>('period_end')!;
  set periodEnd(DateTime value) => setField<DateTime>('period_end', value);

  int? get totalDailyConsumers => getField<int>('total_daily_consumers');
  set totalDailyConsumers(int? value) =>
      setField<int>('total_daily_consumers', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  String? get stripePayoutId => getField<String>('stripe_payout_id');
  set stripePayoutId(String? value) =>
      setField<String>('stripe_payout_id', value);

  String? get stripeStatus => getField<String>('stripe_status');
  set stripeStatus(String? value) => setField<String>('stripe_status', value);

  DateTime? get paidAt => getField<DateTime>('paid_at');
  set paidAt(DateTime? value) => setField<DateTime>('paid_at', value);

  String? get failureReason => getField<String>('failure_reason');
  set failureReason(String? value) => setField<String>('failure_reason', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get payoutMonth => getField<String>('payout_month');
  set payoutMonth(String? value) => setField<String>('payout_month', value);

  String? get stripeTransfertId => getField<String>('stripe_transfert_id');
  set stripeTransfertId(String? value) =>
      setField<String>('stripe_transfert_id', value);

  String? get stripeAccountId => getField<String>('stripe_account_id');
  set stripeAccountId(String? value) =>
      setField<String>('stripe_account_id', value);

  String? get stripeError => getField<String>('stripe_error');
  set stripeError(String? value) => setField<String>('stripe_error', value);
}
