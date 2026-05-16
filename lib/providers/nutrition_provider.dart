import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_client.dart';
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

  // Columns: date, total_calories, total_protein_g, total_carbs_g, total_fat_g
  factory DailyNutrition.fromJson(Map<String, dynamic> json) => DailyNutrition(
        date: DateTime.parse(json['date'] as String),
        calories: (json['total_calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['total_protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['total_carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['total_fat_g'] as num?)?.toDouble() ?? 0,
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

  final client = ref.watch(supabaseClientProvider);
  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  final data = await client
      .from('daily_nutrition_log')
      .select()
      .eq('user_id', user.id)
      .eq('date', dateStr)
      .maybeSingle();
  if (data == null) return null;
  return DailyNutrition.fromJson(data);
});

final weeklyNutritionProvider =
    FutureProvider.autoDispose<List<DailyNutrition>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final weekAgo = DateTime.now().subtract(const Duration(days: 7));
  final weekAgoStr =
      '${weekAgo.year}-${weekAgo.month.toString().padLeft(2, '0')}-${weekAgo.day.toString().padLeft(2, '0')}';

  final data = await client
      .from('daily_nutrition_log')
      .select()
      .eq('user_id', user.id)
      .gte('date', weekAgoStr)
      .order('date') as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(DailyNutrition.fromJson)
      .toList();
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
        weightKg: (json['weight_kg'] as num).toDouble(),
        note: json['note'] as String?,
      );
}

final weightLogProvider =
    FutureProvider.autoDispose<List<WeightEntry>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final client = ref.watch(supabaseClientProvider);
  final data = await client
      .from('weight_log')
      .select()
      .eq('user_id', user.id)
      .order('logged_at', ascending: false) as List<dynamic>;

  return data
      .cast<Map<String, dynamic>>()
      .map(WeightEntry.fromJson)
      .toList();
});

class WeightLogNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addEntry(double weightKg, {String? note}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final client = ref.read(supabaseClientProvider);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await client.from('weight_log').insert({
        'user_id': user.id,
        'weight_kg': weightKg,
        if (note != null) 'note': note,
        'logged_at': DateTime.now().toIso8601String(),
      });
      ref.invalidate(weightLogProvider);
    });
  }
}

final weightLogNotifierProvider =
    AsyncNotifierProvider.autoDispose<WeightLogNotifier, void>(
        WeightLogNotifier.new);
