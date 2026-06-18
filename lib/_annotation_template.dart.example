// =============================================================================
// AKELI - Flutter Component Annotation Template
// =============================================================================
// 
// PURPOSE: Every page, widget, provider, and service MUST be annotated with:
//   - ROLE: What it does in the system
//   - PURPOSE: Why it exists, the problem it solves
//   - USAGE: How it's used, who calls it
//   - DATA SOURCE: Where its data comes from (provider, RPC, Edge Function, local)
//   - NAVIGATION: What screens it navigates to
//   - DEPENDENCIES: What providers/services it relies on
//   - NOTES: Important caveats, performance considerations
// 
// This template shows the REQUIRED annotation format.
// Copy this pattern to EVERY Flutter file you create.
// =============================================================================

// -----------------------------------------------------------------------------
// EXAMPLE: Recipe Detail Page (fully annotated)
// -----------------------------------------------------------------------------

// ROLE: Recipe detail screen - displays full recipe information with interactions
// PURPOSE: Show complete recipe details including steps, nutrition, creator info.
//          Allow users to like, save, share, and navigate to creator profile.
// USAGE: Accessed from feed (recipe card tap), search results, meal plan detail,
//        or deep link (/recipes/:recipeId).
// DATA SOURCE:
//   - Recipe detail: recipeDetailProvider(recipeId) → RPC or direct query
//   - Like status: recipeLikedProvider(recipeId) → direct table query
//   - Creator info: creatorProfileProvider(creatorId) → RPC get_creator_public_profile
//   - Current user: currentUserProvider → auth state
// NAVIGATION:
//   - onTap creator → CreatorProfilePage(creatorId)
//   - onTap share → System share dialog
//   - onTap save → Toggles via recipeSaveProvider
// DEPENDENCIES:
//   - recipeDetailProvider (data)
//   - recipeLikedProvider (like state)
//   - recipeSaveProvider (save state)
//   - currentUserProvider (auth context)
// NOTES:
//   - All complex data comes from backend (JOINs, aggregations via RPC)
//   - Like/save are simple single-table operations (client-side OK)
//   - Recipe steps are ordered by step_number (indexed)
//   - Impression tracked on view, open tracked on mount/close

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logger.dart';
// ... other imports

/// Recipe detail page controller
/// 
/// ROLE: Orchestrates recipe detail page data loading and user actions
/// PURPOSE: Fetch recipe data, track impressions/opens, handle like/save
/// USAGE: Created by RecipeDetailPage, manages lifecycle of data fetching
class RecipeDetailController {
  final WidgetRef ref;
  final String recipeId;
  final _logger = appLogger;

  RecipeDetailController({required this.ref, required this.recipeId}) {
    _logger.d('📍 ENTRY: RecipeDetailController created | recipeId: $recipeId');
  }

  /// Track recipe impression (card was seen)
  /// 
  /// ROLE: Analytics - record passive view signal
  /// PURPOSE: Track recipe visibility for creator analytics
  /// USAGE: Called when recipe card becomes visible in viewport
  /// DATA: Inserts into recipe_impression table (simple single-table insert)
  void trackImpression({required String source}) {
    _logger.d('📡 DB: trackImpression() | recipeId: $recipeId | source: $source | userId: ${_currentUserId}');
    // Insert to recipe_impression table
    // Simple single-table operation - OK on client
  }

  /// Track recipe open (user tapped into detail)
  /// 
  /// ROLE: Analytics - record intentional engagement
  /// PURPOSE: Track recipe opens with session duration
  /// USAGE: Called on page mount, closed on dispose
  /// DATA: Inserts into recipe_open, updates closed_at + duration on dispose
  void trackOpen({required String source}) {
    _logger.d('📡 DB: trackOpen() | recipeId: $recipeId | source: $source');
    // Insert into recipe_open with opened_at
  }

  /// Track recipe close (session duration)
  /// 
  /// ROLE: Analytics - complete open session
  /// PURPOSE: Calculate and save session duration
  /// USAGE: Called on page dispose
  void trackClose() {
    final duration = DateTime.now().difference(_openTime!);
    _logger.d('📡 DB: trackClose() | recipeId: $recipeId | duration: ${duration.inSeconds}s');
    // Update recipe_open with closed_at and session_duration_seconds
  }

  String? get _currentUserId => ref.read(currentUserProvider)?.id;
  DateTime? _openTime;
}

