import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/datasources/recipe_tracking_datasource.dart';
import '../../data/repositories/recipe_tracking_repository.dart';
import '../../domain/repositories/i_recipe_tracking_repository.dart';

final recipeTrackingDatasourceProvider = Provider<RecipeTrackingDatasource>(
  (ref) => RecipeTrackingDatasource(Supabase.instance.client),
);

final recipeTrackingRepositoryProvider = Provider<IRecipeTrackingRepository>(
  (ref) => RecipeTrackingRepository(
    ref.watch(recipeTrackingDatasourceProvider),
    Supabase.instance.client,
  ),
);
