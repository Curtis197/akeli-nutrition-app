// lib/providers/user_preferences_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:akeli/core/logger.dart';
import '../core/supabase_client.dart';
import '../shared/models/user_preferences.dart';
import 'auth_provider.dart';

class UserPreferencesNotifier
    extends AutoDisposeAsyncNotifier<UserPreferencesModel> {
  final _logger = appLogger;

  static const _knownRestrictions = {'no_pork', 'no_meat', 'no_gluten', 'no_lactose'};

  @override
  Future<UserPreferencesModel> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const UserPreferencesModel();

    _logger.provider('UserPreferencesNotifier build() | userId: ${user.id}');
    ref.onDispose(() => _logger.provider('UserPreferencesNotifier disposed'));

    final client = ref.watch(supabaseClientProvider);

    _logger.db('BEFORE | tables: user_health_profile,user_profile,user_cuisine_preference,user_dietary_restriction | op: SELECT | userId: ${user.id}');

    try {
      final healthFuture = client
          .from('user_health_profile')
          .select('cooking_time')
          .eq('user_id', user.id)
          .maybeSingle();

      final profileFuture = client
          .from('user_profile')
          .select('batch_cooking_enabled, batch_cooking_max_portions')
          .eq('id', user.id)
          .single();

      final cuisineFuture = client
          .from('user_cuisine_preference')
          .select('region')
          .eq('user_id', user.id)
          .limit(1)
          .maybeSingle();

      final restrictionsFuture = client
          .from('user_dietary_restriction')
          .select('restriction')
          .eq('user_id', user.id);

      final results = await Future.wait<dynamic>([
        healthFuture,
        profileFuture,
        cuisineFuture,
        restrictionsFuture,
      ]);

      final health = results[0] as Map<String, dynamic>?;
      final profile = results[1] as Map<String, dynamic>;
      final cuisine = results[2] as Map<String, dynamic>?;
      final rawRestrictions = results[3] as List<dynamic>;

      final restrictionCodes =
          rawRestrictions.map((r) => r['restriction'] as String).toList();

      _logger.db('AFTER | tables: user_health_profile,user_profile,user_cuisine_preference,user_dietary_restriction | userId: ${user.id}');
      _logger.provider('UserPreferencesNotifier → data | userId: ${user.id}');

      return UserPreferencesModel(
        cookingTime: health?['cooking_time'] as String?,
        batchCookingEnabled: profile['batch_cooking_enabled'] as bool? ?? false,
        batchMaxPortions: profile['batch_cooking_max_portions'] as int? ?? 4,
        cuisineRegion: cuisine?['region'] as String?,
        noPork: restrictionCodes.contains('no_pork'),
        noMeat: restrictionCodes.contains('no_meat'),
        noGluten: restrictionCodes.contains('no_gluten'),
        noLactose: restrictionCodes.contains('no_lactose'),
        allergies: restrictionCodes
            .where((r) => !_knownRestrictions.contains(r))
            .toList(),
      );
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | UserPreferencesNotifier | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | UserPreferencesNotifier | code: ${e.code}', error: e, stackTrace: st);
      }
      _logger.provider('UserPreferencesNotifier → error | ${e.message}');
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | UserPreferencesNotifier | unexpected: $e', error: e, stackTrace: st);
      _logger.provider('UserPreferencesNotifier → error | $e');
      rethrow;
    }
  }

  Future<void> save(UserPreferencesModel updated) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('UserPreferences save', metadata: {
      'batchEnabled': updated.batchCookingEnabled,
      'maxPortions': updated.batchMaxPortions,
      'cookingTime': updated.cookingTime,
      'region': updated.cuisineRegion,
    });

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();

    try {
      _logger.db('BEFORE | table: user_health_profile | op: UPSERT | userId: ${user.id}');
      await client.from('user_health_profile').upsert({
        'user_id': user.id,
        'cooking_time': updated.cookingTime,
      });
      _logger.db('AFTER | table: user_health_profile | op: UPSERT | rows: 1');

      _logger.db('BEFORE | table: user_profile | op: UPDATE | userId: ${user.id}');
      await client.from('user_profile').update({
        'batch_cooking_enabled': updated.batchCookingEnabled,
        'batch_cooking_max_portions': updated.batchMaxPortions,
      }).eq('id', user.id);
      _logger.db('AFTER | table: user_profile | op: UPDATE | rows: 1');

      _logger.db('BEFORE | table: user_cuisine_preference | op: DELETE | userId: ${user.id}');
      await client.from('user_cuisine_preference').delete().eq('user_id', user.id);
      _logger.db('AFTER | table: user_cuisine_preference | op: DELETE');

      if (updated.cuisineRegion != null) {
        _logger.db('BEFORE | table: user_cuisine_preference | op: INSERT | userId: ${user.id}');
        await client.from('user_cuisine_preference').insert({
          'user_id': user.id,
          'region': updated.cuisineRegion,
          'preference_score': 1.0,
        });
        _logger.db('AFTER | table: user_cuisine_preference | op: INSERT | rows: 1');
      }

      _logger.db('BEFORE | table: user_dietary_restriction | op: DELETE | userId: ${user.id}');
      await client.from('user_dietary_restriction').delete().eq('user_id', user.id);
      _logger.db('AFTER | table: user_dietary_restriction | op: DELETE');

      final restrictions = [
        if (updated.noPork) 'no_pork',
        if (updated.noMeat) 'no_meat',
        if (updated.noGluten) 'no_gluten',
        if (updated.noLactose) 'no_lactose',
        ...updated.allergies,
      ];
      if (restrictions.isNotEmpty) {
        _logger.db('BEFORE | table: user_dietary_restriction | op: INSERT | rows: ${restrictions.length}');
        await client.from('user_dietary_restriction').insert(
          restrictions.map((r) => {'user_id': user.id, 'restriction': r}).toList(),
        );
        _logger.db('AFTER | table: user_dietary_restriction | op: INSERT | rows: ${restrictions.length}');
      }

      _logger.provider('UserPreferencesNotifier → save success');
      state = AsyncData(updated);
      ref.invalidateSelf();
    } on PostgrestException catch (e, st) {
      if (e.code == '42501') {
        _logger.rls('Permission denied | UserPreferencesNotifier save | userId: ${user.id}', error: e, stackTrace: st);
      } else {
        _logger.db('ERROR | UserPreferencesNotifier save | code: ${e.code}', error: e, stackTrace: st);
      }
      _logger.provider('UserPreferencesNotifier → error (save)');
      state = AsyncError(e, st);
      rethrow;
    } catch (e, st) {
      _logger.db('ERROR | UserPreferencesNotifier save | unexpected: $e', error: e, stackTrace: st);
      _logger.provider('UserPreferencesNotifier → error (save unexpected)');
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final userPreferencesProvider = AsyncNotifierProvider.autoDispose<
    UserPreferencesNotifier, UserPreferencesModel>(UserPreferencesNotifier.new);
