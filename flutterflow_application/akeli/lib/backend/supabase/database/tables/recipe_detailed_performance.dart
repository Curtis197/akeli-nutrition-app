import '../database.dart';

class RecipeDetailedPerformanceTable
    extends SupabaseTable<RecipeDetailedPerformanceRow> {
  @override
  String get tableName => 'recipe_detailed_performance';

  @override
  RecipeDetailedPerformanceRow createRow(Map<String, dynamic> data) =>
      RecipeDetailedPerformanceRow(data);
}

class RecipeDetailedPerformanceRow extends SupabaseDataRow {
  RecipeDetailedPerformanceRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => RecipeDetailedPerformanceTable();

  int? get recipeId => getField<int>('recipe_id');
  set recipeId(int? value) => setField<int>('recipe_id', value);

  String? get recipeName => getField<String>('recipe_name');
  set recipeName(String? value) => setField<String>('recipe_name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get foodRegion => getField<String>('Food Region');
  set foodRegion(String? value) => setField<String>('Food Region', value);

  List<String> get type => getListField<String>('type');
  set type(List<String>? value) => setListField<String>('type', value);

  String? get difficulty => getField<String>('difficulty');
  set difficulty(String? value) => setField<String>('difficulty', value);

  DateTime? get publishedAt => getField<DateTime>('published_at');
  set publishedAt(DateTime? value) => setField<DateTime>('published_at', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  bool? get isPublished => getField<bool>('is_published');
  set isPublished(bool? value) => setField<bool>('is_published', value);

  int? get timeOfCookingMin => getField<int>('time_of_cooking_min');
  set timeOfCookingMin(int? value) =>
      setField<int>('time_of_cooking_min', value);

  int? get timeOfCookingHour => getField<int>('time_of_cooking_hour');
  set timeOfCookingHour(int? value) =>
      setField<int>('time_of_cooking_hour', value);

  int? get likeCount => getField<int>('like_count');
  set likeCount(int? value) => setField<int>('like_count', value);

  int? get commentCount => getField<int>('comment_count');
  set commentCount(int? value) => setField<int>('comment_count', value);

  int? get totalMealsConsumed => getField<int>('total_meals_consumed');
  set totalMealsConsumed(int? value) =>
      setField<int>('total_meals_consumed', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  int? get totalIndividualConsumers =>
      getField<int>('total_individual_consumers');
  set totalIndividualConsumers(int? value) =>
      setField<int>('total_individual_consumers', value);

  bool? get free => getField<bool>('free');
  set free(bool? value) => setField<bool>('free', value);

  double? get avgRating => getField<double>('avg_rating');
  set avgRating(double? value) => setField<double>('avg_rating', value);

  int? get totalRatingsCount => getField<int>('total_ratings_count');
  set totalRatingsCount(int? value) =>
      setField<int>('total_ratings_count', value);

  dynamic? get ratingBreakdown => getField<dynamic>('rating_breakdown');
  set ratingBreakdown(dynamic? value) =>
      setField<dynamic>('rating_breakdown', value);

  int? get currentWeekConsumers => getField<int>('current_week_consumers');
  set currentWeekConsumers(int? value) =>
      setField<int>('current_week_consumers', value);

  double? get currentWeekEarnings => getField<double>('current_week_earnings');
  set currentWeekEarnings(double? value) =>
      setField<double>('current_week_earnings', value);

  dynamic? get weekDailyBreakdown => getField<dynamic>('week_daily_breakdown');
  set weekDailyBreakdown(dynamic? value) =>
      setField<dynamic>('week_daily_breakdown', value);

  int? get last30DaysConsumers => getField<int>('last_30_days_consumers');
  set last30DaysConsumers(int? value) =>
      setField<int>('last_30_days_consumers', value);

  double? get last30DaysEarnings => getField<double>('last_30_days_earnings');
  set last30DaysEarnings(double? value) =>
      setField<double>('last_30_days_earnings', value);

  DateTime? get lastConsumedDate => getField<DateTime>('last_consumed_date');
  set lastConsumedDate(DateTime? value) =>
      setField<DateTime>('last_consumed_date', value);

  DateTime? get lastConsumedAt => getField<DateTime>('last_consumed_at');
  set lastConsumedAt(DateTime? value) =>
      setField<DateTime>('last_consumed_at', value);
}
