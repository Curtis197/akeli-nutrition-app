import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/supabase_client.dart';
import '../core/logger.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Daily nutrition
// ---------------------------------------------------------------------------

@immutable
class DailyNutrition {
  final DateTime date;
  final double calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final double waterMl;

  const DailyNutrition({
    required this.date,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    this.fiberG = 0.0,
    this.waterMl = 0.0,
  });

  factory DailyNutrition.fromJson(Map<String, dynamic> json) => DailyNutrition(
        date: DateTime.parse(json['log_date'] as String),
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
      );

  DailyNutrition operator +(DailyNutrition other) => DailyNutrition(
        date: date,
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
      );
}

final todayNutritionProvider =
    FutureProvider.autoDispose<DailyNutrition?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  appLogger.provider('todayNutritionProvider build() | userId: ${user.id} | date: $dateStr');
  ref.onDispose(() => appLogger.provider('todayNutritionProvider disposed'));
  appLogger.db('BEFORE | table: daily_nutrition_log | op: SELECT | userId: ${user.id} | date: $dateStr');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('daily_nutrition_log')
        .select()
        .eq('user_id', user.id)
        .eq('log_date', dateStr)
        .maybeSingle();
    appLogger.db('AFTER | table: daily_nutrition_log | rows: ${data == null ? 0 : 1} | userId: ${user.id}');
    if (data == null) {
      appLogger.rls('Zero rows | table: daily_nutrition_log | userId: ${user.id} | date: $dateStr | possible RLS block or no log yet');
      appLogger.provider('todayNutritionProvider → data (null)');
      return null;
    }
    appLogger.provider('todayNutritionProvider → data | calories: ${data['calories']}');
    return DailyNutrition.fromJson(data);
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: daily_nutrition_log | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: daily_nutrition_log | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('todayNutritionProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: daily_nutrition_log | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('todayNutritionProvider → error | $e');
    rethrow;
  }
});

final weeklyNutritionProvider =
    FutureProvider.autoDispose<List<DailyNutrition>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final weekAgoStr =
      '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

  appLogger.provider('weeklyNutritionProvider build() | userId: ${user.id} | since: $weekAgoStr');
  ref.onDispose(() => appLogger.provider('weeklyNutritionProvider disposed'));
  appLogger.db('BEFORE | table: daily_nutrition_log | op: SELECT range | userId: ${user.id} | since: $weekAgoStr');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('daily_nutrition_log')
        .select()
        .eq('user_id', user.id)
        .gte('log_date', weekAgoStr)
        .order('log_date');
    appLogger.db('AFTER | table: daily_nutrition_log | rows: ${data.length} | userId: ${user.id}');
    if (data.isEmpty) {
      appLogger.rls('Zero rows | table: daily_nutrition_log | userId: ${user.id} | weekly range | possible RLS block or no logs');
    }
    appLogger.provider('weeklyNutritionProvider → data | days: ${data.length}');
    return data.map(DailyNutrition.fromJson).toList();
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: daily_nutrition_log | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: daily_nutrition_log | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('weeklyNutritionProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: daily_nutrition_log | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('weeklyNutritionProvider → error | $e');
    rethrow;
  }
});

// ---------------------------------------------------------------------------
// Weight log
// ---------------------------------------------------------------------------

@immutable
class WeightEntry {
  final DateTime date;
  final double weightKg;
  final String? note;

  const WeightEntry({
    required this.date,
    required this.weightKg,
    this.note,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
        date: DateTime.parse(json['logged_at'] as String),
        weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 0.0,
        note: json['note'] as String?,
      );
}

final weightLogProvider =
    FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  appLogger.provider('weightLogProvider build() | userId: ${user.id}');
  ref.onDispose(() => appLogger.provider('weightLogProvider disposed'));
  appLogger.db('BEFORE | table: weight_log | op: SELECT | userId: ${user.id}');

  final client = ref.watch(supabaseClientProvider);
  try {
    final data = await client
        .from('weight_log')
        .select()
        .eq('user_id', user.id)
        .order('logged_at', ascending: false);
    appLogger.db('AFTER | table: weight_log | rows: ${data.length} | userId: ${user.id}');
    if (data.isEmpty) {
      appLogger.rls('Zero rows | table: weight_log | userId: ${user.id} | possible RLS block or no entries');
    }
    appLogger.provider('weightLogProvider → data | entries: ${data.length}');
    return data.map(WeightEntry.fromJson).toList();
  } on PostgrestException catch (e, st) {
    if (e.code == '42501') {
      appLogger.rls('Permission denied | table: weight_log | userId: ${user.id}', error: e, stackTrace: st);
    } else {
      appLogger.db('ERROR | table: weight_log | code: ${e.code}', error: e, stackTrace: st);
    }
    appLogger.provider('weightLogProvider → error | ${e.message}');
    rethrow;
  } catch (e, st) {
    appLogger.db('ERROR | table: weight_log | unexpected: $e', error: e, stackTrace: st);
    appLogger.provider('weightLogProvider → error | $e');
    rethrow;
  }
});

class WeightLogNotifier extends AutoDisposeAsyncNotifier<void> {
  final _logger = appLogger;

  @override
  FutureOr<void> build() {
    _logger.provider('WeightLogNotifier build()');
    ref.onDispose(() => _logger.provider('WeightLogNotifier disposed'));
  }

  Future<void> addEntry(double weightKg, {String? note}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    _logger.userAction('Add weight entry', metadata: {'weightKg': weightKg});
    _logger.db('BEFORE | table: weight_log | op: INSERT | userId: ${user.id} | weightKg: $weightKg');
    _logger.provider('WeightLogNotifier → loading (addEntry)');

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      try {
        await client.from('weight_log').insert({
          'user_id': user.id,
          'weight_kg': weightKg,
          if (note != null) 'note': note,
          'logged_at': DateTime.now().toIso8601String(),
        });
        _logger.db('AFTER | table: weight_log | op: INSERT | success | userId: ${user.id}');
        _logger.provider('WeightLogNotifier → data (addEntry success)');
      } on PostgrestException catch (e, st) {
        if (e.code == '42501') {
          _logger.rls('Permission denied | table: weight_log | INSERT | userId: ${user.id}', error: e, stackTrace: st);
        } else {
          _logger.db('ERROR | table: weight_log | INSERT | code: ${e.code}', error: e, stackTrace: st);
        }
        _logger.provider('WeightLogNotifier → error (addEntry)');
        rethrow;
      } catch (e, st) {
        _logger.db('ERROR | table: weight_log | INSERT | unexpected: $e', error: e, stackTrace: st);
        _logger.provider('WeightLogNotifier → error (addEntry unexpected)');
        rethrow;
      }
    });
    if (state is AsyncData) ref.invalidate(weightLogProvider);
  }
}

final weightLogNotifierProvider =
    AsyncNotifierProvider.autoDispose<WeightLogNotifier, void>(
        WeightLogNotifier.new);
