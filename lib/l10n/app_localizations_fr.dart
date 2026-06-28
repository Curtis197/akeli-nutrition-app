// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Akeli';

  @override
  String get appVersion => 'Akeli V1.0';

  @override
  String get notificationSeeLabel => 'Voir';

  @override
  String get notificationDefaultTitle => 'Nouvelle notification';

  @override
  String get navHome => 'Accueil';

  @override
  String get navMeals => 'Repas';

  @override
  String get navRecipes => 'Recettes';

  @override
  String get navCommunity => 'Communauté';

  @override
  String get tooltipSettings => 'Paramètres';

  @override
  String get tooltipNotifications => 'Notifications';

  @override
  String get authWelcome => 'Bienvenue sur Akeli';

  @override
  String get authSignUp => 'S\'inscrire';

  @override
  String get authLogIn => 'Se connecter';

  @override
  String get authCreateAccount => 'Créer votre compte';

  @override
  String get authJoinCommunity => 'Rejoignez la communauté Akeli';

  @override
  String get authEmailPlaceholder => 'Entrez votre email';

  @override
  String get authEmailRequired => 'Email requis';

  @override
  String get authEmailInvalid => 'Email invalide';

  @override
  String get authPasswordCreate => 'Créez un mot de passe';

  @override
  String get authPasswordRequired => 'Mot de passe requis';

  @override
  String get authPasswordMinLength => 'Minimum 8 caractères';

  @override
  String get authConfirmPassword => 'Confirmez le mot de passe';

  @override
  String get authPasswordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get authGetStarted => 'Commencer';

  @override
  String get authWelcomeBack => 'Heureux de vous revoir !';

  @override
  String get authSignInToAccount => 'Connectez-vous à votre compte';

  @override
  String get authEmailField => 'Email';

  @override
  String get authPasswordField => 'Mot de passe';

  @override
  String get authPasswordReset =>
      'Réinitialisation du mot de passe — bientôt disponible';

  @override
  String get authForgotPassword => 'Mot de passe oublié ?';

  @override
  String get authSignIn => 'Se connecter';

  @override
  String get authErrorInvalidCredentials => 'Email ou mot de passe incorrect.';

  @override
  String get authErrorEmailInUse => 'Cet email est déjà utilisé.';

  @override
  String get authErrorPasswordShort =>
      'Le mot de passe doit contenir au moins 6 caractères.';

  @override
  String get authErrorEmailNotConfirmed =>
      'Veuillez confirmer votre adresse email avant de vous connecter.';

  @override
  String get authErrorGeneric => 'Une erreur est survenue. Réessayez.';

  @override
  String homeGreeting(String name) {
    return 'Bonjour, $name !';
  }

  @override
  String get homeGreetingFallback => 'Bonjour !';

  @override
  String get homeWelcomeBack => 'Heureux de vous revoir.';

  @override
  String get homeWeightLabel => 'Poids';

  @override
  String get homeWeightCurrent => 'Poids actuel';

  @override
  String get homeCaloriesLabel => 'Calories';

  @override
  String get homeViewProgress => 'Voir mes progrès →';

  @override
  String get homeTodayMeals => 'Vos repas du jour';

  @override
  String get homeNoMealsToday => 'Aucun repas planifié pour aujourd\'hui.';

  @override
  String get homeMealDefault => 'Repas';

  @override
  String get homeMealUpdateError =>
      'Impossible de mettre à jour le repas. Réessayez.';

  @override
  String get homeShoppingList => 'Liste de courses';

  @override
  String get homeViewAll => 'Voir tout';

  @override
  String get homeFilterAll => 'Tout';

  @override
  String get homeFilterToBuy => 'À acheter';

  @override
  String get homeFilterBought => 'Déjà acheté';

  @override
  String get homeNoItemsFound => 'Aucun article trouvé';

  @override
  String get homeRecommendedRecipes => 'Recettes recommandées';

  @override
  String get homeNoRecipes => 'Aucune recette disponible.';

  @override
  String homeErrorGeneric(String error) {
    return 'Erreur : $error';
  }

  @override
  String get homeCreatorsForYou => 'Créateurs pour vous';

  @override
  String get homeCreateRecipe => 'Créez et partagez vos propre recette';

  @override
  String get feedTitle => 'Découvrir';

  @override
  String get feedSearchHint => 'Rechercher des recettes...';

  @override
  String get feedTabRecipes => 'Recettes';

  @override
  String get feedTabCreators => 'Créateurs';

  @override
  String get feedNoResults => 'Aucun résultat';

  @override
  String get feedNoResultsSubtitle => 'Essayez d\'autres termes ou filtres';

  @override
  String get feedEmptyTitle => 'Aucune recette';

  @override
  String get feedFilters => 'Filtres';

  @override
  String get feedFilterRegion => 'Région';

  @override
  String get feedFilterDifficulty => 'Difficulté';

  @override
  String get feedFilterTime => 'Temps max';

  @override
  String get feedFilterMealType => 'Type de repas';

  @override
  String get feedFilterCalories => 'Calories';

  @override
  String get feedSortBy => 'Trier par';

  @override
  String get feedAllRegions => 'Toutes les régions';

  @override
  String get feedAllDifficulties => 'Toutes les difficultés';

  @override
  String get feedAllMealTypes => 'Tous les types';

  @override
  String get feedApplyFilters => 'Appliquer';

  @override
  String get feedResetFilters => 'Réinitialiser';

  @override
  String get feedLoadMore => 'Charger plus';

  @override
  String get feedCreatorSearch => 'Rechercher des créateurs...';

  @override
  String get feedCreatorSpecialty => 'Spécialité';

  @override
  String get feedNoCreators => 'Aucun créateur trouvé';

  @override
  String get feedAddToMealPlan => 'Ajouter au plan';

  @override
  String get feedAddedToMealPlan => 'Ajouté au plan';

  @override
  String get feedSwapRecipe => 'Échanger';

  @override
  String get feedSwapDone => 'Recette échangée';

  @override
  String get recipeDetailIngredients => 'Ingrédients';

  @override
  String get recipeDetailInstructions => 'Instructions';

  @override
  String get recipeDetailNutrition => 'Informations nutritionnelles';

  @override
  String get recipeDetailPrepTime => 'Temps de préparation';

  @override
  String get recipeDetailCookTime => 'Temps de cuisson';

  @override
  String get recipeDetailServings => 'Portions';

  @override
  String get recipeDetailDifficulty => 'Difficulté';

  @override
  String get recipeDetailCalories => 'Calories';

  @override
  String get recipeDetailProtein => 'Protéines';

  @override
  String get recipeDetailCarbs => 'Glucides';

  @override
  String get recipeDetailFat => 'Lipides';

  @override
  String get recipeDetailSave => 'Sauvegarder';

  @override
  String get recipeDetailSaved => 'Sauvegardé';

  @override
  String get recipeDetailLike => 'J\'aime';

  @override
  String get recipeDetailShare => 'Partager';

  @override
  String get recipeDetailComments => 'Commentaires';

  @override
  String get recipeDetailNoComments => 'Aucun commentaire';

  @override
  String get recipeDetailAddComment => 'Ajouter un commentaire...';

  @override
  String get recipeDetailSendComment => 'Envoyer';

  @override
  String get recipeDetailLoadError => 'Erreur de chargement';

  @override
  String get recipeDetailMin => 'min';

  @override
  String get recipeDetailPer100g => 'pour 100g';

  @override
  String recipeDetailStepLabel(int step) {
    return 'Étape $step';
  }

  @override
  String get recipeDetailRegion => 'Région';

  @override
  String get recipeDetailTags => 'Tags';

  @override
  String get recipeDetailVideoTitle => 'Vidéo de la recette';

  @override
  String get recipeDetailAddToMealPlan => 'Ajouter au plan';

  @override
  String get recipeDetailAddedToMealPlan => 'Ajouté à votre plan';

  @override
  String get recipeDetailErrorAddPlan => 'Erreur lors de l\'ajout au plan';

  @override
  String get recipeDetailBy => 'par';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileDefaultName => 'Utilisateur';

  @override
  String profileLoadError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get profilePrivateTitle => 'Ce profil est privé';

  @override
  String get profilePrivateMessage => 'Envoyez un message pour vous connecter.';

  @override
  String get profileTabRecipes => 'Recettes';

  @override
  String get profileTabComments => 'Commentaires';

  @override
  String get profileTabGroups => 'Groupes';

  @override
  String get profileLoadError2 => 'Erreur de chargement';

  @override
  String get profileNoLikedRecipes => 'Aucune recette aimée';

  @override
  String get profileNoComments => 'Aucun commentaire';

  @override
  String get profileNoGroups => 'Aucun groupe';

  @override
  String get profileUnknownRecipe => 'Recette inconnue';

  @override
  String get profileGroupDefault => 'Groupe';

  @override
  String profileMemberCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membres',
      one: '$count membre',
    );
    return '$_temp0';
  }

  @override
  String get profileStartConversation => 'Démarrer une conversation';

  @override
  String get profileMessageSent => 'Demande envoyée';

  @override
  String get profileMessageError => 'Erreur lors de l\'envoi de la demande';

  @override
  String get profilePending => 'En attente';

  @override
  String get profileMessage => 'Message';

  @override
  String get profileCloseConversationTitle => 'Fermer la conversation ?';

  @override
  String get profileCloseConversationContent =>
      'Vous quitterez cette conversation. L\'autre utilisateur gardera son historique.';

  @override
  String get profileConversationClosed => 'Conversation fermée';

  @override
  String get profileCloseError => 'Erreur lors de la fermeture';

  @override
  String get settingsTitle => 'Paramètres';

  @override
  String get settingsEdit => 'Modifier';

  @override
  String get settingsPremium => 'Premium';

  @override
  String get settingsSectionMenu => 'Menu';

  @override
  String get settingsNutritionTracking => 'Suivi nutritionnel';

  @override
  String get settingsSavedRecipes => 'Recettes Sauvegardées';

  @override
  String get settingsAccount => 'Mon compte';

  @override
  String get settingsFanMode => 'Mode Fan';

  @override
  String get settingsPreferences => 'Préférences';

  @override
  String get settingsHealthGoals => 'Santé & Objectifs';

  @override
  String get settingsSectionApp => 'Application';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsLanguage => 'Langue';

  @override
  String get settingsLanguageCurrent => 'Français';

  @override
  String get settingsSectionPrivacy => 'Confidentialité';

  @override
  String get settingsPrivateProfile => 'Profil privé';

  @override
  String get settingsSectionSupport => 'Support';

  @override
  String get settingsHelpFaq => 'Aide & FAQ';

  @override
  String get settingsPrivacyPolicy => 'Politique de confidentialité';

  @override
  String get settingsTerms => 'Conditions d\'utilisation';

  @override
  String get settingsSignOut => 'Se déconnecter';

  @override
  String get settingsSignOutTitle => 'Se déconnecter';

  @override
  String get settingsSignOutConfirm =>
      'Voulez-vous vraiment vous déconnecter ?';

  @override
  String get settingsSignOutConfirmBtn => 'Déconnecter';

  @override
  String get settingsEditProfile => 'Modifier le profil';

  @override
  String get settingsName => 'Nom';

  @override
  String get settingsDescription => 'Description';

  @override
  String get settingsDescriptionHint => 'Parlez-nous un peu de vous...';

  @override
  String get settingsSave => 'Enregistrer';

  @override
  String settingsAvatarError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get mealPlannerTitle => 'Vos repas';

  @override
  String get mealPlannerWeekTitle => 'Vos repas de la semaine';

  @override
  String get mealPlannerDaysTitle => 'Vos repas des prochains jours';

  @override
  String get mealPlannerViewDietPlan => 'Voir mon plan diététique';

  @override
  String get mealPlannerViewShoppingList => 'Voir ma liste de course';

  @override
  String get mealPlannerViewBatchCooking => 'Cuisine en lot';

  @override
  String get mealPlannerEmpty => 'Aucun plan alimentaire';

  @override
  String get mealPlannerEmptySubtitle => 'Générer un plan personnalisé';

  @override
  String get mealPlannerGenerate => 'Générer mon plan';

  @override
  String mealPlannerError(String error) {
    return 'Erreur : $error';
  }

  @override
  String get mealPlannerConsumptionError =>
      'Impossible de mettre à jour. Réessayez.';

  @override
  String get mealTypeBreakfast => 'Petit-déjeuner';

  @override
  String get mealTypeLunch => 'Déjeuner';

  @override
  String get mealTypeDinner => 'Dîner';

  @override
  String get mealTypeSnack => 'Collation';

  @override
  String get nutritionTitle => 'Nutrition';

  @override
  String get nutritionTabToday => 'Aujourd\'hui';

  @override
  String get nutritionTabWeek => 'Semaine';

  @override
  String get nutritionTabJourney => 'Parcours';

  @override
  String get nutritionCalories => 'Calories';

  @override
  String get nutritionProtein => 'Protéines';

  @override
  String get nutritionCarbs => 'Glucides';

  @override
  String get nutritionFat => 'Lipides';

  @override
  String get nutritionNoData => 'Aucune donnée nutritionnelle aujourd\'hui';

  @override
  String get nutritionNoPlan => 'Aucun plan nutritionnel';

  @override
  String get nutritionGoal => 'Objectif';

  @override
  String get nutritionConsumed => 'Consommé';

  @override
  String get nutritionRemaining => 'Restant';

  @override
  String get nutritionWeightTracking => 'Suivi du poids';

  @override
  String get nutritionCurrentWeight => 'Poids actuel';

  @override
  String get nutritionTargetWeight => 'Poids cible';

  @override
  String get nutritionAddWeight => 'Enregistrer le poids';

  @override
  String get nutritionWeightAdded => 'Poids enregistré';

  @override
  String get communityTitle => 'Communauté';

  @override
  String get communityMyGroups => 'Mes groupes';

  @override
  String get communityPrivateGroups => 'Privés';

  @override
  String get communityPublicGroups => 'Publics';

  @override
  String get communityDiscoverGroups => 'Découvrir des groupes';

  @override
  String get communityNoGroups => 'Aucun groupe';

  @override
  String get communityCreateGroup => 'Créer';

  @override
  String get communityJoinSuccess => 'Groupe rejoint avec succès';

  @override
  String get communityJoinError => 'Erreur lors de l\'adhésion';

  @override
  String get communityRegionFilter => 'Région';

  @override
  String get communityAllRegions => 'Toutes les régions';

  @override
  String get communityRegionError => 'Erreur régions';

  @override
  String get communityNoCriteria =>
      'Aucun groupe ne correspond à ces critères.';

  @override
  String get communityGroupImageError =>
      'Erreur lors de la sélection de l\'image';

  @override
  String get communityGeneralChannel => 'Général';

  @override
  String get communitySending => 'Envoi en cours…';

  @override
  String get cookingModeTitle => 'Mode Cuisine';

  @override
  String cookingModeStep(int step, int total) {
    return 'Étape $step sur $total';
  }

  @override
  String get cookingModeIngredients => 'Ingrédients';

  @override
  String get cookingModeTimer => 'Minuteur';

  @override
  String get cookingModeComplete => 'Recette terminée !';

  @override
  String get cookingModeStart => 'Commencer la cuisson';

  @override
  String get dietPlanTitle => 'Plan diététique';

  @override
  String get dietPlanNoPlan => 'Aucun plan diététique';

  @override
  String get dietPlanCalorieGoal => 'Objectif calorique';

  @override
  String get dietPlanProteinGoal => 'Objectif protéines';

  @override
  String get dietPlanCarbGoal => 'Objectif glucides';

  @override
  String get dietPlanFatGoal => 'Objectif lipides';

  @override
  String get dietPlanWeeks => 'Durée (semaines)';

  @override
  String get dietPlanActivity => 'Niveau d\'activité';

  @override
  String get shoppingListTitle => 'Liste de courses';

  @override
  String get shoppingListEmpty => 'Votre liste de courses est vide';

  @override
  String shoppingListItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count articles',
      one: '$count article',
    );
    return '$_temp0';
  }

  @override
  String get shoppingListAll => 'Tous';

  @override
  String get shoppingListChecked => 'Coché';

  @override
  String get shoppingListRemaining => 'Restants';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'Aucune notification';

  @override
  String get notificationsMarkAllRead => 'Tout marquer comme lu';

  @override
  String get accountTitle => 'Mon compte';

  @override
  String get accountEmail => 'Email';

  @override
  String get accountDeleteAccount => 'Supprimer le compte';

  @override
  String get accountDeleteConfirmTitle => 'Supprimer le compte';

  @override
  String get accountDeleteConfirmContent =>
      'Cette action est irréversible. Toutes vos données seront supprimées.';

  @override
  String get accountChangePassword => 'Changer le mot de passe';

  @override
  String get accountInfoSection => 'INFORMATIONS';

  @override
  String get accountPasswordSection => 'MOT DE PASSE';

  @override
  String get accountCurrentPassword => 'Mot de passe actuel';

  @override
  String get accountNewPassword => 'Nouveau mot de passe';

  @override
  String get accountConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get accountUpdatePassword => 'Mettre à jour';

  @override
  String get accountDangerZone => 'ZONE DANGEREUSE';

  @override
  String get accountPasswordRequired => 'Veuillez remplir tous les champs.';

  @override
  String get accountPasswordTooShort =>
      'Le mot de passe doit contenir au moins 8 caractères.';

  @override
  String get accountPasswordMismatch =>
      'Les mots de passe ne correspondent pas.';

  @override
  String get accountPasswordUpdated => 'Mot de passe mis à jour avec succès.';

  @override
  String get accountDeleteError =>
      'Erreur lors de la suppression. Veuillez réessayer.';

  @override
  String get accountErrorInvalidPassword => 'Mot de passe actuel incorrect.';

  @override
  String get accountErrorTooManyRequests =>
      'Trop de tentatives. Veuillez patienter.';

  @override
  String get accountErrorGeneric =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get healthProfileTitle => 'Santé & Objectifs';

  @override
  String get healthProfileAge => 'Âge';

  @override
  String get healthProfileWeight => 'Poids (kg)';

  @override
  String get healthProfileHeight => 'Taille (cm)';

  @override
  String get healthProfileGender => 'Sexe';

  @override
  String get healthProfileActivity => 'Niveau d\'activité';

  @override
  String get healthProfileGoal => 'Objectif';

  @override
  String get healthProfileTargetWeight => 'Poids cible (kg)';

  @override
  String get healthProfileSave => 'Enregistrer';

  @override
  String get healthProfileSaved => 'Profil santé enregistré';

  @override
  String get healthProfileError => 'Erreur lors de l\'enregistrement';

  @override
  String get healthParamsSection => 'PARAMÈTRES DE SANTÉ';

  @override
  String get healthSex => 'Sexe';

  @override
  String get healthBirthDate => 'Date de naissance';

  @override
  String get healthBirthDateEmpty => 'Non renseignée';

  @override
  String get healthHeight => 'Taille';

  @override
  String get healthCurrentWeight => 'Poids actuel';

  @override
  String get healthTargetWeight => 'Poids cible';

  @override
  String get healthActivityLevel => 'Niveau d\'activité';

  @override
  String get healthGoalSection => 'OBJECTIF';

  @override
  String get healthGoalType => 'Type d\'objectif';

  @override
  String get healthWeightGoal => 'Objectif poids';

  @override
  String get healthMuscleGoal => 'Objectif muscle';

  @override
  String get healthTargetDuration => 'Durée cible';

  @override
  String healthWeeks(int count) {
    return '$count semaines';
  }

  @override
  String healthWeeksShort(int count) {
    return '$count sem.';
  }

  @override
  String get healthActivitySedentary => 'Sédentaire';

  @override
  String get healthActivityLight => 'Légèrement actif';

  @override
  String get healthActivityModerate => 'Modérément actif';

  @override
  String get healthActivityActive => 'Actif';

  @override
  String get healthActivityVeryActive => 'Très actif';

  @override
  String get healthGoalWeightLoss => 'Perte de poids';

  @override
  String get healthGoalMuscleGain => 'Prise de muscle';

  @override
  String get healthGoalMaintenance => 'Maintien';

  @override
  String get healthGoalHealth => 'Santé';

  @override
  String get healthGoalPerformance => 'Performance';

  @override
  String get healthGoalLose => 'Perdre';

  @override
  String get healthGoalMaintain => 'Maintenir';

  @override
  String get healthGoalGain => 'Prendre';

  @override
  String get healthSexMale => 'Homme';

  @override
  String get healthSexFemale => 'Femme';

  @override
  String get healthSexOther => 'Autre';

  @override
  String get notifSettingsIntro =>
      'Configurez vos préférences pour rester connecté sans être submergé.';

  @override
  String get notifPushLabel => 'Notifications Push';

  @override
  String get notifPushSubtitle =>
      'Recevez vos notifications sur votre appareil';

  @override
  String get notifChatLabel => 'Chat';

  @override
  String get notifChatSubtitle => 'Messages et conversations';

  @override
  String get notifMealLabel => 'Rappels de repas';

  @override
  String get notifMealSubtitle => 'Heures de repas planifiés';

  @override
  String get notifDmLabel => 'Demandes de conversation';

  @override
  String get notifDmSubtitle => 'Nouvelles demandes de connexion';

  @override
  String get notifLoadError => 'Impossible de charger les préférences.';

  @override
  String get preferencesTitle => 'Préférences';

  @override
  String get preferencesDiet => 'Régime';

  @override
  String get preferencesAllergens => 'Allergies & Intolérances';

  @override
  String get preferencesFavoriteRegions => 'Régions favorites';

  @override
  String get preferencesSave => 'Enregistrer';

  @override
  String get preferencesSaved => 'Préférences enregistrées';

  @override
  String get preferencesError => 'Erreur lors de l\'enregistrement';

  @override
  String get preferencesMealPlanSection => 'PLAN DE REPAS';

  @override
  String get preferencesMealPlanFromFavorites => 'Générer depuis les favoris';

  @override
  String get preferencesMealPlanFromFavoritesDesc =>
      'Utiliser uniquement vos recettes enregistrées';

  @override
  String get preferencesCookingSection => 'CUISSON';

  @override
  String get preferencesCookingTimeLabel => 'Temps de préparation';

  @override
  String get preferencesCookingTimeQuick => 'Rapide (< 30 min)';

  @override
  String get preferencesCookingTimeMedium => 'Moyen (30–60 min)';

  @override
  String get preferencesCookingTimeAny => 'Peu importe';

  @override
  String get preferencesBatchCookingLabel => 'Cuisson en batch';

  @override
  String get preferencesBatchCookingDesc =>
      'Préparer plusieurs repas à la fois';

  @override
  String get preferencesBatchCookingDetail =>
      'Cuire en grande quantité pour la semaine';

  @override
  String get preferencesBatchPortions => 'Portions max par session';

  @override
  String get preferencesCuisineSection => 'RÉGION CULINAIRE';

  @override
  String get preferencesRegionWestAfrica => 'Afrique de l\'Ouest';

  @override
  String get preferencesRegionEastAfrica => 'Afrique de l\'Est';

  @override
  String get preferencesRegionNorthAfrica => 'Afrique du Nord';

  @override
  String get preferencesRegionCentralAfrica => 'Afrique Centrale';

  @override
  String get preferencesRegionSouthAfrica => 'Afrique du Sud';

  @override
  String get preferencesRegionCaribbean => 'Caraïbes';

  @override
  String get preferencesRegionWestern => 'Occidental';

  @override
  String get preferencesDietSection => 'RESTRICTIONS ALIMENTAIRES';

  @override
  String get preferencesNoPork => 'Sans porc';

  @override
  String get preferencesNoMeat => 'Sans viande';

  @override
  String get preferencesNoGluten => 'Sans gluten';

  @override
  String get preferencesNoLactose => 'Sans lactose';

  @override
  String get notificationSettingsTitle => 'Notifications';

  @override
  String get notificationSettingsMealReminders => 'Rappels repas';

  @override
  String get notificationSettingsNewRecipes => 'Nouvelles recettes';

  @override
  String get notificationSettingsCommunity => 'Communauté';

  @override
  String get notificationSettingsSave => 'Enregistrer';

  @override
  String get savedRecipesTitle => 'Recettes Sauvegardées';

  @override
  String get savedRecipesEmpty => 'Aucune recette sauvegardée';

  @override
  String get savedRecipesEmptySubtitle =>
      'Sauvegardez des recettes pour les retrouver facilement';

  @override
  String get fanModeTitle => 'Mode Fan';

  @override
  String get fanModeSubscribe => 'S\'abonner';

  @override
  String get fanModeUnsubscribe => 'Se désabonner';

  @override
  String get fanModeMyCreators => 'Mes créateurs';

  @override
  String get fanModeNoCreators => 'Aucun créateur suivi';

  @override
  String get subscriptionTitle => 'Passer Premium';

  @override
  String get subscriptionSubtitle => 'Déverrouillez toutes les fonctionnalités';

  @override
  String get subscriptionMonthly => 'Mensuel';

  @override
  String get subscriptionAnnual => 'Annuel';

  @override
  String get subscriptionSubscribe => 'S\'abonner';

  @override
  String get referralTitle => 'Parrainer un ami';

  @override
  String get referralCopyCode => 'Copier le code';

  @override
  String get referralCodeCopied => 'Code copié !';

  @override
  String get supportTitle => 'Aide & FAQ';

  @override
  String get aiAssistantTitle => 'Assistant IA';

  @override
  String get aiAssistantPlaceholder =>
      'Posez-moi une question sur la nutrition...';

  @override
  String get aiAssistantSend => 'Envoyer';

  @override
  String get batchCookingTitle => 'Cuisine en lot';

  @override
  String get batchCookingEmpty => 'Aucune session de cuisine en lot';

  @override
  String get ratingTitle => 'Évaluer ce repas';

  @override
  String get ratingSubmit => 'Valider';

  @override
  String get ratingSkip => 'Passer';

  @override
  String get journeyTitle => 'Mon Parcours';

  @override
  String journeyStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours de suite',
      one: '$count jour de suite',
    );
    return '$_temp0';
  }

  @override
  String get journeyNoData => 'Commencez votre parcours aujourd\'hui';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonOk => 'OK';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonDelete => 'Supprimer';

  @override
  String get commonEdit => 'Modifier';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonRetry => 'Réessayer';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonError => 'Erreur';

  @override
  String get commonSuccess => 'Succès';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonPrevious => 'Précédent';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonYes => 'Oui';

  @override
  String get commonNo => 'Non';

  @override
  String get difficultyEasy => 'Facile';

  @override
  String get difficultyMedium => 'Moyen';

  @override
  String get difficultyHard => 'Difficile';

  @override
  String get dietVegetarian => 'Végétarien';

  @override
  String get dietVegan => 'Végétalien';

  @override
  String get dietPescatarian => 'Pescétarien';

  @override
  String get dietHalal => 'Halal';

  @override
  String get dietKosher => 'Cacher';

  @override
  String get dietGlutenFree => 'Sans gluten';

  @override
  String get dietLactoseFree => 'Sans lactose';

  @override
  String get dietNutFree => 'Sans noix';

  @override
  String get languageSelectorTitle => 'Choisir la langue';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageFrench => 'Français';

  @override
  String get onboardingWelcome => 'Bienvenue sur Akeli';

  @override
  String get onboardingSubtitle => 'Personnalisons votre expérience';

  @override
  String get onboardingAge => 'Quel est votre âge ?';

  @override
  String get onboardingEstimatedDeadline => 'DÉLAI ESTIMÉ';

  @override
  String get onboardingBatchPrepMeals => 'Préparer plusieurs repas à la fois';

  @override
  String get onboardingBatchCookWeek =>
      'Cuire en grande quantité pour la semaine';

  @override
  String get onboardingPreferences => 'Vos préférences';

  @override
  String get onboardingPreferencesSubtitle =>
      'Personnalisons votre expérience culinaire.';

  @override
  String get onboardingDietLabel => 'Régime alimentaire';

  @override
  String get onboardingAllergens => 'Allergies & Intolérances';

  @override
  String get onboardingAllergensHint => 'Ajoutez les ingrédients à éviter.';

  @override
  String get onboardingSummary => 'Récapitulatif';

  @override
  String get onboardingSummarySubtitle =>
      'Votre profil est prêt. Vérifions les détails avant de commencer.';

  @override
  String get onboardingDietaryPreferences => 'Préférences alimentaires';

  @override
  String get feedSortBestRated => 'Mieux noté';

  @override
  String get feedSortPopular => 'Populaire';

  @override
  String get feedSortNewest => 'Plus récent';

  @override
  String feedFilterTimeMax(int min) {
    return '< $min min';
  }

  @override
  String get onboardingSkip => 'Passer';

  @override
  String onboardingStep(int current, int total) {
    return 'Étape $current sur $total';
  }

  @override
  String get onboardingBack => 'Précédent';

  @override
  String get onboardingNext => 'Suivant';

  @override
  String get onboardingFinish => 'Commencer l\'aventure';

  @override
  String get onboardingProfileTitle => 'Votre profil';

  @override
  String get onboardingDisplayNameHint => 'Comment vous appelez-vous ?';

  @override
  String get onboardingActivityTitle => 'Niveau d\'activité physique';

  @override
  String get mealDetailNotFound => 'Repas introuvable';

  @override
  String get mealDetailConsumed => 'Repas consommé';

  @override
  String get mealDetailMarkConsumed => 'Marquer comme consommé';

  @override
  String get mealDetailDescription => 'Description';

  @override
  String get mealDetailSwapRecipe => 'Changer la recette';

  @override
  String get mealDetailPersonalMeal => 'Repas personnel (IA)';

  @override
  String get mealDetailConsumeFirst => 'Consommez d\'abord ce repas';

  @override
  String get mealDetailEditReview => 'Modifier votre avis';

  @override
  String get mealDetailLeaveReview => 'Laisser un avis';

  @override
  String get mealDetailViewFullRecipe => 'Voir la recette complète';

  @override
  String get mealDetailBatchPrep => 'Préparation batch';

  @override
  String get mealDetailBatchSession => 'Session de cuisine batch';

  @override
  String get recipeDetailTotalRecipe => 'Recette totale';

  @override
  String get recipeDetailPerServing => 'Par portion';

  @override
  String get recipeDetailReviews => 'Avis';

  @override
  String get recipeDetailRatingTaste => 'Goût';

  @override
  String get recipeDetailRatingEase => 'Facilité';

  @override
  String get recipeDetailRatingSatiety => 'Satiété';

  @override
  String get batchCookingThisWeek => 'Cette semaine';

  @override
  String get batchCookingOngoing => 'Vos préparations en cours';

  @override
  String get batchCookingNoSessionsTitle => 'Aucune session cette semaine';

  @override
  String get batchCookingNoSessionsBody =>
      'Vos sessions batch apparaîtront ici automatiquement quand une recette est planifiée plusieurs fois.';

  @override
  String get batchCookingDefaultRecipe => 'Recette';

  @override
  String get batchDetailPreparation => 'Préparation';

  @override
  String get batchDetailPortionsUsed => 'Portions utilisées';

  @override
  String batchDetailPortionsUsedCount(int count) {
    return '$count utilisées';
  }

  @override
  String get batchDetailStartCooking => 'Commencer la cuisson';

  @override
  String get commonAdd => 'Ajouter';

  @override
  String get mealPlannerAddSnack => 'Ajouter une collation';

  @override
  String get mealPlannerAddAnotherSnack => 'Ajouter une autre collation';

  @override
  String get snackPickerTitle => 'Choisir une collation';

  @override
  String get snackPickerEstimatedQty => 'Quantité estimée';

  @override
  String get snackPickerPersonal => 'Collation personnelle';

  @override
  String get snackPickerNoResults => 'Aucune recette trouvée';

  @override
  String get fanModeLoadError => 'Erreur de chargement';

  @override
  String get fanModeCreatorsTitle => 'Créateurs à soutenir';

  @override
  String get fanModeCreatorsSubtitle =>
      'Votre créateur dominant est mis en avant.';

  @override
  String get fanModeNoCreatorsTitle => 'Aucun créateur éligible';

  @override
  String get fanModeNoCreatorsSubtitle =>
      'Les créateurs doivent publier 30 recettes pour être éligibles.';

  @override
  String get fanModeActivateTitle => 'Activer le Mode Fan';

  @override
  String fanModeActivateContent(String name) {
    return 'Vous allez soutenir $name avec 1€/mois, inclus dans votre abonnement Akeli.\n\nRègle 90/10 : 90% de vos repas devront venir du catalogue de ce créateur (max 9 recettes externes par mois).\n\nActif à partir du 1er du mois prochain.';
  }

  @override
  String get fanModeConfirm => 'Confirmer';

  @override
  String get fanModeActivateError => 'Erreur lors de l\'activation.';

  @override
  String fanModeActivateSuccess(String name) {
    return 'Vous soutenez maintenant $name !';
  }

  @override
  String get fanModeRecipesThisMonth => 'Vos recettes ce mois';

  @override
  String get fanModeNoRecipesThisMonth => 'Aucune recette enregistrée ce mois';

  @override
  String fanModeTotalMeals(int count) {
    return '$count repas enregistrés';
  }

  @override
  String fanModeRecipeCount(int count) {
    return '$count recettes';
  }

  @override
  String fanModeFanCount(int count) {
    return '$count fans';
  }

  @override
  String get fanModeSupport => 'Soutenir';

  @override
  String get fanModeQuit => 'Quitter le Mode Fan';

  @override
  String get fanModeQuitContent =>
      'Votre soutien se terminera à la fin du mois en cours.';

  @override
  String get fanModeKeep => 'Garder';

  @override
  String get fanModeQuitConfirm => 'Quitter';

  @override
  String get fanModeCancelled => 'Mode Fan annulé.';

  @override
  String get fanModeStatusPending => '⏳ Actif le 1er du mois prochain';

  @override
  String get fanModeStatusActive => '❤️ Mode Fan actif';

  @override
  String get fanModeExternalTitle => 'Recettes externes ce mois';

  @override
  String get fanModeExternalSubtitle => 'Recettes hors catalogue';

  @override
  String get fanModeEngagementTitle => 'Engagement Mode Fan';

  @override
  String get fanModeEngagementYouSupport => 'Vous soutenez ';

  @override
  String get fanModeEngagementWith => ' avec ';

  @override
  String get fanModeEngagementGuaranteed => '1€/mois garanti';

  @override
  String get fanModeEngagementIncluded =>
      ', inclus dans votre abonnement.\n\nRègle 90/10 : 90% de vos repas doivent venir du catalogue de ce créateur. Vous pouvez utiliser jusqu\'à ';

  @override
  String get fanModeEngagementExternalCount => '9 recettes externes';

  @override
  String get fanModeEngagementPerMonth => ' par mois.';

  @override
  String get fanModeDefaultCreator => 'votre créateur';

  @override
  String get commonLoadError => 'Erreur de chargement';

  @override
  String get commonGenericError =>
      'Une erreur est survenue. Veuillez réessayer.';

  @override
  String get groupDetailTitle => 'Détail du groupe';

  @override
  String get groupDetailUnknownGroup => 'Groupe inconnu';

  @override
  String get groupDetailTabMembers => 'Membres';

  @override
  String get groupDetailTabPhotos => 'Photos';

  @override
  String get groupDetailTabRecipes => 'Recettes';

  @override
  String get groupDetailDmAlreadySent => 'Demande déjà envoyée';

  @override
  String groupDetailDmSentTo(String name) {
    return 'Demande envoyée à $name';
  }

  @override
  String groupDetailExcludeTitle(String name) {
    return 'Exclure $name ?';
  }

  @override
  String get groupDetailExcludeContent =>
      'Cette personne perdra l\'accès au groupe et au chat de groupe.';

  @override
  String get groupDetailExclude => 'Exclure';

  @override
  String get groupDetailMemberExcluded => 'Membre exclu du groupe';

  @override
  String get groupDetailNotAdmin =>
      'Vous n\'êtes plus administrateur de ce groupe';

  @override
  String get groupDetailInvite => 'Inviter';

  @override
  String get groupDetailNoMembersTitle => 'Aucun membre';

  @override
  String get groupDetailNoMembersSubtitle => 'Les membres apparaîtront ici.';

  @override
  String get groupDetailNoPhotosTitle => 'Aucune photo partagée';

  @override
  String get groupDetailNoPhotosSubtitle =>
      'Les photos envoyées dans le chat apparaîtront ici.';

  @override
  String get groupDetailNoRecipesTitle => 'Aucune recette partagée';

  @override
  String get groupDetailNoRecipesSubtitle =>
      'Les recettes partagées dans le chat apparaîtront ici.';

  @override
  String get groupDetailInvitesSent => 'Invitations envoyées';

  @override
  String get groupDetailInviteTitle => 'Inviter des membres';

  @override
  String get groupDetailNoEligibleTitle => 'Aucun contact éligible';

  @override
  String get groupDetailNoEligibleSubtitle =>
      'Vous n\'avez pas encore de conversations privées avec des utilisateurs à inviter.';

  @override
  String groupDetailInviteCount(int count) {
    return 'Inviter ($count)';
  }

  @override
  String get groupDetailPrivateMessage => 'Message privé';

  @override
  String get groupDetailExcludeFromGroup => 'Exclure du groupe';

  @override
  String get allergenPickerHint => 'Ex: arachides, noix...';

  @override
  String allergenPickerAdd(String query) {
    return 'Ajouter \"$query\"';
  }

  @override
  String get allergenPickerSuggestionSent =>
      'Suggestion envoyée pour révision.';

  @override
  String get ingredientDetailOptional => 'Optionnel';

  @override
  String get ingredientDetailTagHighProtein => 'Riche en protéines';

  @override
  String get ingredientDetailTagLowFat => 'Pauvre en graisses';

  @override
  String get ingredientDetailTagGlutenFree => 'Sans gluten';

  @override
  String get ingredientDetailTagAfricanStaple => 'Aliment de base';

  @override
  String get ingredientDetailTagHardToFindEu => 'Difficile à trouver en Europe';

  @override
  String get ingredientDetailNutritionTitle => 'Valeurs nutritives (pour 100g)';

  @override
  String get ingredientDetailEnergy => 'Énergie';

  @override
  String get cookingSessionTitle => 'Session de cuisine';

  @override
  String get cookingSessionSubtitle => 'Organisez vos repas de la semaine';

  @override
  String get cookingSessionComingSoon => 'Bientôt disponible';

  @override
  String get cookingSessionComingSoonDesc =>
      'Cette fonctionnalité sera disponible dans une prochaine mise à jour';

  @override
  String get cookingSessionGotIt => 'Compris';

  @override
  String get journeyCalendarLegendAll => 'Tous';

  @override
  String get journeyCalendarLegendPartial => 'Partiel';

  @override
  String get journeyCalendarLegendNone => 'Aucun';

  @override
  String get journeySummaryDays => 'Jours de parcours';

  @override
  String get journeySummaryTracked => 'Jours suivis';

  @override
  String get journeySummaryMeals => 'Repas consommés';

  @override
  String get journeySummaryConsistency => 'Régularité';

  @override
  String get journeyGoalsWeight => '⚖️  Poids';

  @override
  String get journeyGoalsCalories => '🎯  Calories';

  @override
  String get journeyGoalsProtein => '💪  Protéines';

  @override
  String get journeyGoalsCarbs => '🌾  Glucides';

  @override
  String get journeyGoalsFat => '🥑  Lipides';

  @override
  String journeyGoalsCalorieHitSubtitle(int pct) {
    return 'Vous avez atteint votre objectif calorique $pct% des jours logués.';
  }

  @override
  String get subscriptionMyTitle => 'Mon abonnement';

  @override
  String get subscriptionActiveTitle => 'Abonnement actif';

  @override
  String get subscriptionPremiumBadge => 'Akeli Premium';

  @override
  String get subscriptionActiveThankYou =>
      'Merci de faire partie de la communauté Akeli.';

  @override
  String get subscriptionTagline => 'Nutrition africaine personnalisée';

  @override
  String get subscriptionIncludedTitle => 'Ce qui est inclus';

  @override
  String get subscriptionPerMonth => '/ mois';

  @override
  String get subscriptionCancelAnytime =>
      'Annulable à tout moment via le Store';

  @override
  String get subscriptionSubscribeViaStore => 'S\'abonner via le Store';

  @override
  String get subscriptionMobileOnly =>
      'Abonnement disponible sur iOS et Android uniquement.';

  @override
  String get subscriptionFeature1 =>
      'Recettes africaines personnalisées avec IA';

  @override
  String get subscriptionFeature2 => 'Plan alimentaire hebdomadaire adapté';

  @override
  String get subscriptionFeature3 => 'Suivi nutritionnel détaillé';

  @override
  String get subscriptionFeature4 => 'Assistant IA nutritionnel';

  @override
  String get subscriptionFeature5 => 'Mode Fan — soutenez vos créateurs';

  @override
  String get subscriptionFeature6 => 'Communauté et groupes de discussion';

  @override
  String get subscriptionFeature7 => 'Liste de courses automatique';

  @override
  String get subscriptionActiveBadge => 'Abonnement Premium actif';

  @override
  String subscriptionRenewalDate(String date) {
    return 'Prochain renouvellement : $date';
  }

  @override
  String get subscriptionPlatformIos => 'Abonnement via App Store';

  @override
  String get subscriptionPlatformAndroid => 'Abonnement via Google Play';

  @override
  String get journalingNewEntry => 'Nouvelle entrée';

  @override
  String get journalingNewEntrySubtitle => 'Notez votre expérience culinaire';

  @override
  String get journalingPhotos => 'Photos';

  @override
  String get journalingAddPhotos => 'Ajouter des photos';

  @override
  String get journalingMealType => 'Type de repas';

  @override
  String get journalingDescription => 'Description';

  @override
  String get journalingDescriptionHint =>
      'Comment s\'est passé ce repas? Goûts, textures, émotions...';

  @override
  String get journalingDescriptionRequired =>
      'Veuillez ajouter une description';

  @override
  String get journalingSaving => 'Enregistrement...';

  @override
  String get journalingSaveEntry => 'Enregistrer l\'entrée';

  @override
  String get journalingEntrySaved => 'Entrée enregistrée avec succès!';

  @override
  String get journalingSaveError => 'Erreur lors de l\'enregistrement';

  @override
  String get aiAssistantOnline => 'En ligne';

  @override
  String get aiAssistantNewConversation => 'Nouvelle conversation';

  @override
  String get aiAssistantToday => 'AUJOURD\'HUI';

  @override
  String get aiAssistantError =>
      'Désolé, une erreur est survenue. Réessayez dans un moment.';

  @override
  String get aiAssistantWelcomeTitle =>
      'Bonjour, je suis votre assistant nutritionnel Akeli.';

  @override
  String get aiAssistantWelcomeSubtitle =>
      'Posez-moi vos questions sur la nutrition, les recettes africaines ou votre plan alimentaire.';

  @override
  String get aiAssistantSuggestions => 'Suggestions';

  @override
  String get aiAssistantMessageHint => 'Message...';

  @override
  String get aiAssistantSuggestion1 =>
      'Quels aliments riches en protéines pour ma culture ?';

  @override
  String get aiAssistantSuggestion2 =>
      'Quel est mon apport calorique recommandé ?';

  @override
  String get aiAssistantSuggestion3 =>
      'Comment perdre du poids avec la cuisine africaine ?';

  @override
  String get aiAssistantSuggestion4 => 'Donne-moi une recette pour ce soir.';

  @override
  String get referralCodeLabel => 'Votre code de parrainage';

  @override
  String referralReferreeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count filleuls',
      one: '$count filleul',
    );
    return '$_temp0';
  }

  @override
  String get referralShareTitle => 'Partagez l\'Oasis';

  @override
  String get referralShareBody =>
      'Invitez vos amis à découvrir Akeli Oasis. Pour chaque ami qui s\'inscrit avec votre code, vous recevrez une invitation à un rituel de bien-être exclusif, et ils bénéficieront d\'un accueil privilégié.';

  @override
  String get referralChangeCodeTitle => 'Changer de code';

  @override
  String get referralEditCode => 'Modifier le code';

  @override
  String get referralNewCodeLabel => 'Nouveau code';

  @override
  String get referralNewCodeHint => 'Entrez un nouveau code';

  @override
  String get referralCodeUpdated => 'Code mis à jour avec succès!';

  @override
  String get supportHeaderTitle => 'Comment pouvons-nous vous aider?';

  @override
  String get supportHeaderSubtitle =>
      'Notre équipe est là pour répondre à vos questions';

  @override
  String get supportSubjectLabel => 'Sujet';

  @override
  String get supportSubjectHint => 'Ex: Problème de connexion...';

  @override
  String get supportSubjectRequired => 'Veuillez entrer un sujet';

  @override
  String get supportEmailHint => 'votre@email.com';

  @override
  String get supportEmailRequired => 'Veuillez entrer votre email';

  @override
  String get supportEmailInvalid => 'Veuillez entrer un email valide';

  @override
  String get supportMessageLabel => 'Message';

  @override
  String get supportMessageHint => 'Décrivez votre problème...';

  @override
  String get supportMessageRequired => 'Veuillez entrer votre message';

  @override
  String get supportMessageTooShort =>
      'Le message doit contenir au moins 10 caractères';

  @override
  String get supportAddScreenshot => 'Ajouter une capture d\'écran';

  @override
  String get supportSendMessage => 'Envoyer le message';

  @override
  String get supportMessageSent => 'Message envoyé avec succès!';

  @override
  String get supportSendError => 'Erreur lors de l\'envoi. Veuillez réessayer.';

  @override
  String get supportChangeScreenshot => 'Changer la capture';

  @override
  String get savedRecipesEligibilityNotLoggedIn => 'Non connecté';

  @override
  String get savedRecipesEligibilityNoData => 'Aucune donnée trouvée';

  @override
  String get savedRecipesEligibilityTitle => 'Générer avec vos favoris';

  @override
  String get savedRecipesEligibilityDesc =>
      'Si vous avez suffisamment de recettes enregistrées, vous pouvez demander à Akeli de générer vos plans de repas uniquement à partir de vos favoris, plutôt que via nos recommandations.';

  @override
  String get savedRecipesEligibilityProgress => 'Progression';

  @override
  String savedRecipesEligibilityMissing(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il manque $count recettes',
      one: 'Il manque $count recette',
    );
    return '$_temp0';
  }

  @override
  String get savedRecipesEligibilityToggleTitle =>
      'Utiliser uniquement les favoris';

  @override
  String get savedRecipesEligibilityEnabled => 'Activé';

  @override
  String get savedRecipesEligibilityBlocked =>
      'Bloqué: Vous devez atteindre 7 recettes pour chaque catégorie ci-dessus.';

  @override
  String get legalPrivacyTitle => 'Politique de Confidentialité';

  @override
  String get legalPrivacyHeroTitle => 'Vos données sont protégées';

  @override
  String get legalPrivacyHeroSubtitle =>
      'Nous nous engageons à protéger votre vie privée conformément au RGPD';

  @override
  String get legalPrivacySummaryTitle => 'En bref';

  @override
  String get legalPrivacyCollectionTitle => 'Collecte minimale';

  @override
  String get legalPrivacyCollectionDesc =>
      'Seules les données nécessaires au fonctionnement de l\'application';

  @override
  String get legalPrivacySecurityTitle => 'Sécurité maximale';

  @override
  String get legalPrivacySecurityDesc =>
      'Chiffrement de bout en bout et stockage sécurisé';

  @override
  String get legalPrivacyControlTitle => 'Contrôle total';

  @override
  String get legalPrivacyControlDesc =>
      'Vous pouvez accéder, modifier ou supprimer vos données à tout moment';

  @override
  String get legalPrivacySection1Title => '1. Collecte de données';

  @override
  String get legalPrivacySection1Content =>
      'Nous collectons uniquement les données nécessaires pour vous offrir la meilleure expérience :\n\n• Informations de profil (nom, email, préférences alimentaires)\n• Historique de navigation dans l\'application\n• Données de santé que vous choisissez de partager\n• Préférences de contenu et interactions';

  @override
  String get legalPrivacySection2Title => '2. Utilisation des données';

  @override
  String get legalPrivacySection2Content =>
      'Vos données nous permettent de :\n\n• Personnaliser vos recommandations de recettes\n• Améliorer continuellement notre service\n• Vous envoyer des notifications pertinentes\n• Assurer la sécurité de votre compte';

  @override
  String get legalPrivacySection3Title => '3. Vos droits RGPD';

  @override
  String get legalPrivacyRightAccess => 'Accès';

  @override
  String get legalPrivacyRightAccessDesc => 'Consulter vos données';

  @override
  String get legalPrivacyRightRectification => 'Rectification';

  @override
  String get legalPrivacyRightRectificationDesc => 'Modifier vos informations';

  @override
  String get legalPrivacyRightErasure => 'Effacement';

  @override
  String get legalPrivacyRightErasureDesc => 'Supprimer votre compte';

  @override
  String get legalPrivacyRightPortability => 'Portabilité';

  @override
  String get legalPrivacyRightPortabilityDesc => 'Exporter vos données';

  @override
  String get legalPrivacySection4Title => '4. Partage des données';

  @override
  String get legalPrivacySection4Content =>
      'Nous ne vendons jamais vos données personnelles.\n\nElles peuvent être partagées uniquement avec :\n• Nos prestataires techniques hébergés en UE\n• Les autorités légales si requis par la loi\n• Vos créateurs favoris (uniquement avec votre consentement explicite)';

  @override
  String get legalPrivacySection5Title => '5. Conservation';

  @override
  String get legalPrivacySection5Content =>
      'Vos données sont conservées :\n• Tant que votre compte est actif\n• Jusqu\'à 3 ans après votre dernière connexion\n• Immédiatement supprimées après demande de suppression de compte';

  @override
  String get legalPrivacyDpoTitle => 'Contact DPO';

  @override
  String get legalPrivacyDpoEmail => 'dpo@akeli.app';

  @override
  String get legalPrivacyDpoDesc =>
      'Notre délégué à la protection des données répond sous 48h ouvrées à toute demande concernant vos données personnelles.';

  @override
  String get legalPrivacyVersion =>
      'Version 1.0 • Dernière mise à jour: Janvier 2026';

  @override
  String get legalTermsTitle => 'Conditions Générales';

  @override
  String get legalTermsHeroTitle => 'Bienvenue sur Akeli';

  @override
  String get legalTermsHeroSubtitle =>
      'En utilisant notre application, vous acceptez ces conditions';

  @override
  String get legalTermsArticle1Title => 'Accès au service';

  @override
  String get legalTermsArticle1Content =>
      'Akeli est une application mobile gratuite dédiée à la nutrition africaine et aux recettes traditionnelles.\n\nL\'accès au service nécessite :\n• Un smartphone compatible iOS ou Android\n• Une connexion internet pour synchroniser les données\n• La création d\'un compte utilisateur\n\nCertaines fonctionnalités premium (Fan Mode, plans personnalisés) sont accessibles via abonnement.';

  @override
  String get legalTermsArticle2Title => 'Compte utilisateur';

  @override
  String get legalTermsArticle2Content =>
      'Vous êtes responsable de :\n• La confidentialité de vos identifiants\n• L\'exactitude des informations fournies\n• Toutes les activités effectuées depuis votre compte\n\nNous nous réservons le droit de suspendre ou supprimer tout compte en cas de violation des présentes conditions.';

  @override
  String get legalTermsArticle3Title => 'Propriété intellectuelle';

  @override
  String get legalTermsArticle3Content =>
      'Tous les contenus présents sur Akeli (recettes, textes, images, logos) sont la propriété exclusive d\'Akeli ou de ses partenaires.\n\nInterdictions :\n• Reproduction sans autorisation\n• Utilisation commerciale non autorisée\n• Modification ou altération des contenus\n\nLes créateurs conservent les droits sur leurs recettes publiées.';

  @override
  String get legalTermsArticle4Title => 'Responsabilité';

  @override
  String get legalTermsArticle4Content =>
      'Akeli fournit des informations nutritionnelles à titre indicatif uniquement.\n\nNous ne pouvons être tenus responsables :\n• Des erreurs dans les informations nutritionnelles\n• Des réactions allergiques ou problèmes de santé liés aux recettes\n• Des interruptions temporaires du service pour maintenance\n\nConsultez toujours un professionnel de santé pour des conseils médicaux.';

  @override
  String get legalTermsArticle5Title => 'Abonnements et paiements';

  @override
  String get legalTermsArticle5Content =>
      'Les abonnements Fan Mode (€3/mois) sont facturés mensuellement via les stores (Google Play / App Store).\n\n• Résiliation possible à tout moment\n• Accès maintenu jusqu\'à la fin de période payée\n• Aucun remboursement partiel\n\nLes créateurs reçoivent 70% des revenus générés par leurs abonnés.';

  @override
  String get legalTermsArticle6Title => 'Modifications';

  @override
  String get legalTermsArticle6Content =>
      'Nous nous réservons le droit de modifier ces conditions à tout moment.\n\nLes utilisateurs seront notifiés :\n• Par notification push pour changements majeurs\n• Par email si modification impacte les données personnelles\n\nLa poursuite de l\'utilisation vaut acceptation des nouvelles conditions.';

  @override
  String get legalTermsContactTitle => 'Contact';

  @override
  String get legalTermsContactEmail => 'legal@akeli.app';

  @override
  String get legalTermsVersion =>
      'Version 1.0 • Dernière mise à jour: Janvier 2026';
}
