class NutritionCalculatorService {
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
