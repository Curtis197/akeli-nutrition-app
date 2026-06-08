import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/logger.dart';
import '../shared/models/ingredient_detail.dart';

final ingredientDetailProvider =
    FutureProvider.family<IngredientDetail?, String>((ref, ingredientId) async {
  final logger = appLogger;
  logger.provider('ingredientDetailProvider build() | ingredientId: $ingredientId');
  ref.onDispose(() => logger.provider('ingredientDetailProvider disposed | ingredientId: $ingredientId'));

  logger.db(
      'BEFORE | table: ingredient | op: SELECT | ingredientId: $ingredientId');

  try {
    final data = await Supabase.instance.client
        .from('ingredient')
        .select(
            'id, name_fr, name, calories_per_100g, protein_per_100g, carbs_per_100g, fat_per_100g, fiber_per_100g, substitution, market_notes')
        .eq('id', ingredientId)
        .maybeSingle();

    if (data == null) {
      logger.db('AFTER | table: ingredient | rows: 0');
      logger.rls(
          'Zero rows | table: ingredient | ingredientId: $ingredientId | possible RLS block');
      return null;
    }

    logger.db('AFTER | table: ingredient | rows: 1');
    return IngredientDetail.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      logger.rls(
          'Permission denied | table: ingredient | ingredientId: $ingredientId',
          error: e,
          stackTrace: st);
    } else {
      logger.db(
          'ERROR | table: ingredient | code: ${e.code} | ${e.message}',
          error: e,
          stackTrace: st);
      rethrow;
    }
    rethrow;
  } catch (e, st) {
    logger.db('ERROR | table: ingredient | unexpected | $e', error: e, stackTrace: st);
    rethrow;
  }
});
