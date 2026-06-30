import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Akeli'**
  String get appTitle;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'Akeli V1.0'**
  String get appVersion;

  /// No description provided for @notificationSeeLabel.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get notificationSeeLabel;

  /// No description provided for @notificationDefaultTitle.
  ///
  /// In en, this message translates to:
  /// **'New Notification'**
  String get notificationDefaultTitle;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals'**
  String get navMeals;

  /// No description provided for @navRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get navRecipes;

  /// No description provided for @navCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get navCommunity;

  /// No description provided for @tooltipSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tooltipSettings;

  /// No description provided for @tooltipNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tooltipNotifications;

  /// No description provided for @authWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Akeli'**
  String get authWelcome;

  /// No description provided for @authSignUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get authSignUp;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogIn;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get authCreateAccount;

  /// No description provided for @authJoinCommunity.
  ///
  /// In en, this message translates to:
  /// **'Join the Akeli community'**
  String get authJoinCommunity;

  /// No description provided for @authEmailPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get authEmailPlaceholder;

  /// No description provided for @authEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email required'**
  String get authEmailRequired;

  /// No description provided for @authEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get authEmailInvalid;

  /// No description provided for @authPasswordCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a password'**
  String get authPasswordCreate;

  /// No description provided for @authPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password required'**
  String get authPasswordRequired;

  /// No description provided for @authPasswordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Minimum 8 characters'**
  String get authPasswordMinLength;

  /// No description provided for @authConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm your password'**
  String get authConfirmPassword;

  /// No description provided for @authPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get authPasswordMismatch;

  /// No description provided for @authGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get authGetStarted;

  /// No description provided for @authWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back!'**
  String get authWelcomeBack;

  /// No description provided for @authSignInToAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get authSignInToAccount;

  /// No description provided for @authEmailField.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authEmailField;

  /// No description provided for @authPasswordField.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authPasswordField;

  /// No description provided for @authPasswordReset.
  ///
  /// In en, this message translates to:
  /// **'Password reset — coming soon'**
  String get authPasswordReset;

  /// No description provided for @authForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get authForgotPassword;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get authSignIn;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already in use.'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorPasswordShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get authErrorPasswordShort;

  /// No description provided for @authErrorEmailNotConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your email address before signing in.'**
  String get authErrorEmailNotConfirmed;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}!'**
  String homeGreeting(String name);

  /// No description provided for @homeGreetingFallback.
  ///
  /// In en, this message translates to:
  /// **'Hello!'**
  String get homeGreetingFallback;

  /// No description provided for @homeWelcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Happy to see you again.'**
  String get homeWelcomeBack;

  /// No description provided for @homeWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get homeWeightLabel;

  /// No description provided for @homeWeightCurrent.
  ///
  /// In en, this message translates to:
  /// **'Current Weight'**
  String get homeWeightCurrent;

  /// No description provided for @homeCaloriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get homeCaloriesLabel;

  /// No description provided for @homeViewProgress.
  ///
  /// In en, this message translates to:
  /// **'View my progress →'**
  String get homeViewProgress;

  /// No description provided for @homeTodayMeals.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Meals'**
  String get homeTodayMeals;

  /// No description provided for @homeNoMealsToday.
  ///
  /// In en, this message translates to:
  /// **'No meals planned for today.'**
  String get homeNoMealsToday;

  /// No description provided for @homeMealDefault.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get homeMealDefault;

  /// No description provided for @homeMealUpdateError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update meal. Try again.'**
  String get homeMealUpdateError;

  /// No description provided for @homeShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get homeShoppingList;

  /// No description provided for @homeViewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get homeViewAll;

  /// No description provided for @homeFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get homeFilterAll;

  /// No description provided for @homeFilterToBuy.
  ///
  /// In en, this message translates to:
  /// **'To Buy'**
  String get homeFilterToBuy;

  /// No description provided for @homeFilterBought.
  ///
  /// In en, this message translates to:
  /// **'Already Bought'**
  String get homeFilterBought;

  /// No description provided for @homeNoItemsFound.
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get homeNoItemsFound;

  /// No description provided for @homeRecommendedRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recommended Recipes'**
  String get homeRecommendedRecipes;

  /// No description provided for @homeNoRecipes.
  ///
  /// In en, this message translates to:
  /// **'No recipes available.'**
  String get homeNoRecipes;

  /// No description provided for @homeErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String homeErrorGeneric(String error);

  /// No description provided for @homeCreatorsForYou.
  ///
  /// In en, this message translates to:
  /// **'Creators for You'**
  String get homeCreatorsForYou;

  /// No description provided for @homeCreateRecipe.
  ///
  /// In en, this message translates to:
  /// **'Create and share your own recipe'**
  String get homeCreateRecipe;

  /// No description provided for @feedTitle.
  ///
  /// In en, this message translates to:
  /// **'Discover'**
  String get feedTitle;

  /// No description provided for @feedSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search recipes...'**
  String get feedSearchHint;

  /// No description provided for @feedTabRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get feedTabRecipes;

  /// No description provided for @feedTabCreators.
  ///
  /// In en, this message translates to:
  /// **'Creators'**
  String get feedTabCreators;

  /// No description provided for @feedNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results found'**
  String get feedNoResults;

  /// No description provided for @feedNoResultsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Try different search terms or filters'**
  String get feedNoResultsSubtitle;

  /// No description provided for @feedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recipes yet'**
  String get feedEmptyTitle;

  /// No description provided for @feedFilters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get feedFilters;

  /// No description provided for @feedFilterRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get feedFilterRegion;

  /// No description provided for @feedFilterDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get feedFilterDifficulty;

  /// No description provided for @feedFilterTime.
  ///
  /// In en, this message translates to:
  /// **'Max Time'**
  String get feedFilterTime;

  /// No description provided for @feedFilterMealType.
  ///
  /// In en, this message translates to:
  /// **'Meal Type'**
  String get feedFilterMealType;

  /// No description provided for @feedFilterCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get feedFilterCalories;

  /// No description provided for @feedSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get feedSortBy;

  /// No description provided for @feedAllRegions.
  ///
  /// In en, this message translates to:
  /// **'All regions'**
  String get feedAllRegions;

  /// No description provided for @feedAllDifficulties.
  ///
  /// In en, this message translates to:
  /// **'All difficulties'**
  String get feedAllDifficulties;

  /// No description provided for @feedAllMealTypes.
  ///
  /// In en, this message translates to:
  /// **'All types'**
  String get feedAllMealTypes;

  /// No description provided for @feedApplyFilters.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get feedApplyFilters;

  /// No description provided for @feedResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get feedResetFilters;

  /// No description provided for @feedLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get feedLoadMore;

  /// No description provided for @feedCreatorSearch.
  ///
  /// In en, this message translates to:
  /// **'Search creators...'**
  String get feedCreatorSearch;

  /// No description provided for @feedCreatorSpecialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get feedCreatorSpecialty;

  /// No description provided for @feedAllSpecialties.
  ///
  /// In en, this message translates to:
  /// **'All specialties'**
  String get feedAllSpecialties;

  /// No description provided for @feedNoCreators.
  ///
  /// In en, this message translates to:
  /// **'No creators found'**
  String get feedNoCreators;

  /// No description provided for @feedAddToMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to Meal Plan'**
  String get feedAddToMealPlan;

  /// No description provided for @feedAddedToMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Added to meal plan'**
  String get feedAddedToMealPlan;

  /// No description provided for @feedSwapRecipe.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get feedSwapRecipe;

  /// No description provided for @feedSwapDone.
  ///
  /// In en, this message translates to:
  /// **'Recipe swapped'**
  String get feedSwapDone;

  /// No description provided for @recipeDetailIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get recipeDetailIngredients;

  /// No description provided for @recipeDetailInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions'**
  String get recipeDetailInstructions;

  /// No description provided for @recipeDetailNutrition.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Info'**
  String get recipeDetailNutrition;

  /// No description provided for @recipeDetailPrepTime.
  ///
  /// In en, this message translates to:
  /// **'Prep Time'**
  String get recipeDetailPrepTime;

  /// No description provided for @recipeDetailCookTime.
  ///
  /// In en, this message translates to:
  /// **'Cook Time'**
  String get recipeDetailCookTime;

  /// No description provided for @recipeDetailServings.
  ///
  /// In en, this message translates to:
  /// **'Servings'**
  String get recipeDetailServings;

  /// No description provided for @recipeDetailDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get recipeDetailDifficulty;

  /// No description provided for @recipeDetailCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get recipeDetailCalories;

  /// No description provided for @recipeDetailProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get recipeDetailProtein;

  /// No description provided for @recipeDetailCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get recipeDetailCarbs;

  /// No description provided for @recipeDetailFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get recipeDetailFat;

  /// No description provided for @recipeDetailSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get recipeDetailSave;

  /// No description provided for @recipeDetailSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get recipeDetailSaved;

  /// No description provided for @recipeDetailLike.
  ///
  /// In en, this message translates to:
  /// **'Like'**
  String get recipeDetailLike;

  /// No description provided for @recipeDetailShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get recipeDetailShare;

  /// No description provided for @recipeDetailComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get recipeDetailComments;

  /// No description provided for @recipeDetailNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments yet'**
  String get recipeDetailNoComments;

  /// No description provided for @recipeDetailAddComment.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get recipeDetailAddComment;

  /// No description provided for @recipeDetailSendComment.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get recipeDetailSendComment;

  /// No description provided for @recipeDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading recipe'**
  String get recipeDetailLoadError;

  /// No description provided for @recipeDetailMin.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get recipeDetailMin;

  /// No description provided for @recipeDetailPer100g.
  ///
  /// In en, this message translates to:
  /// **'per 100g'**
  String get recipeDetailPer100g;

  /// No description provided for @recipeDetailStepLabel.
  ///
  /// In en, this message translates to:
  /// **'Step {step}'**
  String recipeDetailStepLabel(int step);

  /// No description provided for @recipeDetailRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get recipeDetailRegion;

  /// No description provided for @recipeDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get recipeDetailTags;

  /// No description provided for @recipeDetailVideoTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe Video'**
  String get recipeDetailVideoTitle;

  /// No description provided for @recipeDetailAddToMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to Meal Plan'**
  String get recipeDetailAddToMealPlan;

  /// No description provided for @recipeDetailAddedToMealPlan.
  ///
  /// In en, this message translates to:
  /// **'Added to your meal plan'**
  String get recipeDetailAddedToMealPlan;

  /// No description provided for @recipeDetailErrorAddPlan.
  ///
  /// In en, this message translates to:
  /// **'Error adding to meal plan'**
  String get recipeDetailErrorAddPlan;

  /// No description provided for @recipeDetailBy.
  ///
  /// In en, this message translates to:
  /// **'by'**
  String get recipeDetailBy;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileDefaultName.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get profileDefaultName;

  /// No description provided for @profileLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String profileLoadError(String error);

  /// No description provided for @profilePrivateTitle.
  ///
  /// In en, this message translates to:
  /// **'This profile is private'**
  String get profilePrivateTitle;

  /// No description provided for @profilePrivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Send a message to connect.'**
  String get profilePrivateMessage;

  /// No description provided for @profileTabRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get profileTabRecipes;

  /// No description provided for @profileTabComments.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get profileTabComments;

  /// No description provided for @profileTabGroups.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get profileTabGroups;

  /// No description provided for @profileLoadError2.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get profileLoadError2;

  /// No description provided for @profileNoLikedRecipes.
  ///
  /// In en, this message translates to:
  /// **'No liked recipes'**
  String get profileNoLikedRecipes;

  /// No description provided for @profileNoComments.
  ///
  /// In en, this message translates to:
  /// **'No comments'**
  String get profileNoComments;

  /// No description provided for @profileNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups'**
  String get profileNoGroups;

  /// No description provided for @profileUnknownRecipe.
  ///
  /// In en, this message translates to:
  /// **'Unknown recipe'**
  String get profileUnknownRecipe;

  /// No description provided for @profileGroupDefault.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get profileGroupDefault;

  /// No description provided for @profileMemberCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} member} other{{count} members}}'**
  String profileMemberCount(int count);

  /// No description provided for @profileStartConversation.
  ///
  /// In en, this message translates to:
  /// **'Start a conversation'**
  String get profileStartConversation;

  /// No description provided for @profileMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get profileMessageSent;

  /// No description provided for @profileMessageError.
  ///
  /// In en, this message translates to:
  /// **'Error sending request'**
  String get profileMessageError;

  /// No description provided for @profilePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get profilePending;

  /// No description provided for @profileMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get profileMessage;

  /// No description provided for @profileCloseConversationTitle.
  ///
  /// In en, this message translates to:
  /// **'Close conversation?'**
  String get profileCloseConversationTitle;

  /// No description provided for @profileCloseConversationContent.
  ///
  /// In en, this message translates to:
  /// **'You will leave this conversation. The other user will keep their history.'**
  String get profileCloseConversationContent;

  /// No description provided for @profileConversationClosed.
  ///
  /// In en, this message translates to:
  /// **'Conversation closed'**
  String get profileConversationClosed;

  /// No description provided for @profileCloseError.
  ///
  /// In en, this message translates to:
  /// **'Error closing conversation'**
  String get profileCloseError;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get settingsEdit;

  /// No description provided for @settingsPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get settingsPremium;

  /// No description provided for @settingsSectionMenu.
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get settingsSectionMenu;

  /// No description provided for @settingsNutritionTracking.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Tracking'**
  String get settingsNutritionTracking;

  /// No description provided for @settingsSavedRecipes.
  ///
  /// In en, this message translates to:
  /// **'Saved Recipes'**
  String get settingsSavedRecipes;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get settingsAccount;

  /// No description provided for @settingsFanMode.
  ///
  /// In en, this message translates to:
  /// **'Fan Mode'**
  String get settingsFanMode;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsHealthGoals.
  ///
  /// In en, this message translates to:
  /// **'Health & Goals'**
  String get settingsHealthGoals;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'Application'**
  String get settingsSectionApp;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageCurrent.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageCurrent;

  /// No description provided for @settingsSectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsSectionPrivacy;

  /// No description provided for @settingsPrivateProfile.
  ///
  /// In en, this message translates to:
  /// **'Private Profile'**
  String get settingsPrivateProfile;

  /// No description provided for @settingsSectionSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get settingsSectionSupport;

  /// No description provided for @settingsHelpFaq.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get settingsHelpFaq;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsTerms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get settingsTerms;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOut;

  /// No description provided for @settingsSignOutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutTitle;

  /// No description provided for @settingsSignOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get settingsSignOutConfirm;

  /// No description provided for @settingsSignOutConfirmBtn.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get settingsSignOutConfirmBtn;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get settingsName;

  /// No description provided for @settingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get settingsDescription;

  /// No description provided for @settingsDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Tell us a bit about yourself...'**
  String get settingsDescriptionHint;

  /// No description provided for @settingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get settingsSave;

  /// No description provided for @settingsAvatarError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String settingsAvatarError(String error);

  /// No description provided for @mealPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Meals'**
  String get mealPlannerTitle;

  /// No description provided for @mealPlannerWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Your meals this week'**
  String get mealPlannerWeekTitle;

  /// No description provided for @mealPlannerDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Your upcoming meals'**
  String get mealPlannerDaysTitle;

  /// No description provided for @mealPlannerViewDietPlan.
  ///
  /// In en, this message translates to:
  /// **'View my diet plan'**
  String get mealPlannerViewDietPlan;

  /// No description provided for @mealPlannerViewShoppingList.
  ///
  /// In en, this message translates to:
  /// **'View my shopping list'**
  String get mealPlannerViewShoppingList;

  /// No description provided for @mealPlannerViewBatchCooking.
  ///
  /// In en, this message translates to:
  /// **'Batch cooking'**
  String get mealPlannerViewBatchCooking;

  /// No description provided for @mealPlannerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No meal plan yet'**
  String get mealPlannerEmpty;

  /// No description provided for @mealPlannerEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generate a personalized plan'**
  String get mealPlannerEmptySubtitle;

  /// No description provided for @mealPlannerGenerate.
  ///
  /// In en, this message translates to:
  /// **'Generate my plan'**
  String get mealPlannerGenerate;

  /// No description provided for @mealPlannerError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String mealPlannerError(String error);

  /// No description provided for @mealPlannerConsumptionError.
  ///
  /// In en, this message translates to:
  /// **'Unable to update. Try again.'**
  String get mealPlannerConsumptionError;

  /// No description provided for @mealTypeBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get mealTypeBreakfast;

  /// No description provided for @mealTypeLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get mealTypeLunch;

  /// No description provided for @mealTypeDinner.
  ///
  /// In en, this message translates to:
  /// **'Dinner'**
  String get mealTypeDinner;

  /// No description provided for @mealTypeSnack.
  ///
  /// In en, this message translates to:
  /// **'Snack'**
  String get mealTypeSnack;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionTitle;

  /// No description provided for @nutritionTabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nutritionTabToday;

  /// No description provided for @nutritionTabWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get nutritionTabWeek;

  /// No description provided for @nutritionTabJourney.
  ///
  /// In en, this message translates to:
  /// **'Journey'**
  String get nutritionTabJourney;

  /// No description provided for @nutritionCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get nutritionCalories;

  /// No description provided for @nutritionProtein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutritionProtein;

  /// No description provided for @nutritionCarbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutritionCarbs;

  /// No description provided for @nutritionFat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutritionFat;

  /// No description provided for @nutritionNoData.
  ///
  /// In en, this message translates to:
  /// **'No nutrition data today'**
  String get nutritionNoData;

  /// No description provided for @nutritionNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No nutrition plan'**
  String get nutritionNoPlan;

  /// No description provided for @nutritionGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get nutritionGoal;

  /// No description provided for @nutritionConsumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get nutritionConsumed;

  /// No description provided for @nutritionRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get nutritionRemaining;

  /// No description provided for @nutritionWeightTracking.
  ///
  /// In en, this message translates to:
  /// **'Weight Tracking'**
  String get nutritionWeightTracking;

  /// No description provided for @nutritionCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get nutritionCurrentWeight;

  /// No description provided for @nutritionTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get nutritionTargetWeight;

  /// No description provided for @nutritionAddWeight.
  ///
  /// In en, this message translates to:
  /// **'Log Weight'**
  String get nutritionAddWeight;

  /// No description provided for @nutritionWeightAdded.
  ///
  /// In en, this message translates to:
  /// **'Weight logged'**
  String get nutritionWeightAdded;

  /// No description provided for @nutritionHydration.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get nutritionHydration;

  /// No description provided for @nutritionMyWeight.
  ///
  /// In en, this message translates to:
  /// **'My Weight'**
  String get nutritionMyWeight;

  /// No description provided for @nutritionNewRecord.
  ///
  /// In en, this message translates to:
  /// **'New Log'**
  String get nutritionNewRecord;

  /// No description provided for @nutritionConsumedMeals.
  ///
  /// In en, this message translates to:
  /// **'Consumed meals'**
  String get nutritionConsumedMeals;

  /// No description provided for @nutritionTargetAchieved.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{You didn\'t reach your goals this week.} one{You reached your goals {count} time this week.} other{You reached your goals {count} times this week.}}'**
  String nutritionTargetAchieved(int count);

  /// No description provided for @nutritionSummary.
  ///
  /// In en, this message translates to:
  /// **'SUMMARY'**
  String get nutritionSummary;

  /// No description provided for @nutritionAvgKcal.
  ///
  /// In en, this message translates to:
  /// **'avg. kcal'**
  String get nutritionAvgKcal;

  /// No description provided for @nutritionWeightVariation.
  ///
  /// In en, this message translates to:
  /// **'weight change'**
  String get nutritionWeightVariation;

  /// No description provided for @nutritionEveryDay.
  ///
  /// In en, this message translates to:
  /// **'EVERY DAY'**
  String get nutritionEveryDay;

  /// No description provided for @nutritionWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get nutritionWeightLabel;

  /// No description provided for @nutritionProgressPercentage.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of goal'**
  String nutritionProgressPercentage(int pct);

  /// No description provided for @nutritionAddFirstWeight.
  ///
  /// In en, this message translates to:
  /// **'Add your first weight log to start tracking.'**
  String get nutritionAddFirstWeight;

  /// No description provided for @nutritionLogAnotherWeight.
  ///
  /// In en, this message translates to:
  /// **'Log another weight to see your trend.'**
  String get nutritionLogAnotherWeight;

  /// No description provided for @communityTitle.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get communityTitle;

  /// No description provided for @communityMyGroups.
  ///
  /// In en, this message translates to:
  /// **'My Groups'**
  String get communityMyGroups;

  /// No description provided for @communityPrivateGroups.
  ///
  /// In en, this message translates to:
  /// **'Private'**
  String get communityPrivateGroups;

  /// No description provided for @communityPublicGroups.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get communityPublicGroups;

  /// No description provided for @communityDiscoverGroups.
  ///
  /// In en, this message translates to:
  /// **'Discover Groups'**
  String get communityDiscoverGroups;

  /// No description provided for @communityNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get communityNoGroups;

  /// No description provided for @communityCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get communityCreateGroup;

  /// No description provided for @communityJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'Group joined successfully'**
  String get communityJoinSuccess;

  /// No description provided for @communityJoinError.
  ///
  /// In en, this message translates to:
  /// **'Error joining group'**
  String get communityJoinError;

  /// No description provided for @communityRegionFilter.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get communityRegionFilter;

  /// No description provided for @communityAllRegions.
  ///
  /// In en, this message translates to:
  /// **'All regions'**
  String get communityAllRegions;

  /// No description provided for @communityRegionError.
  ///
  /// In en, this message translates to:
  /// **'Region error'**
  String get communityRegionError;

  /// No description provided for @communityNoCriteria.
  ///
  /// In en, this message translates to:
  /// **'No groups match these criteria.'**
  String get communityNoCriteria;

  /// No description provided for @communityGroupImageError.
  ///
  /// In en, this message translates to:
  /// **'Error selecting image'**
  String get communityGroupImageError;

  /// No description provided for @communityGeneralChannel.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get communityGeneralChannel;

  /// No description provided for @communitySending.
  ///
  /// In en, this message translates to:
  /// **'Sending…'**
  String get communitySending;

  /// No description provided for @cookingModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking Mode'**
  String get cookingModeTitle;

  /// No description provided for @cookingModeStep.
  ///
  /// In en, this message translates to:
  /// **'Step {step} of {total}'**
  String cookingModeStep(int step, int total);

  /// No description provided for @cookingModeIngredients.
  ///
  /// In en, this message translates to:
  /// **'Ingredients'**
  String get cookingModeIngredients;

  /// No description provided for @cookingModeTimer.
  ///
  /// In en, this message translates to:
  /// **'Timer'**
  String get cookingModeTimer;

  /// No description provided for @cookingModeComplete.
  ///
  /// In en, this message translates to:
  /// **'Recipe complete!'**
  String get cookingModeComplete;

  /// No description provided for @cookingModeStart.
  ///
  /// In en, this message translates to:
  /// **'Start Cooking'**
  String get cookingModeStart;

  /// No description provided for @dietPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Diet Plan'**
  String get dietPlanTitle;

  /// No description provided for @dietPlanNoPlan.
  ///
  /// In en, this message translates to:
  /// **'No diet plan'**
  String get dietPlanNoPlan;

  /// No description provided for @dietPlanCalorieGoal.
  ///
  /// In en, this message translates to:
  /// **'Calorie Goal'**
  String get dietPlanCalorieGoal;

  /// No description provided for @dietPlanProteinGoal.
  ///
  /// In en, this message translates to:
  /// **'Protein Goal'**
  String get dietPlanProteinGoal;

  /// No description provided for @dietPlanCarbGoal.
  ///
  /// In en, this message translates to:
  /// **'Carb Goal'**
  String get dietPlanCarbGoal;

  /// No description provided for @dietPlanFatGoal.
  ///
  /// In en, this message translates to:
  /// **'Fat Goal'**
  String get dietPlanFatGoal;

  /// No description provided for @dietPlanWeeks.
  ///
  /// In en, this message translates to:
  /// **'Duration (weeks)'**
  String get dietPlanWeeks;

  /// No description provided for @dietPlanActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get dietPlanActivity;

  /// No description provided for @shoppingListTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping List'**
  String get shoppingListTitle;

  /// No description provided for @shoppingListEmpty.
  ///
  /// In en, this message translates to:
  /// **'Your shopping list is empty'**
  String get shoppingListEmpty;

  /// No description provided for @shoppingListItems.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} item} other{{count} items}}'**
  String shoppingListItems(int count);

  /// No description provided for @shoppingListAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get shoppingListAll;

  /// No description provided for @shoppingListChecked.
  ///
  /// In en, this message translates to:
  /// **'Checked'**
  String get shoppingListChecked;

  /// No description provided for @shoppingListRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get shoppingListRemaining;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notificationsEmpty;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'My Account'**
  String get accountTitle;

  /// No description provided for @accountEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get accountEmail;

  /// No description provided for @accountDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteAccount;

  /// No description provided for @accountDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get accountDeleteConfirmTitle;

  /// No description provided for @accountDeleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'This action is irreversible. All your data will be deleted.'**
  String get accountDeleteConfirmContent;

  /// No description provided for @accountChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get accountChangePassword;

  /// No description provided for @accountInfoSection.
  ///
  /// In en, this message translates to:
  /// **'INFORMATION'**
  String get accountInfoSection;

  /// No description provided for @accountPasswordSection.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get accountPasswordSection;

  /// No description provided for @accountCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get accountCurrentPassword;

  /// No description provided for @accountNewPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get accountNewPassword;

  /// No description provided for @accountConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get accountConfirmPassword;

  /// No description provided for @accountUpdatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get accountUpdatePassword;

  /// No description provided for @accountDangerZone.
  ///
  /// In en, this message translates to:
  /// **'DANGER ZONE'**
  String get accountDangerZone;

  /// No description provided for @accountPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields.'**
  String get accountPasswordRequired;

  /// No description provided for @accountPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get accountPasswordTooShort;

  /// No description provided for @accountPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get accountPasswordMismatch;

  /// No description provided for @accountPasswordUpdated.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully.'**
  String get accountPasswordUpdated;

  /// No description provided for @accountDeleteError.
  ///
  /// In en, this message translates to:
  /// **'Error deleting account. Please try again.'**
  String get accountDeleteError;

  /// No description provided for @accountErrorInvalidPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect current password.'**
  String get accountErrorInvalidPassword;

  /// No description provided for @accountErrorTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait.'**
  String get accountErrorTooManyRequests;

  /// No description provided for @accountErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get accountErrorGeneric;

  /// No description provided for @healthProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Health & Goals'**
  String get healthProfileTitle;

  /// No description provided for @healthProfileAge.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get healthProfileAge;

  /// No description provided for @healthProfileWeight.
  ///
  /// In en, this message translates to:
  /// **'Weight (kg)'**
  String get healthProfileWeight;

  /// No description provided for @healthProfileHeight.
  ///
  /// In en, this message translates to:
  /// **'Height (cm)'**
  String get healthProfileHeight;

  /// No description provided for @healthProfileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get healthProfileGender;

  /// No description provided for @healthProfileActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get healthProfileActivity;

  /// No description provided for @healthProfileGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get healthProfileGoal;

  /// No description provided for @healthProfileTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target Weight (kg)'**
  String get healthProfileTargetWeight;

  /// No description provided for @healthProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get healthProfileSave;

  /// No description provided for @healthProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Health profile saved'**
  String get healthProfileSaved;

  /// No description provided for @healthProfileError.
  ///
  /// In en, this message translates to:
  /// **'Error saving'**
  String get healthProfileError;

  /// No description provided for @healthParamsSection.
  ///
  /// In en, this message translates to:
  /// **'HEALTH PARAMETERS'**
  String get healthParamsSection;

  /// No description provided for @healthSex.
  ///
  /// In en, this message translates to:
  /// **'Sex'**
  String get healthSex;

  /// No description provided for @healthBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get healthBirthDate;

  /// No description provided for @healthBirthDateEmpty.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get healthBirthDateEmpty;

  /// No description provided for @healthHeight.
  ///
  /// In en, this message translates to:
  /// **'Height'**
  String get healthHeight;

  /// No description provided for @healthCurrentWeight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get healthCurrentWeight;

  /// No description provided for @healthTargetWeight.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get healthTargetWeight;

  /// No description provided for @healthActivityLevel.
  ///
  /// In en, this message translates to:
  /// **'Activity level'**
  String get healthActivityLevel;

  /// No description provided for @healthGoalSection.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get healthGoalSection;

  /// No description provided for @healthGoalType.
  ///
  /// In en, this message translates to:
  /// **'Goal type'**
  String get healthGoalType;

  /// No description provided for @healthWeightGoal.
  ///
  /// In en, this message translates to:
  /// **'Weight goal'**
  String get healthWeightGoal;

  /// No description provided for @healthMuscleGoal.
  ///
  /// In en, this message translates to:
  /// **'Muscle goal'**
  String get healthMuscleGoal;

  /// No description provided for @healthTargetDuration.
  ///
  /// In en, this message translates to:
  /// **'Target duration'**
  String get healthTargetDuration;

  /// No description provided for @healthWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count} weeks'**
  String healthWeeks(int count);

  /// No description provided for @healthWeeksShort.
  ///
  /// In en, this message translates to:
  /// **'{count} wks'**
  String healthWeeksShort(int count);

  /// No description provided for @healthActivitySedentary.
  ///
  /// In en, this message translates to:
  /// **'Sedentary'**
  String get healthActivitySedentary;

  /// No description provided for @healthActivityLight.
  ///
  /// In en, this message translates to:
  /// **'Lightly active'**
  String get healthActivityLight;

  /// No description provided for @healthActivityModerate.
  ///
  /// In en, this message translates to:
  /// **'Moderately active'**
  String get healthActivityModerate;

  /// No description provided for @healthActivityActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get healthActivityActive;

  /// No description provided for @healthActivityVeryActive.
  ///
  /// In en, this message translates to:
  /// **'Very active'**
  String get healthActivityVeryActive;

  /// No description provided for @healthGoalWeightLoss.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get healthGoalWeightLoss;

  /// No description provided for @healthGoalMuscleGain.
  ///
  /// In en, this message translates to:
  /// **'Muscle gain'**
  String get healthGoalMuscleGain;

  /// No description provided for @healthGoalMaintenance.
  ///
  /// In en, this message translates to:
  /// **'Maintenance'**
  String get healthGoalMaintenance;

  /// No description provided for @healthGoalHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get healthGoalHealth;

  /// No description provided for @healthGoalPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get healthGoalPerformance;

  /// No description provided for @healthGoalLose.
  ///
  /// In en, this message translates to:
  /// **'Lose'**
  String get healthGoalLose;

  /// No description provided for @healthGoalMaintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain'**
  String get healthGoalMaintain;

  /// No description provided for @healthGoalGain.
  ///
  /// In en, this message translates to:
  /// **'Gain'**
  String get healthGoalGain;

  /// No description provided for @healthSexMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get healthSexMale;

  /// No description provided for @healthSexFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get healthSexFemale;

  /// No description provided for @healthSexOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get healthSexOther;

  /// No description provided for @notifSettingsIntro.
  ///
  /// In en, this message translates to:
  /// **'Configure your preferences to stay connected without feeling overwhelmed.'**
  String get notifSettingsIntro;

  /// No description provided for @notifPushLabel.
  ///
  /// In en, this message translates to:
  /// **'Push Notifications'**
  String get notifPushLabel;

  /// No description provided for @notifPushSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notifications on your device'**
  String get notifPushSubtitle;

  /// No description provided for @notifChatLabel.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get notifChatLabel;

  /// No description provided for @notifChatSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Messages and conversations'**
  String get notifChatSubtitle;

  /// No description provided for @notifMealLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal reminders'**
  String get notifMealLabel;

  /// No description provided for @notifMealSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled meal times'**
  String get notifMealSubtitle;

  /// No description provided for @notifDmLabel.
  ///
  /// In en, this message translates to:
  /// **'Conversation requests'**
  String get notifDmLabel;

  /// No description provided for @notifDmSubtitle.
  ///
  /// In en, this message translates to:
  /// **'New connection requests'**
  String get notifDmSubtitle;

  /// No description provided for @notifLoadError.
  ///
  /// In en, this message translates to:
  /// **'Unable to load preferences.'**
  String get notifLoadError;

  /// No description provided for @preferencesTitle.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferencesTitle;

  /// No description provided for @preferencesDiet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get preferencesDiet;

  /// No description provided for @preferencesAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergens & Intolerances'**
  String get preferencesAllergens;

  /// No description provided for @preferencesFavoriteRegions.
  ///
  /// In en, this message translates to:
  /// **'Favorite Regions'**
  String get preferencesFavoriteRegions;

  /// No description provided for @preferencesSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get preferencesSave;

  /// No description provided for @preferencesSaved.
  ///
  /// In en, this message translates to:
  /// **'Preferences saved'**
  String get preferencesSaved;

  /// No description provided for @preferencesError.
  ///
  /// In en, this message translates to:
  /// **'Error saving preferences'**
  String get preferencesError;

  /// No description provided for @preferencesMealPlanSection.
  ///
  /// In en, this message translates to:
  /// **'MEAL PLAN'**
  String get preferencesMealPlanSection;

  /// No description provided for @preferencesMealPlanFromFavorites.
  ///
  /// In en, this message translates to:
  /// **'Generate from favorites'**
  String get preferencesMealPlanFromFavorites;

  /// No description provided for @preferencesMealPlanFromFavoritesDesc.
  ///
  /// In en, this message translates to:
  /// **'Only use your saved recipes'**
  String get preferencesMealPlanFromFavoritesDesc;

  /// No description provided for @preferencesCookingSection.
  ///
  /// In en, this message translates to:
  /// **'COOKING'**
  String get preferencesCookingSection;

  /// No description provided for @preferencesCookingTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Preparation time'**
  String get preferencesCookingTimeLabel;

  /// No description provided for @preferencesCookingTimeQuick.
  ///
  /// In en, this message translates to:
  /// **'Quick (< 30 min)'**
  String get preferencesCookingTimeQuick;

  /// No description provided for @preferencesCookingTimeMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium (30–60 min)'**
  String get preferencesCookingTimeMedium;

  /// No description provided for @preferencesCookingTimeAny.
  ///
  /// In en, this message translates to:
  /// **'No preference'**
  String get preferencesCookingTimeAny;

  /// No description provided for @preferencesBatchCookingLabel.
  ///
  /// In en, this message translates to:
  /// **'Batch cooking'**
  String get preferencesBatchCookingLabel;

  /// No description provided for @preferencesBatchCookingDesc.
  ///
  /// In en, this message translates to:
  /// **'Prepare several meals at once'**
  String get preferencesBatchCookingDesc;

  /// No description provided for @preferencesBatchCookingDetail.
  ///
  /// In en, this message translates to:
  /// **'Cook in bulk for the week'**
  String get preferencesBatchCookingDetail;

  /// No description provided for @preferencesBatchPortions.
  ///
  /// In en, this message translates to:
  /// **'Max portions per session'**
  String get preferencesBatchPortions;

  /// No description provided for @preferencesCuisineSection.
  ///
  /// In en, this message translates to:
  /// **'CUISINE REGION'**
  String get preferencesCuisineSection;

  /// No description provided for @preferencesRegionWestAfrica.
  ///
  /// In en, this message translates to:
  /// **'West Africa'**
  String get preferencesRegionWestAfrica;

  /// No description provided for @preferencesRegionEastAfrica.
  ///
  /// In en, this message translates to:
  /// **'East Africa'**
  String get preferencesRegionEastAfrica;

  /// No description provided for @preferencesRegionNorthAfrica.
  ///
  /// In en, this message translates to:
  /// **'North Africa'**
  String get preferencesRegionNorthAfrica;

  /// No description provided for @preferencesRegionCentralAfrica.
  ///
  /// In en, this message translates to:
  /// **'Central Africa'**
  String get preferencesRegionCentralAfrica;

  /// No description provided for @preferencesRegionSouthAfrica.
  ///
  /// In en, this message translates to:
  /// **'South Africa'**
  String get preferencesRegionSouthAfrica;

  /// No description provided for @preferencesRegionCaribbean.
  ///
  /// In en, this message translates to:
  /// **'Caribbean'**
  String get preferencesRegionCaribbean;

  /// No description provided for @preferencesRegionWestern.
  ///
  /// In en, this message translates to:
  /// **'Western'**
  String get preferencesRegionWestern;

  /// No description provided for @preferencesDietSection.
  ///
  /// In en, this message translates to:
  /// **'DIETARY RESTRICTIONS'**
  String get preferencesDietSection;

  /// No description provided for @preferencesNoPork.
  ///
  /// In en, this message translates to:
  /// **'No pork'**
  String get preferencesNoPork;

  /// No description provided for @preferencesNoMeat.
  ///
  /// In en, this message translates to:
  /// **'No meat'**
  String get preferencesNoMeat;

  /// No description provided for @preferencesNoGluten.
  ///
  /// In en, this message translates to:
  /// **'No gluten'**
  String get preferencesNoGluten;

  /// No description provided for @preferencesNoLactose.
  ///
  /// In en, this message translates to:
  /// **'No lactose'**
  String get preferencesNoLactose;

  /// No description provided for @notificationSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationSettingsTitle;

  /// No description provided for @notificationSettingsMealReminders.
  ///
  /// In en, this message translates to:
  /// **'Meal Reminders'**
  String get notificationSettingsMealReminders;

  /// No description provided for @notificationSettingsNewRecipes.
  ///
  /// In en, this message translates to:
  /// **'New Recipes'**
  String get notificationSettingsNewRecipes;

  /// No description provided for @notificationSettingsCommunity.
  ///
  /// In en, this message translates to:
  /// **'Community'**
  String get notificationSettingsCommunity;

  /// No description provided for @notificationSettingsSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get notificationSettingsSave;

  /// No description provided for @savedRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved Recipes'**
  String get savedRecipesTitle;

  /// No description provided for @savedRecipesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saved recipes yet'**
  String get savedRecipesEmpty;

  /// No description provided for @savedRecipesEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save recipes to find them easily'**
  String get savedRecipesEmptySubtitle;

  /// No description provided for @fanModeTitle.
  ///
  /// In en, this message translates to:
  /// **'Fan Mode'**
  String get fanModeTitle;

  /// No description provided for @fanModeSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get fanModeSubscribe;

  /// No description provided for @fanModeUnsubscribe.
  ///
  /// In en, this message translates to:
  /// **'Unsubscribe'**
  String get fanModeUnsubscribe;

  /// No description provided for @fanModeMyCreators.
  ///
  /// In en, this message translates to:
  /// **'My Creators'**
  String get fanModeMyCreators;

  /// No description provided for @fanModeNoCreators.
  ///
  /// In en, this message translates to:
  /// **'No creators followed yet'**
  String get fanModeNoCreators;

  /// No description provided for @subscriptionTitle.
  ///
  /// In en, this message translates to:
  /// **'Go Premium'**
  String get subscriptionTitle;

  /// No description provided for @subscriptionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Unlock all features'**
  String get subscriptionSubtitle;

  /// No description provided for @subscriptionMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscriptionMonthly;

  /// No description provided for @subscriptionAnnual.
  ///
  /// In en, this message translates to:
  /// **'Annual'**
  String get subscriptionAnnual;

  /// No description provided for @subscriptionSubscribe.
  ///
  /// In en, this message translates to:
  /// **'Subscribe'**
  String get subscriptionSubscribe;

  /// No description provided for @referralTitle.
  ///
  /// In en, this message translates to:
  /// **'Refer a Friend'**
  String get referralTitle;

  /// No description provided for @referralCopyCode.
  ///
  /// In en, this message translates to:
  /// **'Copy Code'**
  String get referralCopyCode;

  /// No description provided for @referralCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied!'**
  String get referralCodeCopied;

  /// No description provided for @supportTitle.
  ///
  /// In en, this message translates to:
  /// **'Help & FAQ'**
  String get supportTitle;

  /// No description provided for @aiAssistantTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Assistant'**
  String get aiAssistantTitle;

  /// No description provided for @aiAssistantPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask me anything about nutrition...'**
  String get aiAssistantPlaceholder;

  /// No description provided for @aiAssistantSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get aiAssistantSend;

  /// No description provided for @batchCookingTitle.
  ///
  /// In en, this message translates to:
  /// **'Batch Cooking'**
  String get batchCookingTitle;

  /// No description provided for @batchCookingEmpty.
  ///
  /// In en, this message translates to:
  /// **'No batch cooking sessions'**
  String get batchCookingEmpty;

  /// No description provided for @ratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Rate this meal'**
  String get ratingTitle;

  /// No description provided for @ratingSubmit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get ratingSubmit;

  /// No description provided for @ratingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get ratingSkip;

  /// No description provided for @journeyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Journey'**
  String get journeyTitle;

  /// No description provided for @journeyStreak.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day streak} other{{count} day streak}}'**
  String journeyStreak(int count);

  /// No description provided for @journeyNoData.
  ///
  /// In en, this message translates to:
  /// **'Start your journey today'**
  String get journeyNoData;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get commonSuccess;

  /// No description provided for @commonNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get commonNext;

  /// No description provided for @commonPrevious.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get commonPrevious;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @difficultyEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get difficultyEasy;

  /// No description provided for @difficultyMedium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get difficultyMedium;

  /// No description provided for @difficultyHard.
  ///
  /// In en, this message translates to:
  /// **'Hard'**
  String get difficultyHard;

  /// No description provided for @dietVegetarian.
  ///
  /// In en, this message translates to:
  /// **'Vegetarian'**
  String get dietVegetarian;

  /// No description provided for @dietVegan.
  ///
  /// In en, this message translates to:
  /// **'Vegan'**
  String get dietVegan;

  /// No description provided for @dietPescatarian.
  ///
  /// In en, this message translates to:
  /// **'Pescatarian'**
  String get dietPescatarian;

  /// No description provided for @dietHalal.
  ///
  /// In en, this message translates to:
  /// **'Halal'**
  String get dietHalal;

  /// No description provided for @dietKosher.
  ///
  /// In en, this message translates to:
  /// **'Kosher'**
  String get dietKosher;

  /// No description provided for @dietGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten Free'**
  String get dietGlutenFree;

  /// No description provided for @dietLactoseFree.
  ///
  /// In en, this message translates to:
  /// **'Lactose Free'**
  String get dietLactoseFree;

  /// No description provided for @dietNutFree.
  ///
  /// In en, this message translates to:
  /// **'Nut Free'**
  String get dietNutFree;

  /// No description provided for @languageSelectorTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get languageSelectorTitle;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageFrench.
  ///
  /// In en, this message translates to:
  /// **'Français'**
  String get languageFrench;

  /// No description provided for @onboardingWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Akeli'**
  String get onboardingWelcome;

  /// No description provided for @onboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize your experience'**
  String get onboardingSubtitle;

  /// No description provided for @onboardingAge.
  ///
  /// In en, this message translates to:
  /// **'What is your age?'**
  String get onboardingAge;

  /// No description provided for @onboardingEstimatedDeadline.
  ///
  /// In en, this message translates to:
  /// **'ESTIMATED DEADLINE'**
  String get onboardingEstimatedDeadline;

  /// No description provided for @onboardingBatchPrepMeals.
  ///
  /// In en, this message translates to:
  /// **'Prepare several meals at once'**
  String get onboardingBatchPrepMeals;

  /// No description provided for @onboardingBatchCookWeek.
  ///
  /// In en, this message translates to:
  /// **'Cook in bulk for the week'**
  String get onboardingBatchCookWeek;

  /// No description provided for @onboardingPreferences.
  ///
  /// In en, this message translates to:
  /// **'Your Preferences'**
  String get onboardingPreferences;

  /// No description provided for @onboardingPreferencesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s personalize your culinary experience.'**
  String get onboardingPreferencesSubtitle;

  /// No description provided for @onboardingDietLabel.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preferences'**
  String get onboardingDietLabel;

  /// No description provided for @onboardingAllergens.
  ///
  /// In en, this message translates to:
  /// **'Allergies & Intolerances'**
  String get onboardingAllergens;

  /// No description provided for @onboardingAllergensHint.
  ///
  /// In en, this message translates to:
  /// **'Add ingredients to avoid.'**
  String get onboardingAllergensHint;

  /// No description provided for @onboardingSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get onboardingSummary;

  /// No description provided for @onboardingSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your profile is ready. Let\'s check the details before we begin.'**
  String get onboardingSummarySubtitle;

  /// No description provided for @onboardingDietaryPreferences.
  ///
  /// In en, this message translates to:
  /// **'Dietary Preferences'**
  String get onboardingDietaryPreferences;

  /// No description provided for @feedSortBestRated.
  ///
  /// In en, this message translates to:
  /// **'Best rated'**
  String get feedSortBestRated;

  /// No description provided for @feedSortPopular.
  ///
  /// In en, this message translates to:
  /// **'Most popular'**
  String get feedSortPopular;

  /// No description provided for @feedSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get feedSortNewest;

  /// No description provided for @feedSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'Relevance'**
  String get feedSortRelevance;

  /// No description provided for @feedSortMostFans.
  ///
  /// In en, this message translates to:
  /// **'Most fans'**
  String get feedSortMostFans;

  /// No description provided for @feedSortMostRecipes.
  ///
  /// In en, this message translates to:
  /// **'Most recipes'**
  String get feedSortMostRecipes;

  /// No description provided for @feedSortCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get feedSortCustom;

  /// No description provided for @unitKilograms.
  ///
  /// In en, this message translates to:
  /// **'KILOGRAMS'**
  String get unitKilograms;

  /// No description provided for @unitPounds.
  ///
  /// In en, this message translates to:
  /// **'POUNDS'**
  String get unitPounds;

  /// No description provided for @feedFilterTimeMax.
  ///
  /// In en, this message translates to:
  /// **'< {min} min'**
  String feedFilterTimeMax(int min);

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingStep.
  ///
  /// In en, this message translates to:
  /// **'Step {current} of {total}'**
  String onboardingStep(int current, int total);

  /// No description provided for @onboardingBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get onboardingBack;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingFinish.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingFinish;

  /// No description provided for @onboardingProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Your Profile'**
  String get onboardingProfileTitle;

  /// No description provided for @onboardingDisplayNameHint.
  ///
  /// In en, this message translates to:
  /// **'How should we call you?'**
  String get onboardingDisplayNameHint;

  /// No description provided for @onboardingActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity Level'**
  String get onboardingActivityTitle;

  /// No description provided for @mealDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Meal not found'**
  String get mealDetailNotFound;

  /// No description provided for @mealDetailConsumed.
  ///
  /// In en, this message translates to:
  /// **'Meal consumed'**
  String get mealDetailConsumed;

  /// No description provided for @mealDetailMarkConsumed.
  ///
  /// In en, this message translates to:
  /// **'Mark as consumed'**
  String get mealDetailMarkConsumed;

  /// No description provided for @mealDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mealDetailDescription;

  /// No description provided for @mealDetailSwapRecipe.
  ///
  /// In en, this message translates to:
  /// **'Change recipe'**
  String get mealDetailSwapRecipe;

  /// No description provided for @mealDetailPersonalMeal.
  ///
  /// In en, this message translates to:
  /// **'Personal Meal (AI)'**
  String get mealDetailPersonalMeal;

  /// No description provided for @mealDetailConsumeFirst.
  ///
  /// In en, this message translates to:
  /// **'Consume this meal first'**
  String get mealDetailConsumeFirst;

  /// No description provided for @mealDetailEditReview.
  ///
  /// In en, this message translates to:
  /// **'Edit your review'**
  String get mealDetailEditReview;

  /// No description provided for @mealDetailLeaveReview.
  ///
  /// In en, this message translates to:
  /// **'Leave a review'**
  String get mealDetailLeaveReview;

  /// No description provided for @mealDetailViewFullRecipe.
  ///
  /// In en, this message translates to:
  /// **'View full recipe'**
  String get mealDetailViewFullRecipe;

  /// No description provided for @mealDetailBatchPrep.
  ///
  /// In en, this message translates to:
  /// **'Batch preparation'**
  String get mealDetailBatchPrep;

  /// No description provided for @mealDetailBatchSession.
  ///
  /// In en, this message translates to:
  /// **'Batch cooking session'**
  String get mealDetailBatchSession;

  /// No description provided for @recipeDetailTotalRecipe.
  ///
  /// In en, this message translates to:
  /// **'Total recipe'**
  String get recipeDetailTotalRecipe;

  /// No description provided for @recipeDetailPerServing.
  ///
  /// In en, this message translates to:
  /// **'Per serving'**
  String get recipeDetailPerServing;

  /// No description provided for @recipeDetailReviews.
  ///
  /// In en, this message translates to:
  /// **'Reviews'**
  String get recipeDetailReviews;

  /// No description provided for @recipeDetailRatingTaste.
  ///
  /// In en, this message translates to:
  /// **'Taste'**
  String get recipeDetailRatingTaste;

  /// No description provided for @recipeDetailRatingEase.
  ///
  /// In en, this message translates to:
  /// **'Ease'**
  String get recipeDetailRatingEase;

  /// No description provided for @recipeDetailRatingSatiety.
  ///
  /// In en, this message translates to:
  /// **'Satiety'**
  String get recipeDetailRatingSatiety;

  /// No description provided for @batchCookingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get batchCookingThisWeek;

  /// No description provided for @batchCookingOngoing.
  ///
  /// In en, this message translates to:
  /// **'Your ongoing preparations'**
  String get batchCookingOngoing;

  /// No description provided for @batchCookingNoSessionsTitle.
  ///
  /// In en, this message translates to:
  /// **'No sessions this week'**
  String get batchCookingNoSessionsTitle;

  /// No description provided for @batchCookingNoSessionsBody.
  ///
  /// In en, this message translates to:
  /// **'Your batch sessions will appear here automatically when a recipe is planned multiple times.'**
  String get batchCookingNoSessionsBody;

  /// No description provided for @batchCookingDefaultRecipe.
  ///
  /// In en, this message translates to:
  /// **'Recipe'**
  String get batchCookingDefaultRecipe;

  /// No description provided for @batchDetailPreparation.
  ///
  /// In en, this message translates to:
  /// **'Preparation'**
  String get batchDetailPreparation;

  /// No description provided for @batchDetailPortionsUsed.
  ///
  /// In en, this message translates to:
  /// **'Portions used'**
  String get batchDetailPortionsUsed;

  /// No description provided for @batchDetailPortionsUsedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} used'**
  String batchDetailPortionsUsedCount(int count);

  /// No description provided for @batchDetailStartCooking.
  ///
  /// In en, this message translates to:
  /// **'Start cooking'**
  String get batchDetailStartCooking;

  /// No description provided for @commonAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get commonAdd;

  /// No description provided for @mealPlannerAddSnack.
  ///
  /// In en, this message translates to:
  /// **'Add a snack'**
  String get mealPlannerAddSnack;

  /// No description provided for @mealPlannerAddAnotherSnack.
  ///
  /// In en, this message translates to:
  /// **'Add another snack'**
  String get mealPlannerAddAnotherSnack;

  /// No description provided for @snackPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose a snack'**
  String get snackPickerTitle;

  /// No description provided for @snackPickerEstimatedQty.
  ///
  /// In en, this message translates to:
  /// **'Estimated quantity'**
  String get snackPickerEstimatedQty;

  /// No description provided for @snackPickerPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal snack'**
  String get snackPickerPersonal;

  /// No description provided for @snackPickerNoResults.
  ///
  /// In en, this message translates to:
  /// **'No recipe found'**
  String get snackPickerNoResults;

  /// No description provided for @fanModeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get fanModeLoadError;

  /// No description provided for @fanModeCreatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Creators to support'**
  String get fanModeCreatorsTitle;

  /// No description provided for @fanModeCreatorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your dominant creator is highlighted.'**
  String get fanModeCreatorsSubtitle;

  /// No description provided for @fanModeNoCreatorsTitle.
  ///
  /// In en, this message translates to:
  /// **'No eligible creators'**
  String get fanModeNoCreatorsTitle;

  /// No description provided for @fanModeNoCreatorsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Creators must publish 30 recipes to be eligible.'**
  String get fanModeNoCreatorsSubtitle;

  /// No description provided for @fanModeActivateTitle.
  ///
  /// In en, this message translates to:
  /// **'Activate Fan Mode'**
  String get fanModeActivateTitle;

  /// No description provided for @fanModeActivateContent.
  ///
  /// In en, this message translates to:
  /// **'You are about to support {name} with €1/month, included in your Akeli subscription.\n\nRule 90/10: 90% of your meals must come from this creator\'s catalog (max 9 external recipes per month).\n\nActive from the 1st of next month.'**
  String fanModeActivateContent(String name);

  /// No description provided for @fanModeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get fanModeConfirm;

  /// No description provided for @fanModeActivateError.
  ///
  /// In en, this message translates to:
  /// **'Error during activation.'**
  String get fanModeActivateError;

  /// No description provided for @fanModeActivateSuccess.
  ///
  /// In en, this message translates to:
  /// **'You are now supporting {name}!'**
  String fanModeActivateSuccess(String name);

  /// No description provided for @fanModeRecipesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'Your recipes this month'**
  String get fanModeRecipesThisMonth;

  /// No description provided for @fanModeNoRecipesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No recipes recorded this month'**
  String get fanModeNoRecipesThisMonth;

  /// No description provided for @fanModeTotalMeals.
  ///
  /// In en, this message translates to:
  /// **'{count} meals recorded'**
  String fanModeTotalMeals(int count);

  /// No description provided for @fanModeRecipeCount.
  ///
  /// In en, this message translates to:
  /// **'{count} recipes'**
  String fanModeRecipeCount(int count);

  /// No description provided for @fanModeFanCount.
  ///
  /// In en, this message translates to:
  /// **'{count} fans'**
  String fanModeFanCount(int count);

  /// No description provided for @fanModeSupport.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get fanModeSupport;

  /// No description provided for @fanModeQuit.
  ///
  /// In en, this message translates to:
  /// **'Leave Fan Mode'**
  String get fanModeQuit;

  /// No description provided for @fanModeQuitContent.
  ///
  /// In en, this message translates to:
  /// **'Your support will end at the end of the current month.'**
  String get fanModeQuitContent;

  /// No description provided for @fanModeKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get fanModeKeep;

  /// No description provided for @fanModeQuitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get fanModeQuitConfirm;

  /// No description provided for @fanModeCancelled.
  ///
  /// In en, this message translates to:
  /// **'Fan Mode cancelled.'**
  String get fanModeCancelled;

  /// No description provided for @fanModeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'⏳ Active from the 1st of next month'**
  String get fanModeStatusPending;

  /// No description provided for @fanModeStatusActive.
  ///
  /// In en, this message translates to:
  /// **'❤️ Fan Mode active'**
  String get fanModeStatusActive;

  /// No description provided for @fanModeExternalTitle.
  ///
  /// In en, this message translates to:
  /// **'External recipes this month'**
  String get fanModeExternalTitle;

  /// No description provided for @fanModeExternalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes outside catalog'**
  String get fanModeExternalSubtitle;

  /// No description provided for @fanModeEngagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Fan Mode Commitment'**
  String get fanModeEngagementTitle;

  /// No description provided for @fanModeEngagementYouSupport.
  ///
  /// In en, this message translates to:
  /// **'You support '**
  String get fanModeEngagementYouSupport;

  /// No description provided for @fanModeEngagementWith.
  ///
  /// In en, this message translates to:
  /// **' with '**
  String get fanModeEngagementWith;

  /// No description provided for @fanModeEngagementGuaranteed.
  ///
  /// In en, this message translates to:
  /// **'€1/month guaranteed'**
  String get fanModeEngagementGuaranteed;

  /// No description provided for @fanModeEngagementIncluded.
  ///
  /// In en, this message translates to:
  /// **', included in your subscription.\n\nFan Rule 90/10: 90% of your meals must come from this creator\'s catalog. You can use up to '**
  String get fanModeEngagementIncluded;

  /// No description provided for @fanModeEngagementExternalCount.
  ///
  /// In en, this message translates to:
  /// **'9 external recipes'**
  String get fanModeEngagementExternalCount;

  /// No description provided for @fanModeEngagementPerMonth.
  ///
  /// In en, this message translates to:
  /// **' per month.'**
  String get fanModeEngagementPerMonth;

  /// No description provided for @fanModeDefaultCreator.
  ///
  /// In en, this message translates to:
  /// **'your creator'**
  String get fanModeDefaultCreator;

  /// No description provided for @commonLoadError.
  ///
  /// In en, this message translates to:
  /// **'Loading error'**
  String get commonLoadError;

  /// No description provided for @commonGenericError.
  ///
  /// In en, this message translates to:
  /// **'An error occurred. Please try again.'**
  String get commonGenericError;

  /// No description provided for @groupDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Group Details'**
  String get groupDetailTitle;

  /// No description provided for @groupDetailUnknownGroup.
  ///
  /// In en, this message translates to:
  /// **'Unknown group'**
  String get groupDetailUnknownGroup;

  /// No description provided for @groupDetailTabMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get groupDetailTabMembers;

  /// No description provided for @groupDetailTabPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get groupDetailTabPhotos;

  /// No description provided for @groupDetailTabRecipes.
  ///
  /// In en, this message translates to:
  /// **'Recipes'**
  String get groupDetailTabRecipes;

  /// No description provided for @groupDetailDmAlreadySent.
  ///
  /// In en, this message translates to:
  /// **'Request already sent'**
  String get groupDetailDmAlreadySent;

  /// No description provided for @groupDetailDmSentTo.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}'**
  String groupDetailDmSentTo(String name);

  /// No description provided for @groupDetailExcludeTitle.
  ///
  /// In en, this message translates to:
  /// **'Exclude {name}?'**
  String groupDetailExcludeTitle(String name);

  /// No description provided for @groupDetailExcludeContent.
  ///
  /// In en, this message translates to:
  /// **'This person will lose access to the group and group chat.'**
  String get groupDetailExcludeContent;

  /// No description provided for @groupDetailExclude.
  ///
  /// In en, this message translates to:
  /// **'Exclude'**
  String get groupDetailExclude;

  /// No description provided for @groupDetailMemberExcluded.
  ///
  /// In en, this message translates to:
  /// **'Member excluded from group'**
  String get groupDetailMemberExcluded;

  /// No description provided for @groupDetailNotAdmin.
  ///
  /// In en, this message translates to:
  /// **'You are no longer an administrator of this group'**
  String get groupDetailNotAdmin;

  /// No description provided for @groupDetailInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get groupDetailInvite;

  /// No description provided for @groupDetailNoMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'No members'**
  String get groupDetailNoMembersTitle;

  /// No description provided for @groupDetailNoMembersSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Members will appear here.'**
  String get groupDetailNoMembersSubtitle;

  /// No description provided for @groupDetailNoPhotosTitle.
  ///
  /// In en, this message translates to:
  /// **'No shared photos'**
  String get groupDetailNoPhotosTitle;

  /// No description provided for @groupDetailNoPhotosSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Photos sent in the chat will appear here.'**
  String get groupDetailNoPhotosSubtitle;

  /// No description provided for @groupDetailNoRecipesTitle.
  ///
  /// In en, this message translates to:
  /// **'No shared recipes'**
  String get groupDetailNoRecipesTitle;

  /// No description provided for @groupDetailNoRecipesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Recipes shared in the chat will appear here.'**
  String get groupDetailNoRecipesSubtitle;

  /// No description provided for @groupDetailInvitesSent.
  ///
  /// In en, this message translates to:
  /// **'Invitations sent'**
  String get groupDetailInvitesSent;

  /// No description provided for @groupDetailInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite members'**
  String get groupDetailInviteTitle;

  /// No description provided for @groupDetailNoEligibleTitle.
  ///
  /// In en, this message translates to:
  /// **'No eligible contacts'**
  String get groupDetailNoEligibleTitle;

  /// No description provided for @groupDetailNoEligibleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have any private conversations with users to invite yet.'**
  String get groupDetailNoEligibleSubtitle;

  /// No description provided for @groupDetailInviteCount.
  ///
  /// In en, this message translates to:
  /// **'Invite ({count})'**
  String groupDetailInviteCount(int count);

  /// No description provided for @groupDetailPrivateMessage.
  ///
  /// In en, this message translates to:
  /// **'Private message'**
  String get groupDetailPrivateMessage;

  /// No description provided for @groupDetailExcludeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Exclude from group'**
  String get groupDetailExcludeFromGroup;

  /// No description provided for @allergenPickerHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. peanuts, nuts...'**
  String get allergenPickerHint;

  /// No description provided for @allergenPickerAdd.
  ///
  /// In en, this message translates to:
  /// **'Add \"{query}\"'**
  String allergenPickerAdd(String query);

  /// No description provided for @allergenPickerSuggestionSent.
  ///
  /// In en, this message translates to:
  /// **'Suggestion sent for review.'**
  String get allergenPickerSuggestionSent;

  /// No description provided for @ingredientDetailOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get ingredientDetailOptional;

  /// No description provided for @ingredientDetailTagHighProtein.
  ///
  /// In en, this message translates to:
  /// **'High protein'**
  String get ingredientDetailTagHighProtein;

  /// No description provided for @ingredientDetailTagLowFat.
  ///
  /// In en, this message translates to:
  /// **'Low fat'**
  String get ingredientDetailTagLowFat;

  /// No description provided for @ingredientDetailTagGlutenFree.
  ///
  /// In en, this message translates to:
  /// **'Gluten free'**
  String get ingredientDetailTagGlutenFree;

  /// No description provided for @ingredientDetailTagAfricanStaple.
  ///
  /// In en, this message translates to:
  /// **'African staple'**
  String get ingredientDetailTagAfricanStaple;

  /// No description provided for @ingredientDetailTagHardToFindEu.
  ///
  /// In en, this message translates to:
  /// **'Hard to find in Europe'**
  String get ingredientDetailTagHardToFindEu;

  /// No description provided for @ingredientDetailNutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition (per 100g)'**
  String get ingredientDetailNutritionTitle;

  /// No description provided for @ingredientDetailEnergy.
  ///
  /// In en, this message translates to:
  /// **'Energy'**
  String get ingredientDetailEnergy;

  /// No description provided for @cookingSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Cooking Session'**
  String get cookingSessionTitle;

  /// No description provided for @cookingSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Organize your meals for the week'**
  String get cookingSessionSubtitle;

  /// No description provided for @cookingSessionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get cookingSessionComingSoon;

  /// No description provided for @cookingSessionComingSoonDesc.
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in a future update'**
  String get cookingSessionComingSoonDesc;

  /// No description provided for @cookingSessionGotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get cookingSessionGotIt;

  /// No description provided for @journeyCalendarLegendAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get journeyCalendarLegendAll;

  /// No description provided for @journeyCalendarLegendPartial.
  ///
  /// In en, this message translates to:
  /// **'Partial'**
  String get journeyCalendarLegendPartial;

  /// No description provided for @journeyCalendarLegendNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get journeyCalendarLegendNone;

  /// No description provided for @journeySummaryDays.
  ///
  /// In en, this message translates to:
  /// **'Journey days'**
  String get journeySummaryDays;

  /// No description provided for @journeySummaryTracked.
  ///
  /// In en, this message translates to:
  /// **'Days tracked'**
  String get journeySummaryTracked;

  /// No description provided for @journeySummaryMeals.
  ///
  /// In en, this message translates to:
  /// **'Meals consumed'**
  String get journeySummaryMeals;

  /// No description provided for @journeySummaryConsistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get journeySummaryConsistency;

  /// No description provided for @journeyGoalsWeight.
  ///
  /// In en, this message translates to:
  /// **'⚖️  Weight'**
  String get journeyGoalsWeight;

  /// No description provided for @journeyGoalsCalories.
  ///
  /// In en, this message translates to:
  /// **'🎯  Calories'**
  String get journeyGoalsCalories;

  /// No description provided for @journeyGoalsProtein.
  ///
  /// In en, this message translates to:
  /// **'💪  Protein'**
  String get journeyGoalsProtein;

  /// No description provided for @journeyGoalsCarbs.
  ///
  /// In en, this message translates to:
  /// **'🌾  Carbs'**
  String get journeyGoalsCarbs;

  /// No description provided for @journeyGoalsFat.
  ///
  /// In en, this message translates to:
  /// **'🥑  Fat'**
  String get journeyGoalsFat;

  /// No description provided for @journeyGoalsCalorieHitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You hit your calorie goal {pct}% of tracked days.'**
  String journeyGoalsCalorieHitSubtitle(int pct);

  /// No description provided for @subscriptionMyTitle.
  ///
  /// In en, this message translates to:
  /// **'My Subscription'**
  String get subscriptionMyTitle;

  /// No description provided for @subscriptionActiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Active Subscription'**
  String get subscriptionActiveTitle;

  /// No description provided for @subscriptionPremiumBadge.
  ///
  /// In en, this message translates to:
  /// **'Akeli Premium'**
  String get subscriptionPremiumBadge;

  /// No description provided for @subscriptionActiveThankYou.
  ///
  /// In en, this message translates to:
  /// **'Thank you for being part of the Akeli community.'**
  String get subscriptionActiveThankYou;

  /// No description provided for @subscriptionTagline.
  ///
  /// In en, this message translates to:
  /// **'Personalized African nutrition'**
  String get subscriptionTagline;

  /// No description provided for @subscriptionIncludedTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s included'**
  String get subscriptionIncludedTitle;

  /// No description provided for @subscriptionPerMonth.
  ///
  /// In en, this message translates to:
  /// **'/ month'**
  String get subscriptionPerMonth;

  /// No description provided for @subscriptionCancelAnytime.
  ///
  /// In en, this message translates to:
  /// **'Cancel anytime via the Store'**
  String get subscriptionCancelAnytime;

  /// No description provided for @subscriptionSubscribeViaStore.
  ///
  /// In en, this message translates to:
  /// **'Subscribe via the Store'**
  String get subscriptionSubscribeViaStore;

  /// No description provided for @subscriptionMobileOnly.
  ///
  /// In en, this message translates to:
  /// **'Subscription available on iOS and Android only.'**
  String get subscriptionMobileOnly;

  /// No description provided for @subscriptionFeature1.
  ///
  /// In en, this message translates to:
  /// **'Personalized African recipes with AI'**
  String get subscriptionFeature1;

  /// No description provided for @subscriptionFeature2.
  ///
  /// In en, this message translates to:
  /// **'Adapted weekly meal plan'**
  String get subscriptionFeature2;

  /// No description provided for @subscriptionFeature3.
  ///
  /// In en, this message translates to:
  /// **'Detailed nutritional tracking'**
  String get subscriptionFeature3;

  /// No description provided for @subscriptionFeature4.
  ///
  /// In en, this message translates to:
  /// **'Nutritional AI assistant'**
  String get subscriptionFeature4;

  /// No description provided for @subscriptionFeature5.
  ///
  /// In en, this message translates to:
  /// **'Fan Mode — support your creators'**
  String get subscriptionFeature5;

  /// No description provided for @subscriptionFeature6.
  ///
  /// In en, this message translates to:
  /// **'Community and discussion groups'**
  String get subscriptionFeature6;

  /// No description provided for @subscriptionFeature7.
  ///
  /// In en, this message translates to:
  /// **'Automatic shopping list'**
  String get subscriptionFeature7;

  /// No description provided for @subscriptionActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'Active Premium Subscription'**
  String get subscriptionActiveBadge;

  /// No description provided for @subscriptionRenewalDate.
  ///
  /// In en, this message translates to:
  /// **'Next renewal: {date}'**
  String subscriptionRenewalDate(String date);

  /// No description provided for @subscriptionPlatformIos.
  ///
  /// In en, this message translates to:
  /// **'Subscription via App Store'**
  String get subscriptionPlatformIos;

  /// No description provided for @subscriptionPlatformAndroid.
  ///
  /// In en, this message translates to:
  /// **'Subscription via Google Play'**
  String get subscriptionPlatformAndroid;

  /// No description provided for @journalingNewEntry.
  ///
  /// In en, this message translates to:
  /// **'New entry'**
  String get journalingNewEntry;

  /// No description provided for @journalingNewEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Note your culinary experience'**
  String get journalingNewEntrySubtitle;

  /// No description provided for @journalingPhotos.
  ///
  /// In en, this message translates to:
  /// **'Photos'**
  String get journalingPhotos;

  /// No description provided for @journalingAddPhotos.
  ///
  /// In en, this message translates to:
  /// **'Add photos'**
  String get journalingAddPhotos;

  /// No description provided for @journalingMealType.
  ///
  /// In en, this message translates to:
  /// **'Meal type'**
  String get journalingMealType;

  /// No description provided for @journalingDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get journalingDescription;

  /// No description provided for @journalingDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'How was this meal? Tastes, textures, emotions...'**
  String get journalingDescriptionHint;

  /// No description provided for @journalingDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Please add a description'**
  String get journalingDescriptionRequired;

  /// No description provided for @journalingSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get journalingSaving;

  /// No description provided for @journalingSaveEntry.
  ///
  /// In en, this message translates to:
  /// **'Save entry'**
  String get journalingSaveEntry;

  /// No description provided for @journalingEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved successfully!'**
  String get journalingEntrySaved;

  /// No description provided for @journalingSaveError.
  ///
  /// In en, this message translates to:
  /// **'Error saving entry'**
  String get journalingSaveError;

  /// No description provided for @aiAssistantOnline.
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get aiAssistantOnline;

  /// No description provided for @aiAssistantNewConversation.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get aiAssistantNewConversation;

  /// No description provided for @aiAssistantToday.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get aiAssistantToday;

  /// No description provided for @aiAssistantError.
  ///
  /// In en, this message translates to:
  /// **'Sorry, an error occurred. Please try again in a moment.'**
  String get aiAssistantError;

  /// No description provided for @aiAssistantWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Hello, I\'m your Akeli nutritional assistant.'**
  String get aiAssistantWelcomeTitle;

  /// No description provided for @aiAssistantWelcomeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Ask me your questions about nutrition, African recipes or your meal plan.'**
  String get aiAssistantWelcomeSubtitle;

  /// No description provided for @aiAssistantSuggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get aiAssistantSuggestions;

  /// No description provided for @aiAssistantMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get aiAssistantMessageHint;

  /// No description provided for @aiAssistantSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Which protein-rich foods suit my culture?'**
  String get aiAssistantSuggestion1;

  /// No description provided for @aiAssistantSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'What is my recommended caloric intake?'**
  String get aiAssistantSuggestion2;

  /// No description provided for @aiAssistantSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'How to lose weight with African cuisine?'**
  String get aiAssistantSuggestion3;

  /// No description provided for @aiAssistantSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Give me a recipe for tonight.'**
  String get aiAssistantSuggestion4;

  /// No description provided for @referralCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Your referral code'**
  String get referralCodeLabel;

  /// No description provided for @referralReferreeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} referral} other{{count} referrals}}'**
  String referralReferreeCount(int count);

  /// No description provided for @referralShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share the Oasis'**
  String get referralShareTitle;

  /// No description provided for @referralShareBody.
  ///
  /// In en, this message translates to:
  /// **'Invite your friends to discover Akeli Oasis. For every friend who signs up with your code, you\'ll receive an exclusive wellness ritual invitation, and they\'ll get a privileged welcome.'**
  String get referralShareBody;

  /// No description provided for @referralChangeCodeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change code'**
  String get referralChangeCodeTitle;

  /// No description provided for @referralEditCode.
  ///
  /// In en, this message translates to:
  /// **'Edit code'**
  String get referralEditCode;

  /// No description provided for @referralNewCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'New code'**
  String get referralNewCodeLabel;

  /// No description provided for @referralNewCodeHint.
  ///
  /// In en, this message translates to:
  /// **'Enter a new code'**
  String get referralNewCodeHint;

  /// No description provided for @referralCodeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Code updated successfully!'**
  String get referralCodeUpdated;

  /// No description provided for @supportHeaderTitle.
  ///
  /// In en, this message translates to:
  /// **'How can we help you?'**
  String get supportHeaderTitle;

  /// No description provided for @supportHeaderSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Our team is here to answer your questions'**
  String get supportHeaderSubtitle;

  /// No description provided for @supportSubjectLabel.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get supportSubjectLabel;

  /// No description provided for @supportSubjectHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Login issue...'**
  String get supportSubjectHint;

  /// No description provided for @supportSubjectRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a subject'**
  String get supportSubjectRequired;

  /// No description provided for @supportEmailHint.
  ///
  /// In en, this message translates to:
  /// **'your@email.com'**
  String get supportEmailHint;

  /// No description provided for @supportEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get supportEmailRequired;

  /// No description provided for @supportEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email'**
  String get supportEmailInvalid;

  /// No description provided for @supportMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get supportMessageLabel;

  /// No description provided for @supportMessageHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your issue...'**
  String get supportMessageHint;

  /// No description provided for @supportMessageRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your message'**
  String get supportMessageRequired;

  /// No description provided for @supportMessageTooShort.
  ///
  /// In en, this message translates to:
  /// **'Message must be at least 10 characters'**
  String get supportMessageTooShort;

  /// No description provided for @supportAddScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Add a screenshot'**
  String get supportAddScreenshot;

  /// No description provided for @supportSendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get supportSendMessage;

  /// No description provided for @supportMessageSent.
  ///
  /// In en, this message translates to:
  /// **'Message sent successfully!'**
  String get supportMessageSent;

  /// No description provided for @supportSendError.
  ///
  /// In en, this message translates to:
  /// **'Error sending. Please try again.'**
  String get supportSendError;

  /// No description provided for @supportChangeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Change screenshot'**
  String get supportChangeScreenshot;

  /// No description provided for @savedRecipesEligibilityNotLoggedIn.
  ///
  /// In en, this message translates to:
  /// **'Not logged in'**
  String get savedRecipesEligibilityNotLoggedIn;

  /// No description provided for @savedRecipesEligibilityNoData.
  ///
  /// In en, this message translates to:
  /// **'No data found'**
  String get savedRecipesEligibilityNoData;

  /// No description provided for @savedRecipesEligibilityTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate from your favorites'**
  String get savedRecipesEligibilityTitle;

  /// No description provided for @savedRecipesEligibilityDesc.
  ///
  /// In en, this message translates to:
  /// **'If you have enough saved recipes, you can ask Akeli to generate your meal plans only from your favorites, rather than through our recommendations.'**
  String get savedRecipesEligibilityDesc;

  /// No description provided for @savedRecipesEligibilityProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get savedRecipesEligibilityProgress;

  /// No description provided for @savedRecipesEligibilityMissing.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} recipe missing} other{{count} recipes missing}}'**
  String savedRecipesEligibilityMissing(int count);

  /// No description provided for @savedRecipesEligibilityToggleTitle.
  ///
  /// In en, this message translates to:
  /// **'Use favorites only'**
  String get savedRecipesEligibilityToggleTitle;

  /// No description provided for @savedRecipesEligibilityEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get savedRecipesEligibilityEnabled;

  /// No description provided for @savedRecipesEligibilityBlocked.
  ///
  /// In en, this message translates to:
  /// **'Locked: You must reach 7 recipes for each category above.'**
  String get savedRecipesEligibilityBlocked;

  /// No description provided for @legalPrivacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get legalPrivacyTitle;

  /// No description provided for @legalPrivacyHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data is protected'**
  String get legalPrivacyHeroTitle;

  /// No description provided for @legalPrivacyHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We are committed to protecting your privacy in accordance with GDPR'**
  String get legalPrivacyHeroSubtitle;

  /// No description provided for @legalPrivacySummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'In brief'**
  String get legalPrivacySummaryTitle;

  /// No description provided for @legalPrivacyCollectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Minimal collection'**
  String get legalPrivacyCollectionTitle;

  /// No description provided for @legalPrivacyCollectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Only data necessary for the app to function'**
  String get legalPrivacyCollectionDesc;

  /// No description provided for @legalPrivacySecurityTitle.
  ///
  /// In en, this message translates to:
  /// **'Maximum security'**
  String get legalPrivacySecurityTitle;

  /// No description provided for @legalPrivacySecurityDesc.
  ///
  /// In en, this message translates to:
  /// **'End-to-end encryption and secure storage'**
  String get legalPrivacySecurityDesc;

  /// No description provided for @legalPrivacyControlTitle.
  ///
  /// In en, this message translates to:
  /// **'Total control'**
  String get legalPrivacyControlTitle;

  /// No description provided for @legalPrivacyControlDesc.
  ///
  /// In en, this message translates to:
  /// **'You can access, modify or delete your data at any time'**
  String get legalPrivacyControlDesc;

  /// No description provided for @legalPrivacySection1Title.
  ///
  /// In en, this message translates to:
  /// **'1. Data collection'**
  String get legalPrivacySection1Title;

  /// No description provided for @legalPrivacySection1Content.
  ///
  /// In en, this message translates to:
  /// **'We collect only the data needed to provide you with the best experience:\n\n• Profile information (name, email, dietary preferences)\n• Navigation history within the app\n• Health data you choose to share\n• Content preferences and interactions'**
  String get legalPrivacySection1Content;

  /// No description provided for @legalPrivacySection2Title.
  ///
  /// In en, this message translates to:
  /// **'2. Data use'**
  String get legalPrivacySection2Title;

  /// No description provided for @legalPrivacySection2Content.
  ///
  /// In en, this message translates to:
  /// **'Your data allows us to:\n\n• Personalize your recipe recommendations\n• Continuously improve our service\n• Send you relevant notifications\n• Ensure the security of your account'**
  String get legalPrivacySection2Content;

  /// No description provided for @legalPrivacySection3Title.
  ///
  /// In en, this message translates to:
  /// **'3. Your GDPR rights'**
  String get legalPrivacySection3Title;

  /// No description provided for @legalPrivacyRightAccess.
  ///
  /// In en, this message translates to:
  /// **'Access'**
  String get legalPrivacyRightAccess;

  /// No description provided for @legalPrivacyRightAccessDesc.
  ///
  /// In en, this message translates to:
  /// **'View your data'**
  String get legalPrivacyRightAccessDesc;

  /// No description provided for @legalPrivacyRightRectification.
  ///
  /// In en, this message translates to:
  /// **'Rectification'**
  String get legalPrivacyRightRectification;

  /// No description provided for @legalPrivacyRightRectificationDesc.
  ///
  /// In en, this message translates to:
  /// **'Modify your information'**
  String get legalPrivacyRightRectificationDesc;

  /// No description provided for @legalPrivacyRightErasure.
  ///
  /// In en, this message translates to:
  /// **'Erasure'**
  String get legalPrivacyRightErasure;

  /// No description provided for @legalPrivacyRightErasureDesc.
  ///
  /// In en, this message translates to:
  /// **'Delete your account'**
  String get legalPrivacyRightErasureDesc;

  /// No description provided for @legalPrivacyRightPortability.
  ///
  /// In en, this message translates to:
  /// **'Portability'**
  String get legalPrivacyRightPortability;

  /// No description provided for @legalPrivacyRightPortabilityDesc.
  ///
  /// In en, this message translates to:
  /// **'Export your data'**
  String get legalPrivacyRightPortabilityDesc;

  /// No description provided for @legalPrivacySection4Title.
  ///
  /// In en, this message translates to:
  /// **'4. Data sharing'**
  String get legalPrivacySection4Title;

  /// No description provided for @legalPrivacySection4Content.
  ///
  /// In en, this message translates to:
  /// **'We never sell your personal data.\n\nIt may only be shared with:\n• Our technical providers hosted in the EU\n• Legal authorities if required by law\n• Your favourite creators (only with your explicit consent)'**
  String get legalPrivacySection4Content;

  /// No description provided for @legalPrivacySection5Title.
  ///
  /// In en, this message translates to:
  /// **'5. Retention'**
  String get legalPrivacySection5Title;

  /// No description provided for @legalPrivacySection5Content.
  ///
  /// In en, this message translates to:
  /// **'Your data is retained:\n• As long as your account is active\n• Up to 3 years after your last login\n• Immediately deleted upon account deletion request'**
  String get legalPrivacySection5Content;

  /// No description provided for @legalPrivacyDpoTitle.
  ///
  /// In en, this message translates to:
  /// **'DPO Contact'**
  String get legalPrivacyDpoTitle;

  /// No description provided for @legalPrivacyDpoEmail.
  ///
  /// In en, this message translates to:
  /// **'dpo@akeli.app'**
  String get legalPrivacyDpoEmail;

  /// No description provided for @legalPrivacyDpoDesc.
  ///
  /// In en, this message translates to:
  /// **'Our data protection officer responds within 48 business hours to any request regarding your personal data.'**
  String get legalPrivacyDpoDesc;

  /// No description provided for @legalPrivacyVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0 • Last updated: January 2026'**
  String get legalPrivacyVersion;

  /// No description provided for @legalTermsTitle.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get legalTermsTitle;

  /// No description provided for @legalTermsHeroTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Akeli'**
  String get legalTermsHeroTitle;

  /// No description provided for @legalTermsHeroSubtitle.
  ///
  /// In en, this message translates to:
  /// **'By using our app, you accept these terms'**
  String get legalTermsHeroSubtitle;

  /// No description provided for @legalTermsArticle1Title.
  ///
  /// In en, this message translates to:
  /// **'Access to service'**
  String get legalTermsArticle1Title;

  /// No description provided for @legalTermsArticle1Content.
  ///
  /// In en, this message translates to:
  /// **'Akeli is a free mobile app dedicated to African nutrition and traditional recipes.\n\nAccess to the service requires:\n• A compatible iOS or Android smartphone\n• An internet connection to sync data\n• Creating a user account\n\nCertain premium features (Fan Mode, personalized plans) are available via subscription.'**
  String get legalTermsArticle1Content;

  /// No description provided for @legalTermsArticle2Title.
  ///
  /// In en, this message translates to:
  /// **'User account'**
  String get legalTermsArticle2Title;

  /// No description provided for @legalTermsArticle2Content.
  ///
  /// In en, this message translates to:
  /// **'You are responsible for:\n• The confidentiality of your credentials\n• The accuracy of the information provided\n• All activities carried out from your account\n\nWe reserve the right to suspend or delete any account that violates these terms.'**
  String get legalTermsArticle2Content;

  /// No description provided for @legalTermsArticle3Title.
  ///
  /// In en, this message translates to:
  /// **'Intellectual property'**
  String get legalTermsArticle3Title;

  /// No description provided for @legalTermsArticle3Content.
  ///
  /// In en, this message translates to:
  /// **'All content on Akeli (recipes, texts, images, logos) is the exclusive property of Akeli or its partners.\n\nProhibited:\n• Reproduction without authorization\n• Unauthorized commercial use\n• Modification or alteration of content\n\nCreators retain rights to their published recipes.'**
  String get legalTermsArticle3Content;

  /// No description provided for @legalTermsArticle4Title.
  ///
  /// In en, this message translates to:
  /// **'Liability'**
  String get legalTermsArticle4Title;

  /// No description provided for @legalTermsArticle4Content.
  ///
  /// In en, this message translates to:
  /// **'Akeli provides nutritional information for informational purposes only.\n\nWe cannot be held responsible for:\n• Errors in nutritional information\n• Allergic reactions or health problems related to recipes\n• Temporary service interruptions for maintenance\n\nAlways consult a healthcare professional for medical advice.'**
  String get legalTermsArticle4Content;

  /// No description provided for @legalTermsArticle5Title.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions and payments'**
  String get legalTermsArticle5Title;

  /// No description provided for @legalTermsArticle5Content.
  ///
  /// In en, this message translates to:
  /// **'Fan Mode subscriptions (€3/month) are billed monthly via the stores (Google Play / App Store).\n\n• Cancellation possible at any time\n• Access maintained until the end of the paid period\n• No partial refund\n\nCreators receive 70% of revenue generated by their subscribers.'**
  String get legalTermsArticle5Content;

  /// No description provided for @legalTermsArticle6Title.
  ///
  /// In en, this message translates to:
  /// **'Modifications'**
  String get legalTermsArticle6Title;

  /// No description provided for @legalTermsArticle6Content.
  ///
  /// In en, this message translates to:
  /// **'We reserve the right to modify these terms at any time.\n\nUsers will be notified:\n• By push notification for major changes\n• By email if the modification impacts personal data\n\nContinued use constitutes acceptance of the new terms.'**
  String get legalTermsArticle6Content;

  /// No description provided for @legalTermsContactTitle.
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get legalTermsContactTitle;

  /// No description provided for @legalTermsContactEmail.
  ///
  /// In en, this message translates to:
  /// **'legal@akeli.app'**
  String get legalTermsContactEmail;

  /// No description provided for @legalTermsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0 • Last updated: January 2026'**
  String get legalTermsVersion;

  /// No description provided for @mealScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Meal Schedule'**
  String get mealScheduleTitle;

  /// No description provided for @mealScheduleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define which meals you want each day'**
  String get mealScheduleSubtitle;

  /// No description provided for @mealScheduleAddSlot.
  ///
  /// In en, this message translates to:
  /// **'Add a meal slot'**
  String get mealScheduleAddSlot;

  /// No description provided for @mealScheduleSave.
  ///
  /// In en, this message translates to:
  /// **'Save schedule'**
  String get mealScheduleSave;

  /// No description provided for @mealScheduleCalorieTotal.
  ///
  /// In en, this message translates to:
  /// **'{total}% of daily calories'**
  String mealScheduleCalorieTotal(String total);

  /// No description provided for @mealScheduleCalorieTotalError.
  ///
  /// In en, this message translates to:
  /// **'Total must equal 100%'**
  String get mealScheduleCalorieTotalError;

  /// No description provided for @mealScheduleMacroSection.
  ///
  /// In en, this message translates to:
  /// **'Macro targets for this slot'**
  String get mealScheduleMacroSection;

  /// No description provided for @mealScheduleMacroError.
  ///
  /// In en, this message translates to:
  /// **'Macros must equal 100%'**
  String get mealScheduleMacroError;

  /// No description provided for @mealScheduleNicknamePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Custom label (optional)'**
  String get mealScheduleNicknamePlaceholder;

  /// No description provided for @mealScheduleCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Meal type'**
  String get mealScheduleCategoryLabel;

  /// No description provided for @mealScheduleApplyDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'When to apply?'**
  String get mealScheduleApplyDialogTitle;

  /// No description provided for @mealScheduleApplyFromToday.
  ///
  /// In en, this message translates to:
  /// **'Apply from today'**
  String get mealScheduleApplyFromToday;

  /// No description provided for @mealScheduleApplyFromNextWeek.
  ///
  /// In en, this message translates to:
  /// **'Apply from next week'**
  String get mealScheduleApplyFromNextWeek;

  /// No description provided for @mealScheduleHintBanner.
  ///
  /// In en, this message translates to:
  /// **'Customize your meal schedule anytime — tap the settings icon above'**
  String get mealScheduleHintBanner;

  /// No description provided for @mealScheduleHintDismiss.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get mealScheduleHintDismiss;

  /// No description provided for @mealScheduleOnboardingTitle.
  ///
  /// In en, this message translates to:
  /// **'Customize your meal schedule'**
  String get mealScheduleOnboardingTitle;

  /// No description provided for @mealScheduleOnboardingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose which meals you want each day. You can change this anytime in Settings.'**
  String get mealScheduleOnboardingSubtitle;

  /// No description provided for @mealScheduleOnboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip, use default (3 meals)'**
  String get mealScheduleOnboardingSkip;

  /// No description provided for @mealScheduleCustomizeButton.
  ///
  /// In en, this message translates to:
  /// **'Customize meal structure'**
  String get mealScheduleCustomizeButton;

  /// No description provided for @mealScheduleDeleteSlotTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove this slot'**
  String get mealScheduleDeleteSlotTooltip;

  /// No description provided for @mealScheduleCaloriePct.
  ///
  /// In en, this message translates to:
  /// **'Calorie share'**
  String get mealScheduleCaloriePct;

  /// No description provided for @mealScheduleProteinPct.
  ///
  /// In en, this message translates to:
  /// **'Protein %'**
  String get mealScheduleProteinPct;

  /// No description provided for @mealScheduleCarbsPct.
  ///
  /// In en, this message translates to:
  /// **'Carbs %'**
  String get mealScheduleCarbsPct;

  /// No description provided for @mealScheduleFatPct.
  ///
  /// In en, this message translates to:
  /// **'Fat %'**
  String get mealScheduleFatPct;

  /// No description provided for @mealScheduleSavedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Schedule saved'**
  String get mealScheduleSavedSuccess;

  /// No description provided for @mealScheduleVarietyTitle.
  ///
  /// In en, this message translates to:
  /// **'Recipe variety'**
  String get mealScheduleVarietyTitle;

  /// No description provided for @mealScheduleVarietySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Avoid repeating recipes used recently'**
  String get mealScheduleVarietySubtitle;

  /// No description provided for @mealScheduleVarietyNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get mealScheduleVarietyNone;

  /// No description provided for @mealScheduleVariety7Days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get mealScheduleVariety7Days;

  /// No description provided for @mealScheduleVariety15Days.
  ///
  /// In en, this message translates to:
  /// **'15 days'**
  String get mealScheduleVariety15Days;

  /// No description provided for @mealScheduleRandomTitle.
  ///
  /// In en, this message translates to:
  /// **'Randomize schedule'**
  String get mealScheduleRandomTitle;

  /// No description provided for @mealScheduleRandomSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle meal days across the week randomly'**
  String get mealScheduleRandomSubtitle;

  /// No description provided for @nutritionPlanSaveButton.
  ///
  /// In en, this message translates to:
  /// **'Save plan'**
  String get nutritionPlanSaveButton;

  /// No description provided for @nutritionToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nutritionToday;

  /// No description provided for @nutritionYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get nutritionYesterday;

  /// No description provided for @nutritionChartTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get nutritionChartTarget;

  /// No description provided for @nutritionEmptyStateTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'No Data'**
  String get nutritionEmptyStateTodayTitle;

  /// No description provided for @nutritionEmptyStateTodaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'No food logged for this day.'**
  String get nutritionEmptyStateTodaySubtitle;

  /// No description provided for @nutritionEmptyStateWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'No Data Yet'**
  String get nutritionEmptyStateWeekTitle;

  /// No description provided for @nutritionEmptyStateWeekSubtitle.
  ///
  /// In en, this message translates to:
  /// **'No food logged for this week.'**
  String get nutritionEmptyStateWeekSubtitle;

  /// No description provided for @nutritionWeightEvolution.
  ///
  /// In en, this message translates to:
  /// **'Weight Trend'**
  String get nutritionWeightEvolution;

  /// No description provided for @journeyBestStreakRecord.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get journeyBestStreakRecord;

  /// No description provided for @preferencesLocaleUsImperial.
  ///
  /// In en, this message translates to:
  /// **'English (US)'**
  String get preferencesLocaleUsImperial;

  /// No description provided for @dietPlanSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get dietPlanSummaryTitle;

  /// No description provided for @dietPlanSummarySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your diet plan'**
  String get dietPlanSummarySubtitle;

  /// No description provided for @dietPlanError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String dietPlanError(String error);

  /// No description provided for @dietPlanWeightEvolution.
  ///
  /// In en, this message translates to:
  /// **'WEIGHT PROGRESS'**
  String get dietPlanWeightEvolution;

  /// No description provided for @dietPlanPerWeek.
  ///
  /// In en, this message translates to:
  /// **'/ week'**
  String get dietPlanPerWeek;

  /// No description provided for @dietPlanWeightStartLabel.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get dietPlanWeightStartLabel;

  /// No description provided for @dietPlanWeightTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get dietPlanWeightTargetLabel;

  /// No description provided for @dietPlanCurrentWeightLabel.
  ///
  /// In en, this message translates to:
  /// **'current'**
  String get dietPlanCurrentWeightLabel;

  /// No description provided for @dietPlanKcalPerDay.
  ///
  /// In en, this message translates to:
  /// **'kcal/day'**
  String get dietPlanKcalPerDay;

  /// No description provided for @dietPlanRestrictionsTitle.
  ///
  /// In en, this message translates to:
  /// **'RESTRICTIONS'**
  String get dietPlanRestrictionsTitle;

  /// No description provided for @dietPlanMealFallback.
  ///
  /// In en, this message translates to:
  /// **'Meal'**
  String get dietPlanMealFallback;

  /// No description provided for @dietPlanRegenerate.
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get dietPlanRegenerate;

  /// No description provided for @dietPlanShoppingList.
  ///
  /// In en, this message translates to:
  /// **'Shopping list'**
  String get dietPlanShoppingList;

  /// No description provided for @mealScheduleBudgetSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget & Localization'**
  String get mealScheduleBudgetSectionTitle;

  /// No description provided for @mealScheduleBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Weekly Budget (optional)'**
  String get mealScheduleBudgetLabel;

  /// No description provided for @mealScheduleBudgetPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter weekly budget'**
  String get mealScheduleBudgetPlaceholder;

  /// No description provided for @mealScheduleBudgetHint.
  ///
  /// In en, this message translates to:
  /// **'Limits meal generation to recipes matching your budget.'**
  String get mealScheduleBudgetHint;

  /// No description provided for @mealScheduleCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Diaspora Region / Country'**
  String get mealScheduleCountryLabel;

  /// No description provided for @shoppingListTotalCost.
  ///
  /// In en, this message translates to:
  /// **'Total Cost'**
  String get shoppingListTotalCost;

  /// No description provided for @shoppingListCostPaid.
  ///
  /// In en, this message translates to:
  /// **'Cost Paid'**
  String get shoppingListCostPaid;

  /// No description provided for @shoppingListCostLeft.
  ///
  /// In en, this message translates to:
  /// **'Cost Left'**
  String get shoppingListCostLeft;

  /// No description provided for @feedTabByIngredients.
  ///
  /// In en, this message translates to:
  /// **'By Ingredients'**
  String get feedTabByIngredients;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
