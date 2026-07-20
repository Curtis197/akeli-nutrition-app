-- =============================================================================
-- AKELI V1 — Translation Seed Data
-- File: 02_translations.sql
-- Purpose: Seed initial UI translations for supported languages
-- =============================================================================

-- ---------------------------------------------------------------------------
-- SECTION 1 — TRANSLATION KEYS
-- ---------------------------------------------------------------------------

INSERT INTO app_translation_key (key_name, description) VALUES
-- Navigation
('nav.home', 'Home screen title'),
('nav.feed', 'Feed screen title'),
('nav.search', 'Search screen title'),
('nav.meal_plan', 'Meal Plan screen title'),
('nav.profile', 'Profile screen title'),
('nav.settings', 'Settings screen title'),

-- Home/Feed
('home.feed.title', 'Feed title'),
('home.feed.refresh', 'Pull to refresh'),
('home.feed.empty', 'No recipes found'),
('home.feed.loading', 'Loading recipes...'),

-- Recipe
('recipe.details.title', 'Recipe details'),
('recipe.details.ingredients', 'Ingredients'),
('recipe.details.instructions', 'Instructions'),
('recipe.details.nutrition', 'Nutrition Info'),
('recipe.details.prep_time', 'Prep Time'),
('recipe.details.cook_time', 'Cook Time'),
('recipe.details.servings', 'Servings'),
('recipe.details.difficulty', 'Difficulty'),
('recipe.details.calories', 'Calories'),
('recipe.details.protein', 'Protein'),
('recipe.details.carbs', 'Carbs'),
('recipe.details.fat', 'Fat'),
('recipe.details.add_to_plan', 'Add to Meal Plan'),
('recipe.details.share', 'Share Recipe'),
('recipe.details.like', 'Like'),
('recipe.details.unlike', 'Unlike'),
('recipe.details.comments', 'Comments'),
('recipe.details.add_comment', 'Add a comment'),

-- Search
('search.title', 'Search'),
('search.placeholder', 'Search recipes...'),
('search.filters', 'Filters'),
('search.filter.region', 'Region'),
('search.filter.difficulty', 'Difficulty'),
('search.filter.time', 'Max Time'),
('search.filter.tags', 'Tags'),
('search.results', 'Results'),
('search.no_results', 'No results found'),

-- Meal Plan
('meal_plan.title', 'Meal Plan'),
('meal_plan.generate', 'Generate Plan'),
('meal_plan.days', 'Days'),
('meal_plan.meals_per_day', 'Meals per Day'),
('meal_plan.start_date', 'Start Date'),
('meal_plan.shopping_list', 'Shopping List'),
('meal_plan.view_list', 'View Shopping List'),
('meal_plan.no_plan', 'No meal plan yet'),

-- Shopping List
('shopping_list.title', 'Shopping List'),
('shopping_list.items', 'Items'),
('shopping_list.quantity', 'Quantity'),
('shopping_list.unit', 'Unit'),
('shopping_list.category', 'Category'),
('shopping_list.check', 'Check'),
('shopping_list.uncheck', 'Uncheck'),

-- Profile
('profile.title', 'Profile'),
('profile.edit', 'Edit Profile'),
('profile.username', 'Username'),
('profile.email', 'Email'),
('profile.language', 'Language'),
('profile.preferences', 'Preferences'),
('profile.dietary_restrictions', 'Dietary Restrictions'),
('profile.favorite_regions', 'Favorite Regions'),
('profile.my_recipes', 'My Recipes'),
('profile.liked_recipes', 'Liked Recipes'),
('profile.logout', 'Logout'),

-- Settings
('settings.title', 'Settings'),
('settings.notifications', 'Notifications'),
('settings.privacy', 'Privacy'),
('settings.about', 'About'),
('settings.version', 'Version'),
('settings.language', 'Language'),

-- Auth
('auth.login', 'Login'),
('auth.signup', 'Sign Up'),
('auth.email', 'Email'),
('auth.password', 'Password'),
('auth.forgot_password', 'Forgot Password?'),
('auth.no_account', "Don't have an account?"),
('auth.have_account', 'Already have an account?'),
('auth.continue', 'Continue'),
('auth.or', 'OR'),

-- Common
('common.save', 'Save'),
('common.cancel', 'Cancel'),
('common.delete', 'Delete'),
('common.edit', 'Edit'),
('common.close', 'Close'),
('common.ok', 'OK'),
('common.yes', 'Yes'),
('common.no', 'No'),
('common.loading', 'Loading...'),
('common.error', 'Error'),
('common.success', 'Success'),
('common.retry', 'Retry'),