/// Recipe detail page
/// 
/// ROLE: Full recipe detail screen
/// PURPOSE: Display recipe with steps, nutrition, creator info, and actions
/// See class annotation above for full details
class RecipeDetailPage extends ConsumerWidget {
  /// ROLE: Recipe identifier - which recipe to display
  /// PURPOSE: Route parameter passed to this page
  final String recipeId;

  const RecipeDetailPage({super.key, required this.recipeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = appLogger;
    logger.d('🎯 UI: RecipeDetailPage.build() | recipeId: $recipeId | evaluating state');

    final recipeState = ref.watch(recipeDetailProvider(recipeId));
    logger.d('🔄 STATE: RecipeDetailPage watching recipeDetailProvider | isLoading: ${recipeState.isLoading} | hasError: ${recipeState.hasError}');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipe Detail'),
        actions: [
          _buildShareButton(context, ref),
          _buildSaveButton(ref),
        ],
      ),
      body: recipeState.when(
        loading: () {
          logger.d('🎯 UI: Rendering loading state | recipeId: $recipeId');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, st) {
          logger.e('🎯 UI: Rendering error state | recipeId: $recipeId | error: $error', error: error, stackTrace: st);
          return _buildErrorView(error);
        },
        data: (recipe) {
          logger.d('🎯 UI: Rendering recipe data | recipeId: ${recipe.id} | title: ${recipe.title} | steps: ${recipe.steps.length}');
          return _buildRecipeContent(context, ref, recipe);
        },
      ),
    );
  }

  /// Share button
  /// 
  /// ROLE: Trigger system share dialog
  /// PURPOSE: Allow user to share recipe externally
  /// USAGE: Tapped from app bar
  Widget _buildShareButton(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.share),
      onPressed: () {
        appLogger.i('🎯 UI: Share button tapped | recipeId: $recipeId | screen: RecipeDetailPage');
        // Share logic here
      },
    );
  }

  /// Save button
  /// 
  /// ROLE: Toggle recipe bookmark
  /// PURPOSE: Let user save recipe for later
  /// USAGE: Tapped from app bar
  /// DATA: Simple single-table insert/delete on recipe_save table
  Widget _buildSaveButton(WidgetRef ref) {
    return Consumer(
      builder: (context, ref, child) {
        final isSaved = ref.watch(recipeSavedProvider(recipeId));
        appLogger.d('🎯 UI: Save button evaluating | recipeId: $recipeId | isSaved: $isSaved');

        return IconButton(
          icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
          onPressed: () {
            appLogger.i('🎯 UI: Save button tapped | recipeId: $recipeId | currentlySaved: $isSaved');
            ref.read(recipeSavedProvider(recipeId).notifier).toggle();
          },
        );
      },
    );
  }

  Widget _buildErrorView(dynamic error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text('Error: $error'),
        ],
      ),
    );
  }

  Widget _buildRecipeContent(BuildContext context, WidgetRef ref, Recipe recipe) {
    // ... recipe detail content
    return Container();
  }
}

// -----------------------------------------------------------------------------
// EXAMPLE: Provider (fully annotated)
// -----------------------------------------------------------------------------

/// Recipe detail provider
/// 
/// ROLE: Fetch and cache single recipe data
/// PURPOSE: Load recipe with steps, nutrition, creator info for detail page
/// USAGE: Watched by RecipeDetailPage via recipeDetailProvider(recipeId)
/// DATA SOURCE: 
///   - Recipe + steps: JOIN recipe + recipe_step (SQL RPC or direct query)
///   - Macros: recipe_macro (simple JOIN)
///   - Creator: creator table (simple JOIN)
///   - Like count: COUNT(recipe_like) (aggregation - should be RPC)
/// BACKEND: Should use RPC function for JOINs + aggregation
///          Client should NOT do JOINs - call recommend_recipes or similar
/// CACHING: Cache per recipeId, TTL 10-30 minutes
/// INVALIDATION: On recipe update, like toggle, new comment
final recipeDetailProvider = FutureProvider.family<Recipe, String>((ref, recipeId) {
  final logger = appLogger;
  logger.d('🔄 Provider: recipeDetailProvider build() | recipeId: $recipeId');

  ref.onDispose(() {
    logger.d('🗑️ Provider: recipeDetailProvider disposed | recipeId: $recipeId');
  });

  return _fetchRecipeDetail(recipeId);
});

