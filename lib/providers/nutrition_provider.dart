import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../shared/mock_data.dart';
import 'auth_provider.dart';

// ---------------------------------------------------------------------------
// Daily nutrition log
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
    required this.fiberG,
    required this.waterMl,
  });

  factory DailyNutrition.fromJson(Map<String, dynamic> json) => DailyNutrition(
        date: DateTime.parse(json['log_date'] as String),
        calories: (json['calories'] as num?)?.toDouble() ?? 0,
        proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0,
        carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0,
        fatG: (json['fat_g'] as num?)?.toDouble() ?? 0,
        fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0,
        waterMl: (json['water_ml'] as num?)?.toDouble() ?? 0,
      );

  DailyNutrition operator +(DailyNutrition other) => DailyNutrition(
        date: date,
        calories: calories + other.calories,
        proteinG: proteinG + other.proteinG,
        carbsG: carbsG + other.carbsG,
        fatG: fatG + other.fatG,
        fiberG: fiberG + other.fiberG,
        waterMl: waterMl + other.waterMl,
      );
}

final todayNutritionProvider =
    FutureProvider.autoDispose<DailyNutrition?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  await Future.delayed(const Duration(milliseconds: 500)); // Simuler latence

  final today = DateTime.now();
  final dateStr =
      '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

  try {
    final entry = MockData.dailyNutritionLogs.firstWhere(
      (log) => log['log_date'] == dateStr,
    );
    return DailyNutrition.fromJson(entry);
  } catch (_) {
    return null;
  }
});

final weeklyNutritionProvider =
    FutureProvider.autoDispose<List<DailyNutrition>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  await Future.delayed(const Duration(milliseconds: 800)); // Simuler latence

  return MockData.dailyNutritionLogs
      .map((e) => DailyNutrition.fromJson(e))
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

  await Future.delayed(const Duration(milliseconds: 600)); // Simuler latence

  return MockData.weightLogs
      .map((e) => WeightEntry.fromJson(e))
      .toList();
});

class WeightLogNotifier extends AutoDisposeAsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> addEntry(double weightKg, {String? note}) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await Future.delayed(const Duration(seconds: 1)); // Simuler réseau
      
      MockData.weightLogs.insert(0, {
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