-- Difficulty levels
('difficulty.easy', 'Easy'),
('difficulty.medium', 'Medium'),
('difficulty.hard', 'Hard'),

-- Meal types
('meal_type.breakfast', 'Breakfast'),
('meal_type.lunch', 'Lunch'),
('meal_type.dinner', 'Dinner'),
('meal_type.snack', 'Snack'),

-- Dietary restrictions
('diet.vegetarian', 'Vegetarian'),
('diet.vegan', 'Vegan'),
('diet.pescatarian', 'Pescatarian'),
('diet.halal', 'Halal'),
('diet.kosher', 'Kosher'),
('diet.gluten_free', 'Gluten Free'),
('diet.lactose_free', 'Lactose Free'),
('diet.nut_free', 'Nut Free');

-- ---------------------------------------------------------------------------
-- SECTION 2 — FRENCH TRANSLATIONS (Default)
-- ---------------------------------------------------------------------------

INSERT INTO app_translation (translation_key_id, language_code, value)
SELECT id, 'fr', CASE key_name
  -- Navigation
  WHEN 'nav.home' THEN 'Accueil'
  WHEN 'nav.feed' THEN 'Fil d''actualité'
  WHEN 'nav.search' THEN 'Rechercher'
  WHEN 'nav.meal_plan' THEN 'Plan alimentaire'
  WHEN 'nav.profile' THEN 'Profil'
  WHEN 'nav.settings' THEN 'Paramètres'
  
  -- Home/Feed
  WHEN 'home.feed.title' THEN 'Recettes pour vous'
  WHEN 'home.feed.refresh' THEN 'Tirer pour rafraîchir'
  WHEN 'home.feed.empty' THEN 'Aucune recette trouvée'
  WHEN 'home.feed.loading' THEN 'Chargement des recettes...'
  
  -- Recipe
  WHEN 'recipe.details.title' THEN 'Détails de la recette'
  WHEN 'recipe.details.ingredients' THEN 'Ingrédients'
  WHEN 'recipe.details.instructions' THEN 'Instructions'
  WHEN 'recipe.details.nutrition' THEN 'Informations nutritionnelles'
  WHEN 'recipe.details.prep_time' THEN 'Temps de préparation'
  WHEN 'recipe.details.cook_time' THEN 'Temps de cuisson'
  WHEN 'recipe.details.servings' THEN 'Portions'
  WHEN 'recipe.details.difficulty' THEN 'Difficulté'
  WHEN 'recipe.details.calories' THEN 'Calories'
  WHEN 'recipe.details.protein' THEN 'Protéines'
  WHEN 'recipe.details.carbs' THEN 'Glucides'
  WHEN 'recipe.details.fat' THEN 'Lipides'
  WHEN 'recipe.details.add_to_plan' THEN 'Ajouter au plan'
  WHEN 'recipe.details.share' THEN 'Partager'
  WHEN 'recipe.details.like' THEN 'J''aime'
  WHEN 'recipe.details.unlike' THEN 'Je n''aime plus'
  WHEN 'recipe.details.comments' THEN 'Commentaires'
  WHEN 'recipe.details.add_comment' THEN 'Ajouter un commentaire'
  
  -- Search
  WHEN 'search.title' THEN 'Rechercher'
  WHEN 'search.placeholder' THEN 'Rechercher des recettes...'
  WHEN 'search.filters' THEN 'Filtres'
  WHEN 'search.filter.region' THEN 'Région'
  WHEN 'search.filter.difficulty' THEN 'Difficulté'
  WHEN 'search.filter.time' THEN 'Temps max'
  WHEN 'search.filter.tags' THEN 'Étiquettes'
  WHEN 'search.results' THEN 'Résultats'
  WHEN 'search.no_results' THEN 'Aucun résultat trouvé'
  
  -- Meal Plan
  WHEN 'meal_plan.title' THEN 'Plan alimentaire'
  WHEN 'meal_plan.generate' THEN 'Générer le plan'
  WHEN 'meal_plan.days' THEN 'Jours'
  WHEN 'meal_plan.meals_per_day' THEN 'Repas par jour'
  WHEN 'meal_plan.start_date' THEN 'Date de début'
  WHEN 'meal_plan.shopping_list' THEN 'Liste de courses'
  WHEN 'meal_plan.view_list' THEN 'Voir la liste'
  WHEN 'meal_plan.no_plan' THEN 'Aucun plan alimentaire'
  
  -- Shopping List
  WHEN 'shopping_list.title' THEN 'Liste de courses'
  WHEN 'shopping_list.items' THEN 'Articles'
  WHEN 'shopping_list.quantity' THEN 'Quantité'
  WHEN 'shopping_list.unit' THEN 'Unité'
  WHEN 'shopping_list.category' THEN 'Catégorie'
  WHEN 'shopping_list.check' THEN 'Cocher'
  WHEN 'shopping_list.uncheck' THEN 'Décocher'
  
  -- Profile
  WHEN 'profile.title' THEN 'Profil'
  WHEN 'profile.edit' THEN 'Modifier le profil'
  WHEN 'profile.username' THEN 'Nom d''utilisateur'
  WHEN 'profile.email' THEN 'Email'
  WHEN 'profile.language' THEN 'Langue'
  WHEN 'profile.preferences' THEN 'Préférences'
  WHEN 'profile.dietary_restrictions' THEN 'Restrictions alimentaires'
  WHEN 'profile.favorite_regions' THEN 'Régions favorites'
  WHEN 'profile.my_recipes' THEN 'Mes recettes'
  WHEN 'profile.liked_recipes' THEN 'Recettes aimées'
  WHEN 'profile.logout' THEN 'Déconnexion'
  
  -- Settings
  WHEN 'settings.title' THEN 'Paramètres'
  WHEN 'settings.notifications' THEN 'Notifications'
  WHEN 'settings.privacy' THEN 'Confidentialité'
  WHEN 'settings.about' THEN 'À propos'
  WHEN 'settings.version' THEN 'Version'
  WHEN 'settings.language' THEN 'Langue'
  
  -- Auth
  WHEN 'auth.login' THEN 'Connexion'
  WHEN 'auth.signup' THEN 'Inscription'
  WHEN 'auth.email' THEN 'Email'
  WHEN 'auth.password' THEN 'Mot de passe'
  WHEN 'auth.forgot_password' THEN 'Mot de passe oublié ?'
  WHEN 'auth.no_account' THEN 'Pas encore de compte ?'
  WHEN 'auth.have_account' THEN 'Déjà un compte ?'
  WHEN 'auth.continue' THEN 'Continuer'
  WHEN 'auth.or' THEN 'OU'
  
  -- Common
  WHEN 'common.save' THEN 'Enregistrer'
  WHEN 'common.cancel' THEN 'Annuler'
  WHEN 'common.delete' THEN 'Supprimer'
  WHEN 'common.edit' THEN 'Modifier'
  WHEN 'common.close' THEN 'Fermer'
  WHEN 'common.ok' THEN 'OK'
  WHEN 'common.yes' THEN 'Oui'
  WHEN 'common.no' THEN 'Non'
  WHEN 'common.loading' THEN 'Chargement...'
  WHEN 'common.error' THEN 'Erreur'
  WHEN 'common.success' THEN 'Succès'
  WHEN 'common.retry' THEN 'Réessayer'
  
  -- Difficulty
  WHEN 'difficulty.easy' THEN 'Facile'
  WHEN 'difficulty.medium' THEN 'Moyen'
  WHEN 'difficulty.hard' THEN 'Difficile'
  
  -- Meal types
  WHEN 'meal_type.breakfast' THEN 'Petit-déjeuner'
  WHEN 'meal_type.lunch' THEN 'Déjeuner'
  WHEN 'meal_type.dinner' THEN 'Dîner'
  WHEN 'meal_type.snack' THEN 'Collation'
  
  -- Dietary
  WHEN 'diet.vegetarian' THEN 'Végétarien'
  WHEN 'diet.vegan' THEN 'Végétalien'
  WHEN 'diet.pescatarian' THEN 'Pescétarien'
  WHEN 'diet.halal' THEN 'Halal'
  WHEN 'diet.kosher' THEN 'Cacher'
  WHEN 'diet.gluten_free' THEN 'Sans gluten'
  WHEN 'diet.lactose_free' THEN 'Sans lactose'
  WHEN 'diet.nut_free' THEN 'Sans noix'
  
  ELSE key_name