/// Fetch recipe detail from backend
/// 
/// ROLE: Data fetching - recipe with all related data
/// PURPOSE: Load complete recipe information for display
/// USAGE: Called by recipeDetailProvider
/// BACKEND: Should call SQL RPC function (not client-side JOINs)
Future<Recipe> _fetchRecipeDetail(String recipeId) async {
  final logger = appLogger;
  logger.d('📡 DB BEFORE: _fetchRecipeDetail() | recipeId: $recipeId | calling RPC or query');

  try {
    // OPTION 1: Call SQL RPC function (RECOMMENDED for JOINs + aggregations)
    // final result = await supabase.rpc('get_recipe_detail', params: {'p_recipe_id': recipeId});
    
    // OPTION 2: Direct query (ONLY if no JOINs needed - simple single table)
    // For recipe detail with steps, macros, creator - use RPC!
    
    final recipe = Recipe.fromJson({}); // Placeholder
    
    logger.d('📡 DB AFTER: _fetchRecipeDetail() succeeded | recipeId: $recipeId | title: ${recipe.title}');
    return recipe;
  } catch (e, st) {
    logger.e('❌ DB ERROR: _fetchRecipeDetail() failed | recipeId: $recipeId | error: $e', error: e, stackTrace: st);
    rethrow;
  }
}

// -----------------------------------------------------------------------------
// EXAMPLE: Widget with conditional rendering (fully annotated)
// -----------------------------------------------------------------------------

/// Recipe steps list
/// 
/// ROLE: Display ordered recipe preparation steps
/// PURPOSE: Show step-by-step instructions with optional timer
/// USAGE: Used in RecipeDetailPage within recipe content
/// DATA SOURCE: recipe.steps (pre-fetched by recipeDetailProvider)
/// NOTES: Steps are ordered by step_number (indexed in DB)
class RecipeStepsList extends StatelessWidget {
  /// ROLE: List of recipe steps to display
  /// PURPOSE: Recipe's preparation steps
  final List<RecipeStep> steps;

  const RecipeStepsList({super.key, required this.steps});

  @override
  Widget build(BuildContext context) {
    final logger = appLogger;
    logger.d('🎯 UI: RecipeStepsList.build() | stepCount: ${steps.length} | evaluating render');

    if (steps.isEmpty) {
      logger.d('🎯 UI: RecipeStepsList rendering empty state | reason: no steps');
      return const Center(child: Text('No steps available'));
    }

    logger.d('🎯 UI: RecipeStepsList rendering steps | reason: ${steps.length} steps available');
    return ListView.builder(
      itemCount: steps.length,
      itemBuilder: (context, index) {
        final step = steps[index];
        logger.d('🎯 UI: RecipeStepsList rendering step ${index + 1}/${steps.length} | stepNumber: ${step.stepNumber} | hasTimer: ${step.timerSeconds != null}');
        return RecipeStepCard(step: step);
      },
    );
  }
}

// =============================================================================
// ANNOTATION QUICK REFERENCE
// =============================================================================
// 
// Every file MUST have this header:
// 
// =============================================================================
// AKELI - [Component Type]: [Component Name]
// Path: lib/[path]/[file].dart
// 
// ROLE: What it does in the system
// PURPOSE: Why it exists, the problem it solves
// USAGE: How it's used, who calls it
// DATA SOURCE: Where data comes from (provider, RPC, EF, local)
// NAVIGATION: What screens it navigates to (if page)
// DEPENDENCIES: What providers/services it relies on
// NOTES: Important caveats, performance considerations
// =============================================================================
// 
// Every class MUST have:
// 
// /// [Class name]
// /// 
// /// ROLE: What this class does
// /// PURPOSE: Why this class exists
// /// USAGE: How this class is used
// class MyClass { ... }
// 
// Every method MUST have:
// 
// /// [Method name]
// /// 
// /// ROLE: What this method does
// /// PURPOSE: Why this method exists
// /// USAGE: How this method is called
// /// DATA: What data it operates on
// void myMethod() { ... }
// 
// Every provider MUST have:
// 
// /// [Provider name]
// /// 
// /// ROLE: What data this provides
// /// PURPOSE: Why this provider exists
// /// USAGE: How this provider is watched/read
// /// DATA SOURCE: Where data comes from
// /// BACKEND: Whether client-side or RPC/Edge Function
// final myProvider = FutureProvider(...);
// 
// =============================================================================
