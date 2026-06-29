// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Akeli';

  @override
  String get appVersion => 'Akeli V1.0';

  @override
  String get notificationSeeLabel => 'View';

  @override
  String get notificationDefaultTitle => 'New Notification';

  @override
  String get navHome => 'Home';

  @override
  String get navMeals => 'Meals';

  @override
  String get navRecipes => 'Recipes';

  @override
  String get navCommunity => 'Community';

  @override
  String get tooltipSettings => 'Settings';

  @override
  String get tooltipNotifications => 'Notifications';

  @override
  String get authWelcome => 'Welcome to Akeli';

  @override
  String get authSignUp => 'Sign Up';

  @override
  String get authLogIn => 'Log In';

  @override
  String get authCreateAccount => 'Create your account';

  @override
  String get authJoinCommunity => 'Join the Akeli community';

  @override
  String get authEmailPlaceholder => 'Enter your email';

  @override
  String get authEmailRequired => 'Email required';

  @override
  String get authEmailInvalid => 'Invalid email';

  @override
  String get authPasswordCreate => 'Create a password';

  @override
  String get authPasswordRequired => 'Password required';

  @override
  String get authPasswordMinLength => 'Minimum 8 characters';

  @override
  String get authConfirmPassword => 'Confirm your password';

  @override
  String get authPasswordMismatch => 'Passwords do not match';

  @override
  String get authGetStarted => 'Get Started';

  @override
  String get authWelcomeBack => 'Welcome back!';

  @override
  String get authSignInToAccount => 'Sign in to your account';

  @override
  String get authEmailField => 'Email';

  @override
  String get authPasswordField => 'Password';

  @override
  String get authPasswordReset => 'Password reset — coming soon';

  @override
  String get authForgotPassword => 'Forgot password?';

  @override
  String get authSignIn => 'Sign In';

  @override
  String get authErrorInvalidCredentials => 'Incorrect email or password.';

  @override
  String get authErrorEmailInUse => 'This email is already in use.';

  @override
  String get authErrorPasswordShort =>
      'Password must be at least 6 characters.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Please confirm your email address before signing in.';

  @override
  String get authErrorGeneric => 'An error occurred. Please try again.';

  @override
  String homeGreeting(String name) {
    return 'Hello, $name!';
  }

  @override
  String get homeGreetingFallback => 'Hello!';

  @override
  String get homeWelcomeBack => 'Happy to see you again.';

  @override
  String get homeWeightLabel => 'Weight';

  @override
  String get homeWeightCurrent => 'Current Weight';

  @override
  String get homeCaloriesLabel => 'Calories';

  @override
  String get homeViewProgress => 'View my progress →';

  @override
  String get homeTodayMeals => 'Today\'s Meals';

  @override
  String get homeNoMealsToday => 'No meals planned for today.';

  @override
  String get homeMealDefault => 'Meal';

  @override
  String get homeMealUpdateError => 'Unable to update meal. Try again.';

  @override
  String get homeShoppingList => 'Shopping List';

  @override
  String get homeViewAll => 'View All';

  @override
  String get homeFilterAll => 'All';

  @override
  String get homeFilterToBuy => 'To Buy';

  @override
  String get homeFilterBought => 'Already Bought';

  @override
  String get homeNoItemsFound => 'No items found';

  @override
  String get homeRecommendedRecipes => 'Recommended Recipes';

  @override
  String get homeNoRecipes => 'No recipes available.';

  @override
  String homeErrorGeneric(String error) {
    return 'Error: $error';
  }

  @override
  String get homeCreatorsForYou => 'Creators for You';

  @override
  String get homeCreateRecipe => 'Create and share your own recipe';

  @override
  String get feedTitle => 'Discover';

  @override
  String get feedSearchHint => 'Search recipes...';

  @override
  String get feedTabRecipes => 'Recipes';

  @override
  String get feedTabCreators => 'Creators';

  @override
  String get feedNoResults => 'No results found';

  @override
  String get feedNoResultsSubtitle => 'Try different search terms or filters';

  @override
  String get feedEmptyTitle => 'No recipes yet';

  @override
  String get feedFilters => 'Filters';

  @override
  String get feedFilterRegion => 'Region';

  @override
  String get feedFilterDifficulty => 'Difficulty';

  @override
  String get feedFilterTime => 'Max Time';

  @override
  String get feedFilterMealType => 'Meal Type';

  @override
  String get feedFilterCalories => 'Calories';

  @override
  String get feedSortBy => 'Sort by';

  @override
  String get feedAllRegions => 'All regions';

  @override
  String get feedAllDifficulties => 'All difficulties';

  @override
  String get feedAllMealTypes => 'All types';

  @override
  String get feedApplyFilters => 'Apply';

  @override
  String get feedResetFilters => 'Reset';

  @override
  String get feedLoadMore => 'Load more';

  @override
  String get feedCreatorSearch => 'Search creators...';

  @override
  String get feedCreatorSpecialty => 'Specialty';

  @override
  String get feedAllSpecialties => 'All specialties';

  @override
  String get feedNoCreators => 'No creators found';

  @override
  String get feedAddToMealPlan => 'Add to Meal Plan';

  @override
  String get feedAddedToMealPlan => 'Added to meal plan';

  @override
  String get feedSwapRecipe => 'Swap';

  @override
  String get feedSwapDone => 'Recipe swapped';

  @override
  String get recipeDetailIngredients => 'Ingredients';

  @override
  String get recipeDetailInstructions => 'Instructions';

  @override
  String get recipeDetailNutrition => 'Nutrition Info';

  @override
  String get recipeDetailPrepTime => 'Prep Time';

  @override
  String get recipeDetailCookTime => 'Cook Time';

  @override
  String get recipeDetailServings => 'Servings';

  @override
  String get recipeDetailDifficulty => 'Difficulty';

  @override
  String get recipeDetailCalories => 'Calories';

  @override
  String get recipeDetailProtein => 'Protein';

  @override
  String get recipeDetailCarbs => 'Carbs';

  @override
  String get recipeDetailFat => 'Fat';

  @override
  String get recipeDetailSave => 'Save';

  @override
  String get recipeDetailSaved => 'Saved';

  @override
  String get recipeDetailLike => 'Like';

  @override
  String get recipeDetailShare => 'Share';

  @override
  String get recipeDetailComments => 'Comments';

  @override
  String get recipeDetailNoComments => 'No comments yet';

  @override
  String get recipeDetailAddComment => 'Add a comment...';

  @override
  String get recipeDetailSendComment => 'Send';

  @override
  String get recipeDetailLoadError => 'Error loading recipe';

  @override
  String get recipeDetailMin => 'min';

  @override
  String get recipeDetailPer100g => 'per 100g';

  @override
  String recipeDetailStepLabel(int step) {
    return 'Step $step';
  }

  @override
  String get recipeDetailRegion => 'Region';

  @override
  String get recipeDetailTags => 'Tags';

  @override
  String get recipeDetailVideoTitle => 'Recipe Video';

  @override
  String get recipeDetailAddToMealPlan => 'Add to Meal Plan';

  @override
  String get recipeDetailAddedToMealPlan => 'Added to your meal plan';

  @override
  String get recipeDetailErrorAddPlan => 'Error adding to meal plan';

  @override
  String get recipeDetailBy => 'by';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileDefaultName => 'User';

  @override
  String profileLoadError(String error) {
    return 'Error: $error';
  }

  @override
  String get profilePrivateTitle => 'This profile is private';

  @override
  String get profilePrivateMessage => 'Send a message to connect.';

  @override
  String get profileTabRecipes => 'Recipes';

  @override
  String get profileTabComments => 'Comments';

  @override
  String get profileTabGroups => 'Groups';

  @override
  String get profileLoadError2 => 'Loading error';

  @override
  String get profileNoLikedRecipes => 'No liked recipes';

  @override
  String get profileNoComments => 'No comments';

  @override
  String get profileNoGroups => 'No groups';

  @override
  String get profileUnknownRecipe => 'Unknown recipe';

  @override
  String get profileGroupDefault => 'Group';

  @override
  String profileMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '$count member',
    );
    return '$_temp0';
  }

  @override
  String get profileStartConversation => 'Start a conversation';

  @override
  String get profileMessageSent => 'Request sent';

  @override
  String get profileMessageError => 'Error sending request';

  @override
  String get profilePending => 'Pending';

  @override
  String get profileMessage => 'Message';

  @override
  String get profileCloseConversationTitle => 'Close conversation?';

  @override
  String get profileCloseConversationContent =>
      'You will leave this conversation. The other user will keep their history.';

  @override
  String get profileConversationClosed => 'Conversation closed';

  @override
  String get profileCloseError => 'Error closing conversation';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsEdit => 'Edit';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsSectionMenu => 'Menu';

  @override
  String get settingsNutritionTracking => 'Nutrition Tracking';

  @override
  String get settingsSavedRecipes => 'Saved Recipes';

  @override
  String get settingsAccount => 'My Account';

  @override
  String get settingsFanMode => 'Fan Mode';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsHealthGoals => 'Health & Goals';

  @override
  String get settingsSectionApp => 'Application';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageCurrent => 'English';

  @override
  String get settingsSectionPrivacy => 'Privacy';

  @override
  String get settingsPrivateProfile => 'Private Profile';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsHelpFaq => 'Help & FAQ';

  @override
  String get settingsPrivacyPolicy => 'Privacy Policy';

  @override
  String get settingsTerms => 'Terms of Use';

  @override
  String get settingsSignOut => 'Sign Out';

  @override
  String get settingsSignOutTitle => 'Sign Out';

  @override
  String get settingsSignOutConfirm => 'Are you sure you want to sign out?';

  @override
  String get settingsSignOutConfirmBtn => 'Sign Out';

  @override
  String get settingsEditProfile => 'Edit Profile';

  @override
  String get settingsName => 'Name';

  @override
  String get settingsDescription => 'Description';

  @override
  String get settingsDescriptionHint => 'Tell us a bit about yourself...';

  @override
  String get settingsSave => 'Save';

  @override
  String settingsAvatarError(String error) {
    return 'Error: $error';
  }

  @override
  String get mealPlannerTitle => 'Your Meals';

  @override
  String get mealPlannerWeekTitle => 'Your meals this week';

  @override
  String get mealPlannerDaysTitle => 'Your upcoming meals';

  @override
  String get mealPlannerViewDietPlan => 'View my diet plan';

  @override
  String get mealPlannerViewShoppingList => 'View my shopping list';

  @override
  String get mealPlannerViewBatchCooking => 'Batch cooking';

  @override
  String get mealPlannerEmpty => 'No meal plan yet';

  @override
  String get mealPlannerEmptySubtitle => 'Generate a personalized plan';

  @override
  String get mealPlannerGenerate => 'Generate my plan';

  @override
  String mealPlannerError(String error) {
    return 'Error: $error';
  }

  @override
  String get mealPlannerConsumptionError => 'Unable to update. Try again.';

  @override
  String get mealTypeBreakfast => 'Breakfast';

  @override
  String get mealTypeLunch => 'Lunch';

  @override
  String get mealTypeDinner => 'Dinner';

  @override
  String get mealTypeSnack => 'Snack';

  @override
  String get nutritionTitle => 'Nutrition';

  @override
  String get nutritionTabToday => 'Today';

  @override
  String get nutritionTabWeek => 'Week';

  @override
  String get nutritionTabJourney => 'Journey';

  @override
  String get nutritionCalories => 'Calories';

  @override
  String get nutritionProtein => 'Protein';

  @override
  String get nutritionCarbs => 'Carbs';

  @override
  String get nutritionFat => 'Fat';

  @override
  String get nutritionNoData => 'No nutrition data today';

  @override
  String get nutritionNoPlan => 'No nutrition plan';

  @override
  String get nutritionGoal => 'Goal';

  @override
  String get nutritionConsumed => 'Consumed';

  @override
  String get nutritionRemaining => 'Remaining';

  @override
  String get nutritionWeightTracking => 'Weight Tracking';

  @override
  String get nutritionCurrentWeight => 'Current weight';

  @override
  String get nutritionTargetWeight => 'Target weight';

  @override
  String get nutritionAddWeight => 'Log Weight';

  @override
  String get nutritionWeightAdded => 'Weight logged';

  @override
  String get nutritionHydration => 'Hydration';

  @override
  String get nutritionMyWeight => 'My Weight';

  @override
  String get nutritionNewRecord => 'New Log';

  @override
  String get nutritionConsumedMeals => 'Consumed meals';

  @override
  String nutritionTargetAchieved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You reached your goals $count times this week.',
      one: 'You reached your goals $count time this week.',
      zero: 'You didn\'t reach your goals this week.',
    );
    return '$_temp0';
  }

  @override
  String get nutritionSummary => 'SUMMARY';

  @override
  String get nutritionAvgKcal => 'avg. kcal';

  @override
  String get nutritionWeightVariation => 'weight change';

  @override
  String get nutritionEveryDay => 'EVERY DAY';

  @override
  String get nutritionWeightLabel => 'Weight';

  @override
  String nutritionProgressPercentage(int pct) {
    return '$pct% of goal';
  }

  @override
  String get nutritionAddFirstWeight =>
      'Add your first weight log to start tracking.';

  @override
  String get nutritionLogAnotherWeight =>
      'Log another weight to see your trend.';

  @override
  String get communityTitle => 'Community';

  @override
  String get communityMyGroups => 'My Groups';

  @override
  String get communityPrivateGroups => 'Private';

  @override
  String get communityPublicGroups => 'Public';

  @override
  String get communityDiscoverGroups => 'Discover Groups';

  @override
  String get communityNoGroups => 'No groups yet';

  @override
  String get communityCreateGroup => 'Create';

  @override
  String get communityJoinSuccess => 'Group joined successfully';

  @override
  String get communityJoinError => 'Error joining group';

  @override
  String get communityRegionFilter => 'Region';

  @override
  String get communityAllRegions => 'All regions';

  @override
  String get communityRegionError => 'Region error';

  @override
  String get communityNoCriteria => 'No groups match these criteria.';

  @override
  String get communityGroupImageError => 'Error selecting image';

  @override
  String get communityGeneralChannel => 'General';

  @override
  String get communitySending => 'Sending…';

  @override
  String get cookingModeTitle => 'Cooking Mode';

  @override
  String cookingModeStep(int step, int total) {
    return 'Step $step of $total';
  }

  @override
  String get cookingModeIngredients => 'Ingredients';

  @override
  String get cookingModeTimer => 'Timer';

  @override
  String get cookingModeComplete => 'Recipe complete!';

  @override
  String get cookingModeStart => 'Start Cooking';

  @override
  String get dietPlanTitle => 'Diet Plan';

  @override
  String get dietPlanNoPlan => 'No diet plan';

  @override
  String get dietPlanCalorieGoal => 'Calorie Goal';

  @override
  String get dietPlanProteinGoal => 'Protein Goal';

  @override
  String get dietPlanCarbGoal => 'Carb Goal';

  @override
  String get dietPlanFatGoal => 'Fat Goal';

  @override
  String get dietPlanWeeks => 'Duration (weeks)';

  @override
  String get dietPlanActivity => 'Activity Level';

  @override
  String get shoppingListTitle => 'Shopping List';

  @override
  String get shoppingListEmpty => 'Your shopping list is empty';

  @override
  String shoppingListItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '$count item',
    );
    return '$_temp0';
  }

  @override
  String get shoppingListAll => 'All';

  @override
  String get shoppingListChecked => 'Checked';

  @override
  String get shoppingListRemaining => 'Remaining';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get accountTitle => 'My Account';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountDeleteAccount => 'Delete account';

  @override
  String get accountDeleteConfirmTitle => 'Delete account';

  @override
  String get accountDeleteConfirmContent =>
      'This action is irreversible. All your data will be deleted.';

  @override
  String get accountChangePassword => 'Change password';

  @override
  String get accountInfoSection => 'INFORMATION';

  @override
  String get accountPasswordSection => 'PASSWORD';

  @override
  String get accountCurrentPassword => 'Current password';

  @override
  String get accountNewPassword => 'New password';

  @override
  String get accountConfirmPassword => 'Confirm password';

  @override
  String get accountUpdatePassword => 'Update';

  @override
  String get accountDangerZone => 'DANGER ZONE';

  @override
  String get accountPasswordRequired => 'Please fill in all fields.';

  @override
  String get accountPasswordTooShort =>
      'Password must be at least 8 characters.';

  @override
  String get accountPasswordMismatch => 'Passwords don\'t match.';

  @override
  String get accountPasswordUpdated => 'Password updated successfully.';

  @override
  String get accountDeleteError => 'Error deleting account. Please try again.';

  @override
  String get accountErrorInvalidPassword => 'Incorrect current password.';

  @override
  String get accountErrorTooManyRequests => 'Too many attempts. Please wait.';

  @override
  String get accountErrorGeneric => 'An error occurred. Please try again.';

  @override
  String get healthProfileTitle => 'Health & Goals';

  @override
  String get healthProfileAge => 'Age';

  @override
  String get healthProfileWeight => 'Weight (kg)';

  @override
  String get healthProfileHeight => 'Height (cm)';

  @override
  String get healthProfileGender => 'Gender';

  @override
  String get healthProfileActivity => 'Activity Level';

  @override
  String get healthProfileGoal => 'Goal';

  @override
  String get healthProfileTargetWeight => 'Target Weight (kg)';

  @override
  String get healthProfileSave => 'Save';

  @override
  String get healthProfileSaved => 'Health profile saved';

  @override
  String get healthProfileError => 'Error saving';

  @override
  String get healthParamsSection => 'HEALTH PARAMETERS';

  @override
  String get healthSex => 'Sex';

  @override
  String get healthBirthDate => 'Date of birth';

  @override
  String get healthBirthDateEmpty => 'Not set';

  @override
  String get healthHeight => 'Height';

  @override
  String get healthCurrentWeight => 'Current weight';

  @override
  String get healthTargetWeight => 'Target weight';

  @override
  String get healthActivityLevel => 'Activity level';

  @override
  String get healthGoalSection => 'GOAL';

  @override
  String get healthGoalType => 'Goal type';

  @override
  String get healthWeightGoal => 'Weight goal';

  @override
  String get healthMuscleGoal => 'Muscle goal';

  @override
  String get healthTargetDuration => 'Target duration';

  @override
  String healthWeeks(int count) {
    return '$count weeks';
  }

  @override
  String healthWeeksShort(int count) {
    return '$count wks';
  }

  @override
  String get healthActivitySedentary => 'Sedentary';

  @override
  String get healthActivityLight => 'Lightly active';

  @override
  String get healthActivityModerate => 'Moderately active';

  @override
  String get healthActivityActive => 'Active';

  @override
  String get healthActivityVeryActive => 'Very active';

  @override
  String get healthGoalWeightLoss => 'Weight loss';

  @override
  String get healthGoalMuscleGain => 'Muscle gain';

  @override
  String get healthGoalMaintenance => 'Maintenance';

  @override
  String get healthGoalHealth => 'Health';

  @override
  String get healthGoalPerformance => 'Performance';

  @override
  String get healthGoalLose => 'Lose';

  @override
  String get healthGoalMaintain => 'Maintain';

  @override
  String get healthGoalGain => 'Gain';

  @override
  String get healthSexMale => 'Male';

  @override
  String get healthSexFemale => 'Female';

  @override
  String get healthSexOther => 'Other';

  @override
  String get notifSettingsIntro =>
      'Configure your preferences to stay connected without feeling overwhelmed.';

  @override
  String get notifPushLabel => 'Push Notifications';

  @override
  String get notifPushSubtitle => 'Receive notifications on your device';

  @override
  String get notifChatLabel => 'Chat';

  @override
  String get notifChatSubtitle => 'Messages and conversations';

  @override
  String get notifMealLabel => 'Meal reminders';

  @override
  String get notifMealSubtitle => 'Scheduled meal times';

  @override
  String get notifDmLabel => 'Conversation requests';

  @override
  String get notifDmSubtitle => 'New connection requests';

  @override
  String get notifLoadError => 'Unable to load preferences.';

  @override
  String get preferencesTitle => 'Preferences';

  @override
  String get preferencesDiet => 'Diet';

  @override
  String get preferencesAllergens => 'Allergens & Intolerances';

  @override
  String get preferencesFavoriteRegions => 'Favorite Regions';

  @override
  String get preferencesSave => 'Save';

  @override
  String get preferencesSaved => 'Preferences saved';

  @override
  String get preferencesError => 'Error saving preferences';

  @override
  String get preferencesMealPlanSection => 'MEAL PLAN';

  @override
  String get preferencesMealPlanFromFavorites => 'Generate from favorites';

  @override
  String get preferencesMealPlanFromFavoritesDesc =>
      'Only use your saved recipes';

  @override
  String get preferencesCookingSection => 'COOKING';

  @override
  String get preferencesCookingTimeLabel => 'Preparation time';

  @override
  String get preferencesCookingTimeQuick => 'Quick (< 30 min)';

  @override
  String get preferencesCookingTimeMedium => 'Medium (30–60 min)';

  @override
  String get preferencesCookingTimeAny => 'No preference';

  @override
  String get preferencesBatchCookingLabel => 'Batch cooking';

  @override
  String get preferencesBatchCookingDesc => 'Prepare several meals at once';

  @override
  String get preferencesBatchCookingDetail => 'Cook in bulk for the week';

  @override
  String get preferencesBatchPortions => 'Max portions per session';

  @override
  String get preferencesCuisineSection => 'CUISINE REGION';

  @override
  String get preferencesRegionWestAfrica => 'West Africa';

  @override
  String get preferencesRegionEastAfrica => 'East Africa';

  @override
  String get preferencesRegionNorthAfrica => 'North Africa';

  @override
  String get preferencesRegionCentralAfrica => 'Central Africa';

  @override
  String get preferencesRegionSouthAfrica => 'South Africa';

  @override
  String get preferencesRegionCaribbean => 'Caribbean';

  @override
  String get preferencesRegionWestern => 'Western';

  @override
  String get preferencesDietSection => 'DIETARY RESTRICTIONS';

  @override
  String get preferencesNoPork => 'No pork';

  @override
  String get preferencesNoMeat => 'No meat';

  @override
  String get preferencesNoGluten => 'No gluten';

  @override
  String get preferencesNoLactose => 'No lactose';

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsMealReminders => 'Meal Reminders';

  @override
  String get notificationSettingsNewRecipes => 'New Recipes';

  @override
  String get notificationSettingsCommunity => 'Community';

  @override
  String get notificationSettingsSave => 'Save';

  @override
  String get savedRecipesTitle => 'Saved Recipes';

  @override
  String get savedRecipesEmpty => 'No saved recipes yet';

  @override
  String get savedRecipesEmptySubtitle => 'Save recipes to find them easily';

  @override
  String get fanModeTitle => 'Fan Mode';

  @override
  String get fanModeSubscribe => 'Subscribe';

  @override
  String get fanModeUnsubscribe => 'Unsubscribe';

  @override
  String get fanModeMyCreators => 'My Creators';

  @override
  String get fanModeNoCreators => 'No creators followed yet';

  @override
  String get subscriptionTitle => 'Go Premium';

  @override
  String get subscriptionSubtitle => 'Unlock all features';

  @override
  String get subscriptionMonthly => 'Monthly';

  @override
  String get subscriptionAnnual => 'Annual';

  @override
  String get subscriptionSubscribe => 'Subscribe';

  @override
  String get referralTitle => 'Refer a Friend';

  @override
  String get referralCopyCode => 'Copy Code';

  @override
  String get referralCodeCopied => 'Code copied!';

  @override
  String get supportTitle => 'Help & FAQ';

  @override
  String get aiAssistantTitle => 'AI Assistant';

  @override
  String get aiAssistantPlaceholder => 'Ask me anything about nutrition...';

  @override
  String get aiAssistantSend => 'Send';

  @override
  String get batchCookingTitle => 'Batch Cooking';

  @override
  String get batchCookingEmpty => 'No batch cooking sessions';

  @override
  String get ratingTitle => 'Rate this meal';

  @override
  String get ratingSubmit => 'Submit';

  @override
  String get ratingSkip => 'Skip';

  @override
  String get journeyTitle => 'My Journey';

  @override
  String journeyStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count day streak',
      one: '$count day streak',
    );
    return '$_temp0';
  }

  @override
  String get journeyNoData => 'Start your journey today';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonError => 'Error';

  @override
  String get commonSuccess => 'Success';

  @override
  String get commonNext => 'Next';

  @override
  String get commonPrevious => 'Previous';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get difficultyEasy => 'Easy';

  @override
  String get difficultyMedium => 'Medium';

  @override
  String get difficultyHard => 'Hard';

  @override
  String get dietVegetarian => 'Vegetarian';

  @override
  String get dietVegan => 'Vegan';

  @override
  String get dietPescatarian => 'Pescatarian';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietKosher => 'Kosher';

  @override
  String get dietGlutenFree => 'Gluten Free';

  @override
  String get dietLactoseFree => 'Lactose Free';

  @override
  String get dietNutFree => 'Nut Free';

  @override
  String get languageSelectorTitle => 'Choose Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get onboardingWelcome => 'Welcome to Akeli';

  @override
  String get onboardingSubtitle => 'Let\'s personalize your experience';

  @override
  String get onboardingAge => 'What is your age?';

  @override
  String get onboardingEstimatedDeadline => 'ESTIMATED DEADLINE';

  @override
  String get onboardingBatchPrepMeals => 'Prepare several meals at once';

  @override
  String get onboardingBatchCookWeek => 'Cook in bulk for the week';

  @override
  String get onboardingPreferences => 'Your Preferences';

  @override
  String get onboardingPreferencesSubtitle =>
      'Let\'s personalize your culinary experience.';

  @override
  String get onboardingDietLabel => 'Dietary Preferences';

  @override
  String get onboardingAllergens => 'Allergies & Intolerances';

  @override
  String get onboardingAllergensHint => 'Add ingredients to avoid.';

  @override
  String get onboardingSummary => 'Summary';

  @override
  String get onboardingSummarySubtitle =>
      'Your profile is ready. Let\'s check the details before we begin.';

  @override
  String get onboardingDietaryPreferences => 'Dietary Preferences';

  @override
  String get feedSortBestRated => 'Best rated';

  @override
  String get feedSortPopular => 'Most popular';

  @override
  String get feedSortNewest => 'Newest';

  @override
  String get feedSortRelevance => 'Relevance';

  @override
  String get feedSortMostFans => 'Most fans';

  @override
  String get feedSortMostRecipes => 'Most recipes';

  @override
  String get feedSortCustom => 'Custom';

  @override
  String get unitKilograms => 'KILOGRAMS';

  @override
  String get unitPounds => 'POUNDS';

  @override
  String feedFilterTimeMax(int min) {
    return '< $min min';
  }

  @override
  String get onboardingSkip => 'Skip';

  @override
  String onboardingStep(int current, int total) {
    return 'Step $current of $total';
  }

  @override
  String get onboardingBack => 'Back';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingFinish => 'Get Started';

  @override
  String get onboardingProfileTitle => 'Your Profile';

  @override
  String get onboardingDisplayNameHint => 'How should we call you?';

  @override
  String get onboardingActivityTitle => 'Activity Level';

  @override
  String get mealDetailNotFound => 'Meal not found';

  @override
  String get mealDetailConsumed => 'Meal consumed';

  @override
  String get mealDetailMarkConsumed => 'Mark as consumed';

  @override
  String get mealDetailDescription => 'Description';

  @override
  String get mealDetailSwapRecipe => 'Change recipe';

  @override
  String get mealDetailPersonalMeal => 'Personal Meal (AI)';

  @override
  String get mealDetailConsumeFirst => 'Consume this meal first';

  @override
  String get mealDetailEditReview => 'Edit your review';

  @override
  String get mealDetailLeaveReview => 'Leave a review';

  @override
  String get mealDetailViewFullRecipe => 'View full recipe';

  @override
  String get mealDetailBatchPrep => 'Batch preparation';

  @override
  String get mealDetailBatchSession => 'Batch cooking session';

  @override
  String get recipeDetailTotalRecipe => 'Total recipe';

  @override
  String get recipeDetailPerServing => 'Per serving';

  @override
  String get recipeDetailReviews => 'Reviews';

  @override
  String get recipeDetailRatingTaste => 'Taste';

  @override
  String get recipeDetailRatingEase => 'Ease';

  @override
  String get recipeDetailRatingSatiety => 'Satiety';

  @override
  String get batchCookingThisWeek => 'This week';

  @override
  String get batchCookingOngoing => 'Your ongoing preparations';

  @override
  String get batchCookingNoSessionsTitle => 'No sessions this week';

  @override
  String get batchCookingNoSessionsBody =>
      'Your batch sessions will appear here automatically when a recipe is planned multiple times.';

  @override
  String get batchCookingDefaultRecipe => 'Recipe';

  @override
  String get batchDetailPreparation => 'Preparation';

  @override
  String get batchDetailPortionsUsed => 'Portions used';

  @override
  String batchDetailPortionsUsedCount(int count) {
    return '$count used';
  }

  @override
  String get batchDetailStartCooking => 'Start cooking';

  @override
  String get commonAdd => 'Add';

  @override
  String get mealPlannerAddSnack => 'Add a snack';

  @override
  String get mealPlannerAddAnotherSnack => 'Add another snack';

  @override
  String get snackPickerTitle => 'Choose a snack';

  @override
  String get snackPickerEstimatedQty => 'Estimated quantity';

  @override
  String get snackPickerPersonal => 'Personal snack';

  @override
  String get snackPickerNoResults => 'No recipe found';

  @override
  String get fanModeLoadError => 'Loading error';

  @override
  String get fanModeCreatorsTitle => 'Creators to support';

  @override
  String get fanModeCreatorsSubtitle => 'Your dominant creator is highlighted.';

  @override
  String get fanModeNoCreatorsTitle => 'No eligible creators';

  @override
  String get fanModeNoCreatorsSubtitle =>
      'Creators must publish 30 recipes to be eligible.';

  @override
  String get fanModeActivateTitle => 'Activate Fan Mode';

  @override
  String fanModeActivateContent(String name) {
    return 'You are about to support $name with €1/month, included in your Akeli subscription.\n\nRule 90/10: 90% of your meals must come from this creator\'s catalog (max 9 external recipes per month).\n\nActive from the 1st of next month.';
  }

  @override
  String get fanModeConfirm => 'Confirm';

  @override
  String get fanModeActivateError => 'Error during activation.';

  @override
  String fanModeActivateSuccess(String name) {
    return 'You are now supporting $name!';
  }

  @override
  String get fanModeRecipesThisMonth => 'Your recipes this month';

  @override
  String get fanModeNoRecipesThisMonth => 'No recipes recorded this month';

  @override
  String fanModeTotalMeals(int count) {
    return '$count meals recorded';
  }

  @override
  String fanModeRecipeCount(int count) {
    return '$count recipes';
  }

  @override
  String fanModeFanCount(int count) {
    return '$count fans';
  }

  @override
  String get fanModeSupport => 'Support';

  @override
  String get fanModeQuit => 'Leave Fan Mode';

  @override
  String get fanModeQuitContent =>
      'Your support will end at the end of the current month.';

  @override
  String get fanModeKeep => 'Keep';

  @override
  String get fanModeQuitConfirm => 'Leave';

  @override
  String get fanModeCancelled => 'Fan Mode cancelled.';

  @override
  String get fanModeStatusPending => '⏳ Active from the 1st of next month';

  @override
  String get fanModeStatusActive => '❤️ Fan Mode active';

  @override
  String get fanModeExternalTitle => 'External recipes this month';

  @override
  String get fanModeExternalSubtitle => 'Recipes outside catalog';

  @override
  String get fanModeEngagementTitle => 'Fan Mode Commitment';

  @override
  String get fanModeEngagementYouSupport => 'You support ';

  @override
  String get fanModeEngagementWith => ' with ';

  @override
  String get fanModeEngagementGuaranteed => '€1/month guaranteed';

  @override
  String get fanModeEngagementIncluded =>
      ', included in your subscription.\n\nFan Rule 90/10: 90% of your meals must come from this creator\'s catalog. You can use up to ';

  @override
  String get fanModeEngagementExternalCount => '9 external recipes';

  @override
  String get fanModeEngagementPerMonth => ' per month.';

  @override
  String get fanModeDefaultCreator => 'your creator';

  @override
  String get commonLoadError => 'Loading error';

  @override
  String get commonGenericError => 'An error occurred. Please try again.';

  @override
  String get groupDetailTitle => 'Group Details';

  @override
  String get groupDetailUnknownGroup => 'Unknown group';

  @override
  String get groupDetailTabMembers => 'Members';

  @override
  String get groupDetailTabPhotos => 'Photos';

  @override
  String get groupDetailTabRecipes => 'Recipes';

  @override
  String get groupDetailDmAlreadySent => 'Request already sent';

  @override
  String groupDetailDmSentTo(String name) {
    return 'Request sent to $name';
  }

  @override
  String groupDetailExcludeTitle(String name) {
    return 'Exclude $name?';
  }

  @override
  String get groupDetailExcludeContent =>
      'This person will lose access to the group and group chat.';

  @override
  String get groupDetailExclude => 'Exclude';

  @override
  String get groupDetailMemberExcluded => 'Member excluded from group';

  @override
  String get groupDetailNotAdmin =>
      'You are no longer an administrator of this group';

  @override
  String get groupDetailInvite => 'Invite';

  @override
  String get groupDetailNoMembersTitle => 'No members';

  @override
  String get groupDetailNoMembersSubtitle => 'Members will appear here.';

  @override
  String get groupDetailNoPhotosTitle => 'No shared photos';

  @override
  String get groupDetailNoPhotosSubtitle =>
      'Photos sent in the chat will appear here.';

  @override
  String get groupDetailNoRecipesTitle => 'No shared recipes';

  @override
  String get groupDetailNoRecipesSubtitle =>
      'Recipes shared in the chat will appear here.';

  @override
  String get groupDetailInvitesSent => 'Invitations sent';

  @override
  String get groupDetailInviteTitle => 'Invite members';

  @override
  String get groupDetailNoEligibleTitle => 'No eligible contacts';

  @override
  String get groupDetailNoEligibleSubtitle =>
      'You don\'t have any private conversations with users to invite yet.';

  @override
  String groupDetailInviteCount(int count) {
    return 'Invite ($count)';
  }

  @override
  String get groupDetailPrivateMessage => 'Private message';

  @override
  String get groupDetailExcludeFromGroup => 'Exclude from group';

  @override
  String get allergenPickerHint => 'e.g. peanuts, nuts...';

  @override
  String allergenPickerAdd(String query) {
    return 'Add \"$query\"';
  }

  @override
  String get allergenPickerSuggestionSent => 'Suggestion sent for review.';

  @override
  String get ingredientDetailOptional => 'Optional';

  @override
  String get ingredientDetailTagHighProtein => 'High protein';

  @override
  String get ingredientDetailTagLowFat => 'Low fat';

  @override
  String get ingredientDetailTagGlutenFree => 'Gluten free';

  @override
  String get ingredientDetailTagAfricanStaple => 'African staple';

  @override
  String get ingredientDetailTagHardToFindEu => 'Hard to find in Europe';

  @override
  String get ingredientDetailNutritionTitle => 'Nutrition (per 100g)';

  @override
  String get ingredientDetailEnergy => 'Energy';

  @override
  String get cookingSessionTitle => 'Cooking Session';

  @override
  String get cookingSessionSubtitle => 'Organize your meals for the week';

  @override
  String get cookingSessionComingSoon => 'Coming soon';

  @override
  String get cookingSessionComingSoonDesc =>
      'This feature will be available in a future update';

  @override
  String get cookingSessionGotIt => 'Got it';

  @override
  String get journeyCalendarLegendAll => 'All';

  @override
  String get journeyCalendarLegendPartial => 'Partial';

  @override
  String get journeyCalendarLegendNone => 'None';

  @override
  String get journeySummaryDays => 'Journey days';

  @override
  String get journeySummaryTracked => 'Days tracked';

  @override
  String get journeySummaryMeals => 'Meals consumed';

  @override
  String get journeySummaryConsistency => 'Consistency';

  @override
  String get journeyGoalsWeight => '⚖️  Weight';

  @override
  String get journeyGoalsCalories => '🎯  Calories';

  @override
  String get journeyGoalsProtein => '💪  Protein';

  @override
  String get journeyGoalsCarbs => '🌾  Carbs';

  @override
  String get journeyGoalsFat => '🥑  Fat';

  @override
  String journeyGoalsCalorieHitSubtitle(int pct) {
    return 'You hit your calorie goal $pct% of tracked days.';
  }

  @override
  String get subscriptionMyTitle => 'My Subscription';

  @override
  String get subscriptionActiveTitle => 'Active Subscription';

  @override
  String get subscriptionPremiumBadge => 'Akeli Premium';

  @override
  String get subscriptionActiveThankYou =>
      'Thank you for being part of the Akeli community.';

  @override
  String get subscriptionTagline => 'Personalized African nutrition';

  @override
  String get subscriptionIncludedTitle => 'What\'s included';

  @override
  String get subscriptionPerMonth => '/ month';

  @override
  String get subscriptionCancelAnytime => 'Cancel anytime via the Store';

  @override
  String get subscriptionSubscribeViaStore => 'Subscribe via the Store';

  @override
  String get subscriptionMobileOnly =>
      'Subscription available on iOS and Android only.';

  @override
  String get subscriptionFeature1 => 'Personalized African recipes with AI';

  @override
  String get subscriptionFeature2 => 'Adapted weekly meal plan';

  @override
  String get subscriptionFeature3 => 'Detailed nutritional tracking';

  @override
  String get subscriptionFeature4 => 'Nutritional AI assistant';

  @override
  String get subscriptionFeature5 => 'Fan Mode — support your creators';

  @override
  String get subscriptionFeature6 => 'Community and discussion groups';

  @override
  String get subscriptionFeature7 => 'Automatic shopping list';

  @override
  String get subscriptionActiveBadge => 'Active Premium Subscription';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Next renewal: $date';
  }

  @override
  String get subscriptionPlatformIos => 'Subscription via App Store';

  @override
  String get subscriptionPlatformAndroid => 'Subscription via Google Play';

  @override
  String get journalingNewEntry => 'New entry';

  @override
  String get journalingNewEntrySubtitle => 'Note your culinary experience';

  @override
  String get journalingPhotos => 'Photos';

  @override
  String get journalingAddPhotos => 'Add photos';

  @override
  String get journalingMealType => 'Meal type';

  @override
  String get journalingDescription => 'Description';

  @override
  String get journalingDescriptionHint =>
      'How was this meal? Tastes, textures, emotions...';

  @override
  String get journalingDescriptionRequired => 'Please add a description';

  @override
  String get journalingSaving => 'Saving...';

  @override
  String get journalingSaveEntry => 'Save entry';

  @override
  String get journalingEntrySaved => 'Entry saved successfully!';

  @override
  String get journalingSaveError => 'Error saving entry';

  @override
  String get aiAssistantOnline => 'Online';

  @override
  String get aiAssistantNewConversation => 'New conversation';

  @override
  String get aiAssistantToday => 'TODAY';

  @override
  String get aiAssistantError =>
      'Sorry, an error occurred. Please try again in a moment.';

  @override
  String get aiAssistantWelcomeTitle =>
      'Hello, I\'m your Akeli nutritional assistant.';

  @override
  String get aiAssistantWelcomeSubtitle =>
      'Ask me your questions about nutrition, African recipes or your meal plan.';

  @override
  String get aiAssistantSuggestions => 'Suggestions';

  @override
  String get aiAssistantMessageHint => 'Message...';

  @override
  String get aiAssistantSuggestion1 =>
      'Which protein-rich foods suit my culture?';

  @override
  String get aiAssistantSuggestion2 => 'What is my recommended caloric intake?';

  @override
  String get aiAssistantSuggestion3 =>
      'How to lose weight with African cuisine?';

  @override
  String get aiAssistantSuggestion4 => 'Give me a recipe for tonight.';

  @override
  String get referralCodeLabel => 'Your referral code';

  @override
  String referralReferreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count referrals',
      one: '$count referral',
    );
    return '$_temp0';
  }

  @override
  String get referralShareTitle => 'Share the Oasis';

  @override
  String get referralShareBody =>
      'Invite your friends to discover Akeli Oasis. For every friend who signs up with your code, you\'ll receive an exclusive wellness ritual invitation, and they\'ll get a privileged welcome.';

  @override
  String get referralChangeCodeTitle => 'Change code';

  @override
  String get referralEditCode => 'Edit code';

  @override
  String get referralNewCodeLabel => 'New code';

  @override
  String get referralNewCodeHint => 'Enter a new code';

  @override
  String get referralCodeUpdated => 'Code updated successfully!';

  @override
  String get supportHeaderTitle => 'How can we help you?';

  @override
  String get supportHeaderSubtitle =>
      'Our team is here to answer your questions';

  @override
  String get supportSubjectLabel => 'Subject';

  @override
  String get supportSubjectHint => 'e.g. Login issue...';

  @override
  String get supportSubjectRequired => 'Please enter a subject';

  @override
  String get supportEmailHint => 'your@email.com';

  @override
  String get supportEmailRequired => 'Please enter your email';

  @override
  String get supportEmailInvalid => 'Please enter a valid email';

  @override
  String get supportMessageLabel => 'Message';

  @override
  String get supportMessageHint => 'Describe your issue...';

  @override
  String get supportMessageRequired => 'Please enter your message';

  @override
  String get supportMessageTooShort => 'Message must be at least 10 characters';

  @override
  String get supportAddScreenshot => 'Add a screenshot';

  @override
  String get supportSendMessage => 'Send message';

  @override
  String get supportMessageSent => 'Message sent successfully!';

  @override
  String get supportSendError => 'Error sending. Please try again.';

  @override
  String get supportChangeScreenshot => 'Change screenshot';

  @override
  String get savedRecipesEligibilityNotLoggedIn => 'Not logged in';

  @override
  String get savedRecipesEligibilityNoData => 'No data found';

  @override
  String get savedRecipesEligibilityTitle => 'Generate from your favorites';

  @override
  String get savedRecipesEligibilityDesc =>
      'If you have enough saved recipes, you can ask Akeli to generate your meal plans only from your favorites, rather than through our recommendations.';

  @override
  String get savedRecipesEligibilityProgress => 'Progress';

  @override
  String savedRecipesEligibilityMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recipes missing',
      one: '$count recipe missing',
    );
    return '$_temp0';
  }

  @override
  String get savedRecipesEligibilityToggleTitle => 'Use favorites only';

  @override
  String get savedRecipesEligibilityEnabled => 'Enabled';

  @override
  String get savedRecipesEligibilityBlocked =>
      'Locked: You must reach 7 recipes for each category above.';

  @override
  String get legalPrivacyTitle => 'Privacy Policy';

  @override
  String get legalPrivacyHeroTitle => 'Your data is protected';

  @override
  String get legalPrivacyHeroSubtitle =>
      'We are committed to protecting your privacy in accordance with GDPR';

  @override
  String get legalPrivacySummaryTitle => 'In brief';

  @override
  String get legalPrivacyCollectionTitle => 'Minimal collection';

  @override
  String get legalPrivacyCollectionDesc =>
      'Only data necessary for the app to function';

  @override
  String get legalPrivacySecurityTitle => 'Maximum security';

  @override
  String get legalPrivacySecurityDesc =>
      'End-to-end encryption and secure storage';

  @override
  String get legalPrivacyControlTitle => 'Total control';

  @override
  String get legalPrivacyControlDesc =>
      'You can access, modify or delete your data at any time';

  @override
  String get legalPrivacySection1Title => '1. Data collection';

  @override
  String get legalPrivacySection1Content =>
      'We collect only the data needed to provide you with the best experience:\n\n• Profile information (name, email, dietary preferences)\n• Navigation history within the app\n• Health data you choose to share\n• Content preferences and interactions';

  @override
  String get legalPrivacySection2Title => '2. Data use';

  @override
  String get legalPrivacySection2Content =>
      'Your data allows us to:\n\n• Personalize your recipe recommendations\n• Continuously improve our service\n• Send you relevant notifications\n• Ensure the security of your account';

  @override
  String get legalPrivacySection3Title => '3. Your GDPR rights';

  @override
  String get legalPrivacyRightAccess => 'Access';

  @override
  String get legalPrivacyRightAccessDesc => 'View your data';

  @override
  String get legalPrivacyRightRectification => 'Rectification';

  @override
  String get legalPrivacyRightRectificationDesc => 'Modify your information';

  @override
  String get legalPrivacyRightErasure => 'Erasure';

  @override
  String get legalPrivacyRightErasureDesc => 'Delete your account';

  @override
  String get legalPrivacyRightPortability => 'Portability';

  @override
  String get legalPrivacyRightPortabilityDesc => 'Export your data';

  @override
  String get legalPrivacySection4Title => '4. Data sharing';

  @override
  String get legalPrivacySection4Content =>
      'We never sell your personal data.\n\nIt may only be shared with:\n• Our technical providers hosted in the EU\n• Legal authorities if required by law\n• Your favourite creators (only with your explicit consent)';

  @override
  String get legalPrivacySection5Title => '5. Retention';

  @override
  String get legalPrivacySection5Content =>
      'Your data is retained:\n• As long as your account is active\n• Up to 3 years after your last login\n• Immediately deleted upon account deletion request';

  @override
  String get legalPrivacyDpoTitle => 'DPO Contact';

  @override
  String get legalPrivacyDpoEmail => 'dpo@akeli.app';

  @override
  String get legalPrivacyDpoDesc =>
      'Our data protection officer responds within 48 business hours to any request regarding your personal data.';

  @override
  String get legalPrivacyVersion => 'Version 1.0 • Last updated: January 2026';

  @override
  String get legalTermsTitle => 'Terms of Service';

  @override
  String get legalTermsHeroTitle => 'Welcome to Akeli';

  @override
  String get legalTermsHeroSubtitle =>
      'By using our app, you accept these terms';

  @override
  String get legalTermsArticle1Title => 'Access to service';

  @override
  String get legalTermsArticle1Content =>
      'Akeli is a free mobile app dedicated to African nutrition and traditional recipes.\n\nAccess to the service requires:\n• A compatible iOS or Android smartphone\n• An internet connection to sync data\n• Creating a user account\n\nCertain premium features (Fan Mode, personalized plans) are available via subscription.';

  @override
  String get legalTermsArticle2Title => 'User account';

  @override
  String get legalTermsArticle2Content =>
      'You are responsible for:\n• The confidentiality of your credentials\n• The accuracy of the information provided\n• All activities carried out from your account\n\nWe reserve the right to suspend or delete any account that violates these terms.';

  @override
  String get legalTermsArticle3Title => 'Intellectual property';

  @override
  String get legalTermsArticle3Content =>
      'All content on Akeli (recipes, texts, images, logos) is the exclusive property of Akeli or its partners.\n\nProhibited:\n• Reproduction without authorization\n• Unauthorized commercial use\n• Modification or alteration of content\n\nCreators retain rights to their published recipes.';

  @override
  String get legalTermsArticle4Title => 'Liability';

  @override
  String get legalTermsArticle4Content =>
      'Akeli provides nutritional information for informational purposes only.\n\nWe cannot be held responsible for:\n• Errors in nutritional information\n• Allergic reactions or health problems related to recipes\n• Temporary service interruptions for maintenance\n\nAlways consult a healthcare professional for medical advice.';

  @override
  String get legalTermsArticle5Title => 'Subscriptions and payments';

  @override
  String get legalTermsArticle5Content =>
      'Fan Mode subscriptions (€3/month) are billed monthly via the stores (Google Play / App Store).\n\n• Cancellation possible at any time\n• Access maintained until the end of the paid period\n• No partial refund\n\nCreators receive 70% of revenue generated by their subscribers.';

  @override
  String get legalTermsArticle6Title => 'Modifications';

  @override
  String get legalTermsArticle6Content =>
      'We reserve the right to modify these terms at any time.\n\nUsers will be notified:\n• By push notification for major changes\n• By email if the modification impacts personal data\n\nContinued use constitutes acceptance of the new terms.';

  @override
  String get legalTermsContactTitle => 'Contact';

  @override
  String get legalTermsContactEmail => 'legal@akeli.app';

  @override
  String get legalTermsVersion => 'Version 1.0 • Last updated: January 2026';

  @override
  String get mealScheduleTitle => 'Meal Schedule';

  @override
  String get mealScheduleSubtitle => 'Define which meals you want each day';

  @override
  String get mealScheduleAddSlot => 'Add a meal slot';

  @override
  String get mealScheduleSave => 'Save schedule';

  @override
  String mealScheduleCalorieTotal(String total) {
    return '$total% of daily calories';
  }

  @override
  String get mealScheduleCalorieTotalError => 'Total must equal 100%';

  @override
  String get mealScheduleMacroSection => 'Macro targets for this slot';

  @override
  String get mealScheduleMacroError => 'Macros must equal 100%';

  @override
  String get mealScheduleNicknamePlaceholder => 'Custom label (optional)';

  @override
  String get mealScheduleCategoryLabel => 'Meal type';

  @override
  String get mealScheduleApplyDialogTitle => 'When to apply?';

  @override
  String get mealScheduleApplyFromToday => 'Apply from today';

  @override
  String get mealScheduleApplyFromNextWeek => 'Apply from next week';

  @override
  String get mealScheduleHintBanner =>
      'Customize your meal schedule anytime — tap the settings icon above';

  @override
  String get mealScheduleHintDismiss => 'Got it';

  @override
  String get mealScheduleOnboardingTitle => 'Customize your meal schedule';

  @override
  String get mealScheduleOnboardingSubtitle =>
      'Choose which meals you want each day. You can change this anytime in Settings.';

  @override
  String get mealScheduleOnboardingSkip => 'Skip, use default (3 meals)';

  @override
  String get mealScheduleCustomizeButton => 'Customize meal structure';

  @override
  String get mealScheduleDeleteSlotTooltip => 'Remove this slot';

  @override
  String get mealScheduleCaloriePct => 'Calorie share';

  @override
  String get mealScheduleProteinPct => 'Protein %';

  @override
  String get mealScheduleCarbsPct => 'Carbs %';

  @override
  String get mealScheduleFatPct => 'Fat %';

  @override
  String get mealScheduleSavedSuccess => 'Schedule saved';

  @override
  String get mealScheduleVarietyTitle => 'Recipe variety';

  @override
  String get mealScheduleVarietySubtitle =>
      'Avoid repeating recipes used recently';

  @override
  String get mealScheduleVarietyNone => 'None';

  @override
  String get mealScheduleVariety7Days => '7 days';

  @override
  String get mealScheduleVariety15Days => '15 days';

  @override
  String get nutritionPlanSaveButton => 'Save plan';

  @override
  String get nutritionToday => 'Today';

  @override
  String get nutritionYesterday => 'Yesterday';

  @override
  String get nutritionChartTarget => 'Target';

  @override
  String get nutritionEmptyStateTodayTitle => 'No Data';

  @override
  String get nutritionEmptyStateTodaySubtitle => 'No food logged for this day.';

  @override
  String get nutritionEmptyStateWeekTitle => 'No Data Yet';

  @override
  String get nutritionEmptyStateWeekSubtitle => 'No food logged for this week.';

  @override
  String get nutritionWeightEvolution => 'Weight Trend';

  @override
  String get journeyBestStreakRecord => 'Record';

  @override
  String get preferencesLocaleUsImperial => 'English (US)';

  @override
  String get dietPlanSummaryTitle => 'Summary';

  @override
  String get dietPlanSummarySubtitle => 'Your diet plan';

  @override
  String dietPlanError(String error) {
    return 'Error: $error';
  }

  @override
  String get dietPlanWeightEvolution => 'WEIGHT PROGRESS';

  @override
  String get dietPlanPerWeek => '/ week';

  @override
  String get dietPlanWeightStartLabel => 'Start';

  @override
  String get dietPlanWeightTargetLabel => 'Target';

  @override
  String get dietPlanCurrentWeightLabel => 'current';

  @override
  String get dietPlanKcalPerDay => 'kcal/day';

  @override
  String get dietPlanRestrictionsTitle => 'RESTRICTIONS';

  @override
  String get dietPlanMealFallback => 'Meal';

  @override
  String get dietPlanRegenerate => 'Regenerate';

  @override
  String get dietPlanShoppingList => 'Shopping list';
}