END
FROM app_translation_key;

-- ---------------------------------------------------------------------------
-- SECTION 3 — ENGLISH TRANSLATIONS
-- ---------------------------------------------------------------------------

INSERT INTO app_translation (translation_key_id, language_code, value)
SELECT id, 'en', CASE key_name
  -- Navigation
  WHEN 'nav.home' THEN 'Home'
  WHEN 'nav.feed' THEN 'Feed'
  WHEN 'nav.search' THEN 'Search'
  WHEN 'nav.meal_plan' THEN 'Meal Plan'
  WHEN 'nav.profile' THEN 'Profile'
  WHEN 'nav.settings' THEN 'Settings'
  
  -- Home/Feed
  WHEN 'home.feed.title' THEN 'Recipes for You'
  WHEN 'home.feed.refresh' THEN 'Pull to refresh'
  WHEN 'home.feed.empty' THEN 'No recipes found'
  WHEN 'home.feed.loading' THEN 'Loading recipes...'
  
  -- Recipe
  WHEN 'recipe.details.title' THEN 'Recipe Details'
  WHEN 'recipe.details.ingredients' THEN 'Ingredients'
  WHEN 'recipe.details.instructions' THEN 'Instructions'
  WHEN 'recipe.details.nutrition' THEN 'Nutrition Info'
  WHEN 'recipe.details.prep_time' THEN 'Prep Time'
  WHEN 'recipe.details.cook_time' THEN 'Cook Time'
  WHEN 'recipe.details.servings' THEN 'Servings'
  WHEN 'recipe.details.difficulty' THEN 'Difficulty'
  WHEN 'recipe.details.calories' THEN 'Calories'
  WHEN 'recipe.details.protein' THEN 'Protein'
  WHEN 'recipe.details.carbs' THEN 'Carbs'
  WHEN 'recipe.details.fat' THEN 'Fat'
  WHEN 'recipe.details.add_to_plan' THEN 'Add to Plan'
  WHEN 'recipe.details.share' THEN 'Share'
  WHEN 'recipe.details.like' THEN 'Like'
  WHEN 'recipe.details.unlike' THEN 'Unlike'
  WHEN 'recipe.details.comments' THEN 'Comments'
  WHEN 'recipe.details.add_comment' THEN 'Add a comment'
  
  -- Search
  WHEN 'search.title' THEN 'Search'
  WHEN 'search.placeholder' THEN 'Search recipes...'
  WHEN 'search.filters' THEN 'Filters'
  WHEN 'search.filter.region' THEN 'Region'
  WHEN 'search.filter.difficulty' THEN 'Difficulty'
  WHEN 'search.filter.time' THEN 'Max Time'
  WHEN 'search.filter.tags' THEN 'Tags'
  WHEN 'search.results' THEN 'Results'
  WHEN 'search.no_results' THEN 'No results found'
  
  -- Meal Plan
  WHEN 'meal_plan.title' THEN 'Meal Plan'
  WHEN 'meal_plan.generate' THEN 'Generate Plan'
  WHEN 'meal_plan.days' THEN 'Days'
  WHEN 'meal_plan.meals_per_day' THEN 'Meals per Day'
  WHEN 'meal_plan.start_date' THEN 'Start Date'
  WHEN 'meal_plan.shopping_list' THEN 'Shopping List'
  WHEN 'meal_plan.view_list' THEN 'View List'
  WHEN 'meal_plan.no_plan' THEN 'No meal plan yet'
  
  -- Shopping List
  WHEN 'shopping_list.title' THEN 'Shopping List'
  WHEN 'shopping_list.items' THEN 'Items'
  WHEN 'shopping_list.quantity' THEN 'Quantity'
  WHEN 'shopping_list.unit' THEN 'Unit'
  WHEN 'shopping_list.category' THEN 'Category'
  WHEN 'shopping_list.check' THEN 'Check'
  WHEN 'shopping_list.uncheck' THEN 'Uncheck'
  
  -- Profile
  WHEN 'profile.title' THEN 'Profile'
  WHEN 'profile.edit' THEN 'Edit Profile'
  WHEN 'profile.username' THEN 'Username'
  WHEN 'profile.email' THEN 'Email'
  WHEN 'profile.language' THEN 'Language'
  WHEN 'profile.preferences' THEN 'Preferences'
  WHEN 'profile.dietary_restrictions' THEN 'Dietary Restrictions'
  WHEN 'profile.favorite_regions' THEN 'Favorite Regions'
  WHEN 'profile.my_recipes' THEN 'My Recipes'
  WHEN 'profile.liked_recipes' THEN 'Liked Recipes'
  WHEN 'profile.logout' THEN 'Logout'
  
  -- Settings
  WHEN 'settings.title' THEN 'Settings'
  WHEN 'settings.notifications' THEN 'Notifications'
  WHEN 'settings.privacy' THEN 'Privacy'
  WHEN 'settings.about' THEN 'About'
  WHEN 'settings.version' THEN 'Version'
  WHEN 'settings.language' THEN 'Language'
  
  -- Auth
  WHEN 'auth.login' THEN 'Login'
  WHEN 'auth.signup' THEN 'Sign Up'
  WHEN 'auth.email' THEN 'Email'
  WHEN 'auth.password' THEN 'Password'
  WHEN 'auth.forgot_password' THEN 'Forgot Password?'
  WHEN 'auth.no_account' THEN 'Don''t have an account?'
  WHEN 'auth.have_account' THEN 'Already have an account?'
  WHEN 'auth.continue' THEN 'Continue'
  WHEN 'auth.or' THEN 'OR'
  
  -- Common
  WHEN 'common.save' THEN 'Save'
  WHEN 'common.cancel' THEN 'Cancel'
  WHEN 'common.delete' THEN 'Delete'
  WHEN 'common.edit' THEN 'Edit'
  WHEN 'common.close' THEN 'Close'
  WHEN 'common.ok' THEN 'OK'
  WHEN 'common.yes' THEN 'Yes'
  WHEN 'common.no' THEN 'No'
  WHEN 'common.loading' THEN 'Loading...'
  WHEN 'common.error' THEN 'Error'
  WHEN 'common.success' THEN 'Success'
  WHEN 'common.retry' THEN 'Retry'
  
  -- Difficulty
  WHEN 'difficulty.easy' THEN 'Easy'
  WHEN 'difficulty.medium' THEN 'Medium'
  WHEN 'difficulty.hard' THEN 'Hard'
  
  -- Meal types
  WHEN 'meal_type.breakfast' THEN 'Breakfast'
  WHEN 'meal_type.lunch' THEN 'Lunch'
  WHEN 'meal_type.dinner' THEN 'Dinner'
  WHEN 'meal_type.snack' THEN 'Snack'
  
  -- Dietary
  WHEN 'diet.vegetarian' THEN 'Vegetarian'
  WHEN 'diet.vegan' THEN 'Vegan'
  WHEN 'diet.pescatarian' THEN 'Pescatarian'
  WHEN 'diet.halal' THEN 'Halal'
  WHEN 'diet.kosher' THEN 'Kosher'
  WHEN 'diet.gluten_free' THEN 'Gluten Free'
  WHEN 'diet.lactose_free' THEN 'Lactose Free'
  WHEN 'diet.nut_free' THEN 'Nut Free'
  
  ELSE key_name
