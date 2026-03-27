import '../database.dart';

class UserPreferencesTable extends SupabaseTable<UserPreferencesRow> {
  @override
  String get tableName => 'user_preferences';

  @override
  UserPreferencesRow createRow(Map<String, dynamic> data) =>
      UserPreferencesRow(data);
}

class UserPreferencesRow extends SupabaseDataRow {
  UserPreferencesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => UserPreferencesTable();

  String? get id => getField<String>('id');
  set id(String? value) => setField<String>('id', value);

  String? get preference => getField<String>('preference');
  set preference(String? value) => setField<String>('preference', value);

  String? get favoriteFoodRegion => getField<String>('favorite_food_region');
  set favoriteFoodRegion(String? value) =>
      setField<String>('favorite_food_region', value);

  int? get userId => getField<int>('user_id');
  set userId(int? value) => setField<int>('user_id', value);

  String? get particularDiet => getField<String>('particular diet');
  set particularDiet(String? value) =>
      setField<String>('particular diet', value);

  String? get preferredTags => getField<String>('preferred_tags');
  set preferredTags(String? value) => setField<String>('preferred_tags', value);

  String? get dislikedIngredients => getField<String>('disliked_ingredients');
  set dislikedIngredients(String? value) =>
      setField<String>('disliked_ingredients', value);

  bool? get halal => getField<bool>('halal');
  set halal(bool? value) => setField<bool>('halal', value);

  bool? get sansViande => getField<bool>('sans viande');
  set sansViande(bool? value) => setField<bool>('sans viande', value);
}
