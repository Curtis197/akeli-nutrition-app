import '../database.dart';

class PaymentHistoryEnrichedTable
    extends SupabaseTable<PaymentHistoryEnrichedRow> {
  @override
  String get tableName => 'payment_history_enriched';

  @override
  PaymentHistoryEnrichedRow createRow(Map<String, dynamic> data) =>
      PaymentHistoryEnrichedRow(data);
}

class PaymentHistoryEnrichedRow extends SupabaseDataRow {
  PaymentHistoryEnrichedRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => PaymentHistoryEnrichedTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get payoutMonth => getField<String>('payout_month');
  set payoutMonth(String? value) => setField<String>('payout_month', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  String? get stripeStatus => getField<String>('stripe_status');
  set stripeStatus(String? value) => setField<String>('stripe_status', value);

  String? get stripeTransfertId => getField<String>('stripe_transfert_id');
  set stripeTransfertId(String? value) =>
      setField<String>('stripe_transfert_id', value);

  String? get stripeAccountId => getField<String>('stripe_account_id');
  set stripeAccountId(String? value) =>
      setField<String>('stripe_account_id', value);

  String? get stripeError => getField<String>('stripe_error');
  set stripeError(String? value) => setField<String>('stripe_error', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get paidAt => getField<DateTime>('paid_at');
  set paidAt(DateTime? value) => setField<DateTime>('paid_at', value);

  String? get monthLabelEn => getField<String>('month_label_en');
  set monthLabelEn(String? value) => setField<String>('month_label_en', value);

  String? get monthLabelFr => getField<String>('month_label_fr');
  set monthLabelFr(String? value) => setField<String>('month_label_fr', value);

  String? get statusLabelFr => getField<String>('status_label_fr');
  set statusLabelFr(String? value) =>
      setField<String>('status_label_fr', value);

  double? get daysSinceCreated => getField<double>('days_since_created');
  set daysSinceCreated(double? value) =>
      setField<double>('days_since_created', value);

  double? get daysSincePaid => getField<double>('days_since_paid');
  set daysSincePaid(double? value) =>
      setField<double>('days_since_paid', value);
}
