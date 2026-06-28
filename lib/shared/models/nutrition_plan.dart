class MealDistribution {
  final String? id;
  final String? nutritionPlanId;
  final String mealType;
  final int sortOrder;
  final double caloriePct;
  final double? calorieTarget;
  final int minPortionG;
  final int maxPortionG;
  // NEW fields
  final String? nickname;
  final double? proteinPct;
  final double? carbsPct;
  final double? fatPct;

  MealDistribution({
    this.id,
    this.nutritionPlanId,
    required this.mealType,
    required this.sortOrder,
    required this.caloriePct,
    this.calorieTarget,
    this.minPortionG = 50,
    this.maxPortionG = 1500,
    this.nickname,
    this.proteinPct,
    this.carbsPct,
    this.fatPct,
  });

  factory MealDistribution.fromJson(Map<String, dynamic> json) {
    return MealDistribution(
      id: json['id'] as String?,
      nutritionPlanId: json['nutrition_plan_id'] as String?,
      mealType: json['meal_type'] as String,
      sortOrder: json['sort_order'] as int,
      caloriePct: (json['calorie_pct'] as num).toDouble(),
      calorieTarget: json['calorie_target'] != null
          ? (json['calorie_target'] as num).toDouble()
          : null,
      minPortionG: (json['min_portion_g'] as int?) ?? 50,
      maxPortionG: (json['max_portion_g'] as int?) ?? 1500,
      nickname: json['nickname'] as String?,
      proteinPct: (json['protein_pct'] as num?)?.toDouble(),
      carbsPct: (json['carbs_pct'] as num?)?.toDouble(),
      fatPct: (json['fat_pct'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (nutritionPlanId != null) 'nutrition_plan_id': nutritionPlanId,
      'meal_type': mealType,
      'sort_order': sortOrder,
      'calorie_pct': caloriePct,
      if (calorieTarget != null) 'calorie_target': calorieTarget,
      'min_portion_g': minPortionG,
      'max_portion_g': maxPortionG,
      if (nickname != null) 'nickname': nickname,
      if (proteinPct != null) 'protein_pct': proteinPct,
      if (carbsPct != null) 'carbs_pct': carbsPct,
      if (fatPct != null) 'fat_pct': fatPct,
    };
  }

  MealDistribution copyWith({
    String? id,
    String? nutritionPlanId,
    String? mealType,
    int? sortOrder,
    double? caloriePct,
    double? calorieTarget,
    int? minPortionG,
    int? maxPortionG,
    String? nickname,
    double? proteinPct,
    double? carbsPct,
    double? fatPct,
  }) {
    return MealDistribution(
      id: id ?? this.id,
      nutritionPlanId: nutritionPlanId ?? this.nutritionPlanId,
      mealType: mealType ?? this.mealType,
      sortOrder: sortOrder ?? this.sortOrder,
      caloriePct: caloriePct ?? this.caloriePct,
      calorieTarget: calorieTarget ?? this.calorieTarget,
      minPortionG: minPortionG ?? this.minPortionG,
      maxPortionG: maxPortionG ?? this.maxPortionG,
      nickname: nickname ?? this.nickname,
      proteinPct: proteinPct ?? this.proteinPct,
      carbsPct: carbsPct ?? this.carbsPct,
      fatPct: fatPct ?? this.fatPct,
    );
  }
}

class NutritionPlan {
  final String? id;
  final String userId;
  final int calorieGoal;
  final double proteinGoalG;
  final double carbGoalG;
  final double fatGoalG;
  final double? bmr;
  final double? tdee;
  final bool isActive;
  final List<MealDistribution>? distributions;

  NutritionPlan({
    this.id,
    required this.userId,
    required this.calorieGoal,
    required this.proteinGoalG,
    required this.carbGoalG,
    required this.fatGoalG,
    this.bmr,
    this.tdee,
    this.isActive = true,
    this.distributions,
  });

  factory NutritionPlan.fromJson(Map<String, dynamic> json) {
    return NutritionPlan(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      calorieGoal: json['calorie_goal'] as int,
      proteinGoalG: (json['protein_goal_g'] as num).toDouble(),
      carbGoalG: (json['carb_goal_g'] as num).toDouble(),
      fatGoalG: (json['fat_goal_g'] as num).toDouble(),
      bmr: json['bmr'] != null ? (json['bmr'] as num).toDouble() : null,
      tdee: json['tdee'] != null ? (json['tdee'] as num).toDouble() : null,
      isActive: json['is_active'] as bool? ?? true,
      distributions: json['distributions'] != null
          ? (json['distributions'] as List).map((e) => MealDistribution.fromJson(e)).toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'calorie_goal': calorieGoal,
      'protein_goal_g': proteinGoalG,
      'carb_goal_g': carbGoalG,
      'fat_goal_g': fatGoalG,
      if (bmr != null) 'bmr': bmr,
      if (tdee != null) 'tdee': tdee,
      'is_active': isActive,
    };
  }
}
