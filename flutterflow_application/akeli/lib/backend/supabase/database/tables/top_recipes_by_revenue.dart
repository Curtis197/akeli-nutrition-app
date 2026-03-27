import '../database.dart';

class TopRecipesByRevenueTable extends SupabaseTable<TopRecipesByRevenueRow> {
  @override
  String get tableName => 'top_recipes_by_revenue';

  @override
  TopRecipesByRevenueRow createRow(Map<String, dynamic> data) =>
      TopRecipesByRevenueRow(data);
}

class TopRecipesByRevenueRow extends SupabaseDataRow {
  TopRecipesByRevenueRow(Map<String, dynamic> data) : super(data);

  @override
  SupabaseTable get table => TopRecipesByRevenueTable();

  int? get recipeId => getField<int>('recipe_id');
  set recipeId(int? value) => setField<int>('recipe_id', value);

  String? get name => getField<String>('name');
  set name(String? value) => setField<String>('name', value);

  String? get description => getField<String>('description');
  set description(String? value) => setField<String>('description', value);

  String? get creatorId => getField<String>('creator_id');
  set creatorId(String? value) => setField<String>('creator_id', value);

  double? get totalEarnings => getField<double>('total_earnings');
  set totalEarnings(double? value) => setField<double>('total_earnings', value);

  int? get likeCount => getField<int>('like_count');
  set likeCount(int? value) => setField<int>('like_count', value);

  int? get totalConsumers => getField<int>('total_consumers');
  set totalConsumers(int? value) => setField<int>('total_consumers', value);

  DateTime? get createdAt => getField<DateTime>('created_at');
  set createdAt(DateTime? value) => setField<DateTime>('created_at', value);

  int? get rankByRevenue => getField<int>('rank_by_revenue');
  set rankByRevenue(int? value) => setField<int>('rank_by_revenue', value);

  int? get rankByLikes => getField<int>('rank_by_likes');
  set rankByLikes(int? value) => setField<int>('rank_by_likes', value);

  int? get rankByConsumers => getField<int>('rank_by_consumers');
  set rankByConsumers(int? value) => setField<int>('rank_by_consumers', value);
}
