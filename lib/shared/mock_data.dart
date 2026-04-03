import 'models/recipe.dart';
import 'models/user_profile.dart';
import 'models/meal_plan.dart';
import 'models/creator.dart';

class MockData {
  // --- Profiles ---
  static final UserProfile currentUserProfile = UserProfile(
    id: 'mock-user-123',
    email: 'contact@akeli.app',
    username: 'awa_diop',
    firstName: 'Awa',
    lastName: 'Diop',
    avatarUrl: 'https://images.unsplash.com/photo-1531123897727-8f129e1688ce?w=400',
    bio: 'Passionnée de cuisine traditionnelle sénégalaise et de nutrition équilibrée.',
    onboardingDone: true,
    isCreator: false,
    createdAt: DateTime.now().subtract(const Duration(days: 30)),
  );

  static final HealthProfile currentHealthProfile = HealthProfile(
    userId: 'mock-user-123',
    birthDate: DateTime(1995, 5, 15),
    sex: 'female',
    weightKg: 65,
    heightCm: 168,
    targetWeightKg: 60,
    activityLevel: 'moderate',
    primaryGoal: 'lose_weight',
    dietaryRestrictions: const ['gluten_free'],
    cuisinePreferences: const ['senegal', 'mali'],
  );

  // --- Creators ---
  static final List<Creator> creators = [
    const Creator(
      id: 'creator-1',
      userId: 'user-creator-1',
      displayName: 'Chef Oumar',
      avatarUrl: 'https://images.unsplash.com/photo-1583394838336-acd977730f8a?w=400',
      bio: 'Expert en gastronomie ouest-africaine moderne.',
      specialties: ['Sénégalaise', 'Moderne'],
      recipeCount: 42,
      fanCount: 15400,
      isFanEligible: true,
      isMyFanCreator: true,
      averageRating: 4.8,
    ),
    const Creator(
      id: 'creator-2',
      userId: 'user-creator-2',
      displayName: 'Mamina Cuisine',
      avatarUrl: 'https://images.unsplash.com/photo-1566554273541-37a9ca77b91f?w=400',
      bio: 'Les secrets de la cuisine traditionnelle du Cameroun.',
      specialties: ['Camerounaise', 'Traditionnelle'],
      recipeCount: 25,
      fanCount: 8900,
      isFanEligible: true,
      isMyFanCreator: false,
      averageRating: 4.6,
    ),
  ];

