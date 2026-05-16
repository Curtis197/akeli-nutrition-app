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

  static List<MealPlanEntry> _generateMockEntries(
      DateTime startDate, int days) {
    final entries = <MealPlanEntry>[];

    final recipes = [
      {
        'id': 'rec-1',
        'title': "Bol d'Avoine Protéiné",
        'thumbnail':
            'https://images.unsplash.com/photo-1517673132405-a56a62b18acc?q=80&w=500',
        'calories': 350.0,
      },
      {
        'id': 'rec-2',
        'title': 'Salade de Quinoa Mediterranéenne',
        'thumbnail':
            'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=500',
        'calories': 420.0,
      },
      {
        'id': 'rec-3',
        'title': 'Poulet Grillé et Patates Douces',
        'thumbnail':
            'https://images.unsplash.com/photo-1532550907401-a500c9a57435?q=80&w=500',
        'calories': 550.0,
      },
      {
        'id': 'rec-4',
        'title': 'Smoothie Vert Détox',
        'thumbnail':
            'https://images.unsplash.com/photo-1544302661-ca697925f4cc?q=80&w=500',
        'calories': 200.0,
      },
    ];

    MealPlanEntryComponent component(
            String entryId, Map<String, Object> recipe) =>
        MealPlanEntryComponent(
          id: 'comp-$entryId',
          mealPlanEntryId: entryId,
          recipeId: recipe['id'] as String,
          recipeTitle: recipe['title'] as String,
          recipeThumbnail: recipe['thumbnail'] as String,
          role: 'base',
          consumptionWeight: 1.0,
          calories: recipe['calories'] as double,
        );

    for (int day = 0; day < days; day++) {
      final scheduledDate = startDate.add(Duration(days: day));

      final breakfastId = 'mock-entry-$day-breakfast';
      entries.add(MealPlanEntry(
        id: breakfastId,
        mealPlanId: 'mock-plan-id',
        mealType: 'breakfast',
        scheduledDate: scheduledDate,
        isConsumed: day < 1,
        components: [component(breakfastId, recipes[0])],
      ));

      final lunchId = 'mock-entry-$day-lunch';
      entries.add(MealPlanEntry(
        id: lunchId,
        mealPlanId: 'mock-plan-id',
        mealType: 'lunch',
        scheduledDate: scheduledDate,
        isConsumed: day < 1,
        components: [component(lunchId, recipes[1])],
      ));

      final snackId = 'mock-entry-$day-snack';
      entries.add(MealPlanEntry(
        id: snackId,
        mealPlanId: 'mock-plan-id',
        mealType: 'snack',
        scheduledDate: scheduledDate,
        isConsumed: false,
        components: [component(snackId, recipes[3])],
      ));

      final dinnerId = 'mock-entry-$day-dinner';
      entries.add(MealPlanEntry(
        id: dinnerId,
        mealPlanId: 'mock-plan-id',
        mealType: 'dinner',
        scheduledDate: scheduledDate,
        isConsumed: false,
        components: [component(dinnerId, recipes[2])],
      ));
    }

    return entries;
  }
}
