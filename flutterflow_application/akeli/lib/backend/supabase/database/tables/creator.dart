import '../database.dart';

class CreatorTable extends SupabaseTable<CreatorRow> {
  @override
  String get tableName => 'creator';

  @override
  CreatorRow createRow(Map<String, dynamic> data) => CreatorRow(data);
}

class CreatorRow extends SupabaseDataRow {
  CreatorRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get authId => getField<String>('auth_id');
  set authId(String? value) => setField<String>('auth_id', value);

  String? get supabaseAuthId => getField<String>('supabase_auth_id');
  set supabaseAuthId(String? value) =>
      setField<String>('supabase_auth_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get foodRegion => getField<String>('Food Region');
  set foodRegion(String? value) => setField<String>('Food Region', value);

  String? get profilUrl => getField<String>('profil_url');
  set profilUrl(String? value) => setField<String>('profil_url', value);

  bool? get stripeOnboardingComplete =>
      getField<bool>('stripe_onboarding_complete');
  set stripeOnboardingComplete(bool? value) =>
      setField<bool>('stripe_onboarding_complete', value);

  bool? get paymentEnabled => getField<bool>('payment_enabled');
  set paymentEnabled(bool? value) => setField<bool>('payment_enabled', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  int? get totalDailyConsumers => getField<int>('total_daily_consumers');
  set totalDailyConsumers(int? value) =>
      setField<int>('total_daily_consumers', value);

  int? get recipeCount => getField<int>('recipe_count');
  set recipeCount(int? value) => setField<int>('recipe_count', value);

  String? get bio => getField<String>('bio');
  set bio(String? value) => setField<String>('bio', value);

  String? get heritageRegion => getField<String>('heritage_region');
  set heritageRegion(String? value) =>
      setField<String>('heritage_region', value);

  List<String> get specialties => getListField<String>('specialties');
  set specialties(List<String>? value) =>
      setListField<String>('specialties', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  DateTime? get updatedAt => getField<DateTime>('updated_at');
  set updatedAt(DateTime? value) => setField<DateTime>('updated_at', value);

  String? get v1CreatorId => getField<String>('v1_creator_id');
  set v1CreatorId(String? value) => setField<String>('v1_creator_id', value);
}