  // --- Recipes ---
  static final List<Recipe> recipes = [
    Recipe(
      id: 'recipe-1',
      creatorId: 'creator-1',
      title: 'Thieboudienne Rouge',
      description: 'Le plat national du Sénégal, riche en saveurs et en couleurs.',
      thumbnailUrl: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=600',
      imageUrls: const ['https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=1200'],
      prepTimeMin: 30,
      cookTimeMin: 90,
      servings: 6,
      difficulty: 'hard',
      calories: 650,
      proteinG: 35,
      carbsG: 85,
      fatG: 22,
      fiberG: 8,
      averageRating: 4.8,
      ratingCount: 124,
      likeCount: 450,
      isLiked: true,
      isPublished: true,
      ingredients: const [
        RecipeIngredient(ingredientId: 'i1', name: 'Riz brisé', quantity: 1, unit: 'kg', isOptional: false),
        RecipeIngredient(ingredientId: 'i2', name: 'Mérou (Thiof)', quantity: 1.5, unit: 'kg', isOptional: false),
        RecipeIngredient(ingredientId: 'i3', name: 'Concentré de tomate', quantity: 200, unit: 'g', isOptional: false),
      ],
      steps: const [
        RecipeStep(stepNumber: 1, instruction: 'Préparer la farce (rof) avec du persil, piment, sel et ail.'),
        RecipeStep(stepNumber: 2, instruction: 'Faire dorer le poisson et réserver.'),
      ],
      tagIds: const ['senegal', 'poisson', 'traditionnel'],
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    Recipe(
      id: 'recipe-2',
      creatorId: 'creator-2',
      title: 'Ndolé Camerounais',
      description: 'Un plat mythique à base de feuilles de ndolé et de crevettes.',
      thumbnailUrl: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=600',
      imageUrls: const ['https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=1200'],
      prepTimeMin: 45,
      cookTimeMin: 60,
      servings: 4,
      difficulty: 'medium',
      calories: 520,
      proteinG: 28,
      carbsG: 40,
      fatG: 18,
      fiberG: 12,
      averageRating: 4.6,
      ratingCount: 85,
      likeCount: 230,
      isLiked: false,
      isPublished: true,
      ingredients: const [
        RecipeIngredient(ingredientId: 'i4', name: 'Feuilles de Ndolé', quantity: 500, unit: 'g', isOptional: false),
        RecipeIngredient(ingredientId: 'i5', name: 'Arachides blanches', quantity: 300, unit: 'g', isOptional: false),
        RecipeIngredient(ingredientId: 'i6', name: 'Crevettes', quantity: 250, unit: 'g', isOptional: false),
      ],
      steps: const [
        RecipeStep(stepNumber: 1, instruction: 'Laver et hacher les feuilles de ndolé.'),
        RecipeStep(stepNumber: 2, instruction: 'Écraser les arachides et cuire la pâte.'),
      ],
      tagIds: const ['cameroun', 'viande', 'feuilles'],
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  // --- Meal Plans ---
  static final MealPlan mealPlan = MealPlan(
    id: 'mp-1',
    userId: 'mock-user-123',
    startDate: DateTime.now().subtract(const Duration(days: 2)),
    endDate: DateTime.now().add(const Duration(days: 5)),
    isActive: true,
    entries: [
      MealPlanEntry(
        id: 'mpe-1',
        mealPlanId: 'mp-1',
        recipeId: 'recipe-1',
        recipeTitle: 'Thieboudienne Rouge',
        recipeThumbnail: 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=400',
        mealType: 'lunch',
        scheduledDate: DateTime.now(),
        isConsumed: true,
        calories: 650,
        proteinG: 35,
        carbsG: 85,
        fatG: 22,
      ),
      MealPlanEntry(
        id: 'mpe-2',
        mealPlanId: 'mp-1',
        recipeId: 'recipe-2',
        recipeTitle: 'Ndolé Camerounais',
        recipeThumbnail: 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=400',
        mealType: 'dinner',
        scheduledDate: DateTime.now(),
        isConsumed: false,
        calories: 520,
        proteinG: 28,
        carbsG: 40,
        fatG: 18,
      ),
    ],
  );

  // --- Shopping List ---
  static final List<ShoppingItem> shoppingList = [
    const ShoppingItem(
      ingredientId: 'i1',
      name: 'Riz brisé',
      quantity: 1,
      unit: 'kg',
      category: 'Grains',
      isChecked: false,
    ),
    const ShoppingItem(
      ingredientId: 'i2',
      name: 'Poisson Mérou',
      quantity: 2,
      unit: 'kg',
      category: 'Frais',
      isChecked: true,
    ),
    const ShoppingItem(
      ingredientId: 'i4',
      name: 'Feuilles de Ndolé',
      quantity: 500,
      unit: 'g',
      category: 'Légumes',
      isChecked: false,
    ),
  ];

  // --- Nutrition Logs ---
  static final List<Map<String, dynamic>> dailyNutritionLogs = [
    {
      'user_id': 'mock-user-123',
      'log_date': DateTime.now().toIso8601String().split('T')[0],
      'calories': 1850,
      'protein_g': 120,
      'carbs_g': 210,
      'fat_g': 55,
      'fiber_g': 25,
      'water_ml': 2000,
    },
    {
      'user_id': 'mock-user-123',
      'log_date': DateTime.now().subtract(const Duration(days: 1)).toIso8601String().split('T')[0],
      'calories': 2100,
      'protein_g': 135,
      'carbs_g': 240,
      'fat_g': 62,
      'fiber_g': 28,
      'water_ml': 2500,
    },
    {
      'user_id': 'mock-user-123',
      'log_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String().split('T')[0],
      'calories': 1950,
      'protein_g': 125,
      'carbs_g': 225,
      'fat_g': 58,
      'fiber_g': 26,
      'water_ml': 2200,
    },
  ];

  // --- Weight Logs ---
  static final List<Map<String, dynamic>> weightLogs = [
    {
      'user_id': 'mock-user-123',
      'weight_kg': 65.2,
      'logged_at': DateTime.now().toIso8601String(),
      'note': 'Poids du matin',
    },
    {
      'user_id': 'mock-user-123',
      'weight_kg': 65.5,
      'logged_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      'note': 'Après séance sport',
    },
    {
      'user_id': 'mock-user-123',
      'weight_kg': 66.0,
      'logged_at': DateTime.now().subtract(const Duration(days: 7)).toIso8601String(),
      'note': 'Début de semaine',
    },
  ];

  // --- Subscription ---
  static final Map<String, dynamic> subscription = {
    'user_id': 'mock-user-123',
    'status': 'active',
    'plan_id': 'premium_monthly',
    'current_period_end': DateTime.now().add(const Duration(days: 15)).toIso8601String(),
  };

  // --- Fan Subscriptions ---
  static final Map<String, dynamic> fanSubscription = {
    'user_id': 'mock-user-123',
    'creator_id': 'creator-1',
    'status': 'active',
    'started_at': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
  };
}
