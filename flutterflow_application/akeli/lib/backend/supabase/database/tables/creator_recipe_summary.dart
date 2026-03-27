import '../database.dart';

class CreatorRecipeSummaryTable extends SupabaseTable<CreatorRecipeSummaryRow> {
  @override
  String get tableName => 'creator_recipe_summary';

  @override
  CreatorRecipeSummaryRow createRow(Map<String, dynamic> data) =>
      CreatorRecipeSummaryRow(data);
}

class CreatorRecipeSummaryRow extends SupabaseDataRow {
  CreatorRecipeSummaryRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => CreatorRecipeSummaryTable();

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  String? get creatorName => getField<String>('creator_name');
  set creatorName(String? value) => setField<String>('creator_name', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  int? get totalDailyConsumers => getField<int>('total_daily_consumers');
  set totalDailyConsumers(int? value) =>
      setField<int>('total_daily_consumers', value);

  int? get totalRecipes => getField<int>('total_recipes');
  set totalRecipes(int? value) => setField<int>('total_recipes', value);

  int? get publishedRecipes => getField<int>('published_recipes');
  set publishedRecipes(int? value) => setField<int>('published_recipes', value);

  int? get temporaryRecipes => getField<int>('temporary_recipes');
  set temporaryRecipes(int? value) => setField<int>('temporary_recipes', value);

  double? get totalLikes => getField<double>('total_likes');
  set totalLikes(double? value) => setField<double>('total_likes', value);

  double? get totalComments => getField<double>('total_comments');
  set totalComments(double? value) => setField<double>('total_comments', value);

  DateTime? get latestRecipeDate => getField<DateTime>('latest_recipe_date');
  set latestRecipeDate(DateTime? value) =>
      setField<DateTime>('latest_recipe_date', value);
}
