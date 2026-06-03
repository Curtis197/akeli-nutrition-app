class NutritionCalculatorService {
  // Mifflin-St Jeor
  static double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required String sex,
  }) {
    double bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    if (sex.toLowerCase() == 'male') {
      bmr += 5;
    } else {
      bmr -= 161;
    }
    return bmr;
  }

  static double calculateTDEE(double bmr, String activityLevel) {
    switch (activityLevel) {
      case 'sedentary':
        return bmr * 1.2;
      case 'lightly_active':
        return bmr * 1.375;
      case 'moderately_active':
        return bmr * 1.55;
      case 'very_active':
        return bmr * 1.725;
      case 'extremely_active':
        return bmr * 1.9;
      default:
        return bmr * 1.2;
    }
  }

  static int calculateCalorieGoal(double tdee, String primaryGoal) {
    if (primaryGoal == 'weight_loss') {
      return (tdee - 500).round();
    } else if (primaryGoal == 'muscle_gain' || primaryGoal == 'weight_gain') {
      return (tdee + 300).round();
    }
    return tdee.round(); // maintenance
  }

  static Map<String, double> getDefaultMacros(String primaryGoal) {
    if (primaryGoal == 'weight_loss') {
      return {'protein': 30, 'carbs': 40, 'fat': 30};
    } else if (primaryGoal == 'muscle_gain' || primaryGoal == 'weight_gain') {
      return {'protein': 30, 'carbs': 45, 'fat': 25};
    }
    return {'protein': 25, 'carbs': 50, 'fat': 25}; // maintenance
  }

  static double calculateMacroGrams(int totalCalories, double percentage, String macroType) {
    double caloriesFromMacro = totalCalories * (percentage / 100);
    if (macroType == 'fat') {
      return caloriesFromMacro / 9.0;
    }
    // protein and carbs are 4 calories per gram
    return caloriesFromMacro / 4.0;
  }

  static Map<String, double> getDefaultMealSplits(int mealCount) {
    if (mealCount == 3) {
      return {'breakfast': 30, 'lunch': 35, 'dinner': 35};
    } else if (mealCount == 4) {
      return {'breakfast': 25, 'lunch': 35, 'dinner': 30, 'snack_1': 10};
    }
    
    // Equal split for other counts
    double split = 100.0 / mealCount;
    Map<String, double> splits = {};
    for (int i = 0; i < mealCount; i++) {
      String key = i == 0 ? 'breakfast' : i == 1 ? 'lunch' : i == 2 ? 'dinner' : 'snack_${i - 2}';
      splits[key] = double.parse(split.toStringAsFixed(1));
    }
    return splits;
  }
}