END
FROM app_translation_key;

-- ---------------------------------------------------------------------------
-- SECTION 4 — SPANISH TRANSLATIONS
-- ---------------------------------------------------------------------------

INSERT INTO app_translation (translation_key_id, language_code, value, is_machine_translated)
SELECT id, 'es', CASE key_name
  -- Navigation
  WHEN 'nav.home' THEN 'Inicio'
  WHEN 'nav.feed' THEN 'Feed'
  WHEN 'nav.search' THEN 'Buscar'
  WHEN 'nav.meal_plan' THEN 'Plan de Comidas'
  WHEN 'nav.profile' THEN 'Perfil'
  WHEN 'nav.settings' THEN 'Configuración'
  
  -- Home/Feed
  WHEN 'home.feed.title' THEN 'Recetas para ti'
  WHEN 'home.feed.refresh' THEN 'Tirar para actualizar'
  WHEN 'home.feed.empty' THEN 'No se encontraron recetas'
  WHEN 'home.feed.loading' THEN 'Cargando recetas...'
  
  -- Recipe
  WHEN 'recipe.details.title' THEN 'Detalles de la receta'
  WHEN 'recipe.details.ingredients' THEN 'Ingredientes'
  WHEN 'recipe.details.instructions' THEN 'Instrucciones'
  WHEN 'recipe.details.nutrition' THEN 'Información nutricional'
  WHEN 'recipe.details.prep_time' THEN 'Tiempo de preparación'
  WHEN 'recipe.details.cook_time' THEN 'Tiempo de cocción'
  WHEN 'recipe.details.servings' THEN 'Porciones'
  WHEN 'recipe.details.difficulty' THEN 'Dificultad'
  WHEN 'recipe.details.calories' THEN 'Calorías'
  WHEN 'recipe.details.protein' THEN 'Proteínas'
  WHEN 'recipe.details.carbs' THEN 'Carbohidratos'
  WHEN 'recipe.details.fat' THEN 'Grasas'
  WHEN 'recipe.details.add_to_plan' THEN 'Añadir al plan'
  WHEN 'recipe.details.share' THEN 'Compartir'
  WHEN 'recipe.details.like' THEN 'Me gusta'
  WHEN 'recipe.details.unlike' THEN 'Quitar me gusta'
  WHEN 'recipe.details.comments' THEN 'Comentarios'
  WHEN 'recipe.details.add_comment' THEN 'Añadir comentario'
  
  -- Search
  WHEN 'search.title' THEN 'Buscar'
  WHEN 'search.placeholder' THEN 'Buscar recetas...'
  WHEN 'search.filters' THEN 'Filtros'
  WHEN 'search.filter.region' THEN 'Región'
  WHEN 'search.filter.difficulty' THEN 'Dificultad'
  WHEN 'search.filter.time' THEN 'Tiempo máx'
  WHEN 'search.filter.tags' THEN 'Etiquetas'
  WHEN 'search.results' THEN 'Resultados'
  WHEN 'search.no_results' THEN 'No se encontraron resultados'
  
  -- Meal Plan
  WHEN 'meal_plan.title' THEN 'Plan de Comidas'
  WHEN 'meal_plan.generate' THEN 'Generar plan'
  WHEN 'meal_plan.days' THEN 'Días'
  WHEN 'meal_plan.meals_per_day' THEN 'Comidas por día'
  WHEN 'meal_plan.start_date' THEN 'Fecha de inicio'
  WHEN 'meal_plan.shopping_list' THEN 'Lista de compras'
  WHEN 'meal_plan.view_list' THEN 'Ver lista'
  WHEN 'meal_plan.no_plan' THEN 'Sin plan de comidas'
  
  -- Shopping List
  WHEN 'shopping_list.title' THEN 'Lista de compras'
  WHEN 'shopping_list.items' THEN 'Artículos'
  WHEN 'shopping_list.quantity' THEN 'Cantidad'
  WHEN 'shopping_list.unit' THEN 'Unidad'
  WHEN 'shopping_list.category' THEN 'Categoría'
  WHEN 'shopping_list.check' THEN 'Marcar'
  WHEN 'shopping_list.uncheck' THEN 'Desmarcar'
  
  -- Profile
  WHEN 'profile.title' THEN 'Perfil'
  WHEN 'profile.edit' THEN 'Editar perfil'
  WHEN 'profile.username' THEN 'Nombre de usuario'
  WHEN 'profile.email' THEN 'Correo'
  WHEN 'profile.language' THEN 'Idioma'
  WHEN 'profile.preferences' THEN 'Preferencias'
  WHEN 'profile.dietary_restrictions' THEN 'Restricciones dietéticas'
  WHEN 'profile.favorite_regions' THEN 'Regiones favoritas'
  WHEN 'profile.my_recipes' THEN 'Mis recetas'
  WHEN 'profile.liked_recipes' THEN 'Recetas guardadas'
  WHEN 'profile.logout' THEN 'Cerrar sesión'
  
  -- Settings
  WHEN 'settings.title' THEN 'Configuración'
  WHEN 'settings.notifications' THEN 'Notificaciones'
  WHEN 'settings.privacy' THEN 'Privacidad'
  WHEN 'settings.about' THEN 'Acerca de'
  WHEN 'settings.version' THEN 'Versión'
  WHEN 'settings.language' THEN 'Idioma'
  
  -- Auth
  WHEN 'auth.login' THEN 'Iniciar sesión'
  WHEN 'auth.signup' THEN 'Registrarse'
  WHEN 'auth.email' THEN 'Correo'
  WHEN 'auth.password' THEN 'Contraseña'
  WHEN 'auth.forgot_password' THEN '¿Olvidaste tu contraseña?'
  WHEN 'auth.no_account' THEN '¿No tienes cuenta?'
  WHEN 'auth.have_account' THEN '¿Ya tienes cuenta?'
  WHEN 'auth.continue' THEN 'Continuar'
  WHEN 'auth.or' THEN 'O'
  
  -- Common
  WHEN 'common.save' THEN 'Guardar'
  WHEN 'common.cancel' THEN 'Cancelar'
  WHEN 'common.delete' THEN 'Eliminar'
  WHEN 'common.edit' THEN 'Editar'
  WHEN 'common.close' THEN 'Cerrar'
  WHEN 'common.ok' THEN 'OK'
  WHEN 'common.yes' THEN 'Sí'
  WHEN 'common.no' THEN 'No'
  WHEN 'common.loading' THEN 'Cargando...'
  WHEN 'common.error' THEN 'Error'
  WHEN 'common.success' THEN 'Éxito'
  WHEN 'common.retry' THEN 'Reintentar'
  
  -- Difficulty
  WHEN 'difficulty.easy' THEN 'Fácil'
  WHEN 'difficulty.medium' THEN 'Medio'
  WHEN 'difficulty.hard' THEN 'Difícil'
  
  -- Meal types
  WHEN 'meal_type.breakfast' THEN 'Desayuno'
  WHEN 'meal_type.lunch' THEN 'Almuerzo'
  WHEN 'meal_type.dinner' THEN 'Cena'
  WHEN 'meal_type.snack' THEN 'Merienda'
  
  -- Dietary
  WHEN 'diet.vegetarian' THEN 'Vegetariano'
  WHEN 'diet.vegan' THEN 'Vegano'
  WHEN 'diet.pescatarian' THEN 'Pescetariano'
  WHEN 'diet.halal' THEN 'Halal'
  WHEN 'diet.kosher' THEN 'Kosher'
  WHEN 'diet.gluten_free' THEN 'Sin gluten'
  WHEN 'diet.lactose_free' THEN 'Sin lactosa'
  WHEN 'diet.nut_free' THEN 'Sin frutos secos'
  
  ELSE key_name
