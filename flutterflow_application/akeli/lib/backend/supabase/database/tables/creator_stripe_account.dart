import '../database.dart';

class CreatorStripeAccountTable extends SupabaseTable<CreatorStripeAccountRow> {
  @override
  String get tableName => 'creator_stripe_account';

  @override
  CreatorStripeAccountRow createRow(Map<String, dynamic> data) =>
      CreatorStripeAccountRow(data);
}

class CreatorStripeAccountRow extends SupabaseDataRow {
  CreatorStripeAccountRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorStripeAccountTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String get creatorId => getField<String>('creator_id')!;
  set creatorId(String value) => setField<String>('creator_id', value);

  String get stripeAccountId => getField<String>('stripe_account_id')!;
  set stripeAccountId(String value) =>
      setField<String>('stripe_account_id', value);

  bool? get stripeOnboardingComplete =>
      getField<bool>('stripe_onboarding_complete');
  set stripeOnboardingComplete(bool? value) =>
      setField<bool>('stripe_onboarding_complete', value);

  bool? get stripeChargesEnabled => getField<bool>('stripe_charges_enabled');
  set stripeChargesEnabled(bool? value) =>
      setField<bool>('stripe_charges_enabled', value);

  bool? get stripePayoutsEnabled => getField<bool>('stripe_payouts_enabled');
  set stripePayoutsEnabled(bool? value) =>
      setField<bool>('stripe_payouts_enabled', value);

  String? get stripeRequirementsDisabledReason =>
      getField<String>('stripe_requirements_disabled_reason');
  set stripeRequirementsDisabledReason(String? value) =>
      setField<String>('stripe_requirements_disabled_reason', value);

  String? get countryCode => getField<String>('country_code');
  set countryCode(String? value) => setField<String>('country_code', value);

  String? get currency => getField<String>('currency');
  set currency(String? value) => setField<String>('currency', value);

  String? get accountType => getField<String>('account_type');
  set accountType(String? value) => setField<String>('account_type', value);

  String? get email => getField<String>('email');
  set email(String? value) => setField<String>('email', value);

  dynamic? get metadata => getField<dynamic>('metadata');
  set metadata(dynamic? value) => setField<dynamic>('metadata', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);
}
