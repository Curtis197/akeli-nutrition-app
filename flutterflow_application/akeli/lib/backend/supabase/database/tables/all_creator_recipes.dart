import '../database.dart';

class AllCreatorRecipesTable extends SupabaseTable<AllCreatorRecipesRow> {
  @override
  String get tableName => 'all_creator_recipes';

  @override
  AllCreatorRecipesRow createRow(Map<String, dynamic> data) =>
      AllCreatorRecipesRow(data);
}

class AllCreatorRecipesRow extends SupabaseDataRow {
  AllCreatorRecipesRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => AllCreatorRecipesTable();

  int? get id => getField<int>('id');
  set id(int? value) => setField<int>('id', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  int? get timeOfCookingMin => getField<int>('time_of_cooking_min');
  set timeOfCookingMin(int? value) =>
      setField<int>('time_of_cooking_min', value);

  int? get timeOfCookingHour => getField<int>('time_of_cooking_hour');
  set timeOfCookingHour(int? value) =>
      setField<int>('time_of_cooking_hour', value);

  String? get difficulty => getField<String>('difficulty');
  set difficulty(String? value) => setField<String>('difficulty', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  bool? get isPublished => getField<bool>('is_published');
  set isPublished(bool? value) => setField<bool>('is_published', value);

  int? get likeCount => getField<int>('like_count');
  set likeCount(int? value) => setField<int>('like_count', value);

  int? get commentCount => getField<int>('comment_count');
  set commentCount(int? value) => setField<int>('comment_count', value);

  int? get mealConsumed => getField<int>('meal_consumed');
  set mealConsumed(int? value) => setField<int>('meal_consumed', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  int? get dailyConsumerCount => getField<int>('daily_consumer_count');
  set dailyConsumerCount(int? value) =>
      setField<int>('daily_consumer_count', value);

  List<String> get type => getListField<String>('type');
  set type(List<String>? value) => setListField<String>('type', value);

  String? get foodRegion => getField<String>('food_region');
  set foodRegion(String? value) => setField<String>('food_region', value);

  bool? get temporary => getField<bool>('temporary');
  set temporary(bool? value) => setField<bool>('temporary', value);

  String? get recipeType => getField<String>('recipe_type');
  set recipeType(String? value) => setField<String>('recipe_type', value);

  bool? get isDeleted => getField<bool>('is_deleted');
  set isDeleted(bool? value) => setField<bool>('is_deleted', value);
}