END, true
FROM app_translation_key;

-- ---------------------------------------------------------------------------
-- SECTION 5 — PORTUGUESE TRANSLATIONS
-- ---------------------------------------------------------------------------

INSERT INTO app_translation (translation_key_id, language_code, value, is_machine_translated)
SELECT id, 'pt', CASE key_name
  -- Navigation
  WHEN 'nav.home' THEN 'Início'
  WHEN 'nav.feed' THEN 'Feed'
  WHEN 'nav.search' THEN 'Pesquisar'
  WHEN 'nav.meal_plan' THEN 'Plano Alimentar'
  WHEN 'nav.profile' THEN 'Perfil'
  WHEN 'nav.settings' THEN 'Configurações'
  
  -- Home/Feed
  WHEN 'home.feed.title' THEN 'Receitas para você'
  WHEN 'home.feed.refresh' THEN 'Puxe para atualizar'
  WHEN 'home.feed.empty' THEN 'Nenhuma receita encontrada'
  WHEN 'home.feed.loading' THEN 'Carregando receitas...'
  
  -- Recipe
  WHEN 'recipe.details.title' THEN 'Detalhes da receita'
  WHEN 'recipe.details.ingredients' THEN 'Ingredientes'
  WHEN 'recipe.details.instructions' THEN 'Instruções'
  WHEN 'recipe.details.nutrition' THEN 'Informações nutricionais'
  WHEN 'recipe.details.prep_time' THEN 'Tempo de preparo'
  WHEN 'recipe.details.cook_time' THEN 'Tempo de cozimento'
  WHEN 'recipe.details.servings' THEN 'Porções'
  WHEN 'recipe.details.difficulty' THEN 'Dificuldade'
  WHEN 'recipe.details.calories' THEN 'Calorias'
  WHEN 'recipe.details.protein' THEN 'Proteínas'
  WHEN 'recipe.details.carbs' THEN 'Carboidratos'
  WHEN 'recipe.details.fat' THEN 'Gorduras'
  WHEN 'recipe.details.add_to_plan' THEN 'Adicionar ao plano'
  WHEN 'recipe.details.share' THEN 'Compartilhar'
  WHEN 'recipe.details.like' THEN 'Curtir'
  WHEN 'recipe.details.unlike' THEN 'Descurtir'
  WHEN 'recipe.details.comments' THEN 'Comentários'
  WHEN 'recipe.details.add_comment' THEN 'Adicionar comentário'
  
  -- Search
  WHEN 'search.title' THEN 'Pesquisar'
  WHEN 'search.placeholder' THEN 'Pesquisar receitas...'
  WHEN 'search.filters' THEN 'Filtros'
  WHEN 'search.filter.region' THEN 'Região'
  WHEN 'search.filter.difficulty' THEN 'Dificuldade'
  WHEN 'search.filter.time' THEN 'Tempo máx'
  WHEN 'search.filter.tags' THEN 'Tags'
  WHEN 'search.results' THEN 'Resultados'
  WHEN 'search.no_results' THEN 'Nenhum resultado encontrado'
  
  -- Meal Plan
  WHEN 'meal_plan.title' THEN 'Plano Alimentar'
  WHEN 'meal_plan.generate' THEN 'Gerar plano'
  WHEN 'meal_plan.days' THEN 'Dias'
  WHEN 'meal_plan.meals_per_day' THEN 'Refeições por dia'
  WHEN 'meal_plan.start_date' THEN 'Data de início'
  WHEN 'meal_plan.shopping_list' THEN 'Lista de compras'
  WHEN 'meal_plan.view_list' THEN 'Ver lista'
  WHEN 'meal_plan.no_plan' THEN 'Sem plano alimentar'
  
  -- Shopping List
  WHEN 'shopping_list.title' THEN 'Lista de compras'
  WHEN 'shopping_list.items' THEN 'Itens'
  WHEN 'shopping_list.quantity' THEN 'Quantidade'
  WHEN 'shopping_list.unit' THEN 'Unidade'
  WHEN 'shopping_list.category' THEN 'Categoria'
  WHEN 'shopping_list.check' THEN 'Marcar'
  WHEN 'shopping_list.uncheck' THEN 'Desmarcar'
  
  -- Profile
  WHEN 'profile.title' THEN 'Perfil'
  WHEN 'profile.edit' THEN 'Editar perfil'
  WHEN 'profile.username' THEN 'Nome de usuário'
  WHEN 'profile.email' THEN 'Email'
  WHEN 'profile.language' THEN 'Idioma'
  WHEN 'profile.preferences' THEN 'Preferências'
  WHEN 'profile.dietary_restrictions' THEN 'Restrições alimentares'
  WHEN 'profile.favorite_regions' THEN 'Regiões favoritas'
  WHEN 'profile.my_recipes' THEN 'Minhas receitas'
  WHEN 'profile.liked_recipes' THEN 'Receitas curtidas'
  WHEN 'profile.logout' THEN 'Sair'
  
  -- Settings
  WHEN 'settings.title' THEN 'Configurações'
  WHEN 'settings.notifications' THEN 'Notificações'
  WHEN 'settings.privacy' THEN 'Privacidade'
  WHEN 'settings.about' THEN 'Sobre'
  WHEN 'settings.version' THEN 'Versão'
  WHEN 'settings.language' THEN 'Idioma'
  
  -- Auth
  WHEN 'auth.login' THEN 'Entrar'
  WHEN 'auth.signup' THEN 'Cadastrar'
  WHEN 'auth.email' THEN 'Email'
  WHEN 'auth.password' THEN 'Senha'
  WHEN 'auth.forgot_password' THEN 'Esqueceu a senha?'
  WHEN 'auth.no_account' THEN 'Não tem conta?'
  WHEN 'auth.have_account' THEN 'Já tem conta?'
  WHEN 'auth.continue' THEN 'Continuar'
  WHEN 'auth.or' THEN 'OU'
  
  -- Common
  WHEN 'common.save' THEN 'Salvar'
  WHEN 'common.cancel' THEN 'Cancelar'
  WHEN 'common.delete' THEN 'Excluir'
  WHEN 'common.edit' THEN 'Editar'
  WHEN 'common.close' THEN 'Fechar'
  WHEN 'common.ok' THEN 'OK'
  WHEN 'common.yes' THEN 'Sim'
  WHEN 'common.no' THEN 'Não'
  WHEN 'common.loading' THEN 'Carregando...'
  WHEN 'common.error' THEN 'Erro'
  WHEN 'common.success' THEN 'Sucesso'
  WHEN 'common.retry' THEN 'Tentar novamente'
  
  -- Difficulty
  WHEN 'difficulty.easy' THEN 'Fácil'
  WHEN 'difficulty.medium' THEN 'Médio'
  WHEN 'difficulty.hard' THEN 'Difícil'
  
  -- Meal types
  WHEN 'meal_type.breakfast' THEN 'Café da manhã'
  WHEN 'meal_type.lunch' THEN 'Almoço'
  WHEN 'meal_type.dinner' THEN 'Jantar'
  WHEN 'meal_type.snack' THEN 'Lanche'
  
  -- Dietary
  WHEN 'diet.vegetarian' THEN 'Vegetariano'
  WHEN 'diet.vegan' THEN 'Vegano'
  WHEN 'diet.pescatarian' THEN 'Pescetariano'
  WHEN 'diet.halal' THEN 'Halal'
  WHEN 'diet.kosher' THEN 'Kosher'
  WHEN 'diet.gluten_free' THEN 'Sem glúten'
  WHEN 'diet.lactose_free' THEN 'Sem lactose'
  WHEN 'diet.nut_free' THEN 'Sem nozes'
  
  ELSE key_name
END, true
FROM app_translation_key;
