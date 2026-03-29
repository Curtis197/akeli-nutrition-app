import '../models/meal_plan.dart';

class MockMealPlan {
  static MealPlan sevenDayPlan() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(const Duration(days: 6));

    return MealPlan(
      id: 'mock-plan-id',
      userId: 'mock-user-id',
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      entries: _generateMockEntries(startDate, 7),
    );
  }

  static MealPlan threeDayPlan() {
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day);
    final endDate = startDate.add(const Duration(days: 2));

    return MealPlan(
      id: 'mock-plan-3day-id',
      userId: 'mock-user-id',
      startDate: startDate,
      endDate: endDate,
      isActive: true,
      entries: _generateMockEntries(startDate, 3),
    );
  }

  static List<MealPlanEntry> _generateMockEntries(DateTime startDate, int days) {
    final entries = <MealPlanEntry>[];
    
    // Sample Recipes for variety
    final recipes = [
      {
        'title': 'Bol d\'Avoine Protéiné',
        'thumbnail': 'https://images.unsplash.com/photo-1517673132405-a56a62b18acc?q=80&w=500',
        'calories': 350.0,
      },
      {
        'title': 'Salade de Quinoa Mediterranéenne',
        'thumbnail': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500',
        'calories': 420.0,
      },
      {
        'title': 'Poulet Grillé et Patates Douces',
        'thumbnail': 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?q=80&w=500',
        'calories': 550.0,
      },
      {
        'title': 'Smoothie Vert Détox',
        'thumbnail': 'https://images.unsplash.com/photo-1544302661-ca697925f4cc?q=80&w=500',
        'calories': 200.0,
      },
      {
        'title': 'Saumon au Four et Asperges',
        'thumbnail': 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=500',
        'calories': 480.0,
      },
    ];

    for (int day = 0; day < days; day++) {
      final scheduledDate = startDate.add(Duration(days: day));
      
      // Breakfast
      entries.add(MealPlanEntry(
        id: 'mock-entry-$day-breakfast',
        mealPlanId: 'mock-plan-id',
        recipeId: 'rec-1',
        recipeTitle: recipes[0]['title'] as String,
        recipeThumbnail: recipes[0]['thumbnail'] as String,
        mealType: 'breakfast',
        scheduledDate: scheduledDate,
        isConsumed: day < 1, // First day consumed
        calories: recipes[0]['calories'] as double,
      ));

      // Lunch
      entries.add(MealPlanEntry(
        id: 'mock-entry-$day-lunch',
        mealPlanId: 'mock-plan-id',
        recipeId: 'rec-2',
        recipeTitle: recipes[1]['title'] as String,
        recipeThumbnail: recipes[1]['thumbnail'] as String,
        mealType: 'lunch',
        scheduledDate: scheduledDate,
        isConsumed: day < 1,
        calories: recipes[1]['calories'] as double,
      ));

      // Snack (Collation)
      entries.add(MealPlanEntry(
        id: 'mock-entry-$day-snack',
        mealPlanId: 'mock-plan-id',
        recipeId: 'rec-4',
        recipeTitle: recipes[3]['title'] as String,
        recipeThumbnail: recipes[3]['thumbnail'] as String,
        mealType: 'snack',
        scheduledDate: scheduledDate,
        isConsumed: false,
        calories: recipes[3]['calories'] as double,
      ));

      // Dinner
      entries.add(MealPlanEntry(
        id: 'mock-entry-$day-dinner',
        mealPlanId: 'mock-plan-id',
        recipeId: 'rec-3',
        recipeTitle: recipes[2]['title'] as String,
        recipeThumbnail: recipes[2]['thumbnail'] as String,
        mealType: 'dinner',
        scheduledDate: scheduledDate,
        isConsumed: false,
        calories: recipes[2]['calories'] as double,
      ));
    }

    return entries;
  }
}
