import 'package:flutter/material.dart';
import '../providers/mode_provider.dart';

/// SDUI Widget Factory - Maps JSON component types to Flutter widgets
/// 
/// This is the core of the Server-Driven UI system. It safely renders
/// components based on remote layout configurations while maintaining
/// type safety and error handling.
class WidgetFactory {
  /// Build a widget from a component configuration
  /// 
  /// [component] - Map containing 'type' and 'config' from layout JSON
  /// [mode] - Current active mode for context-aware rendering
  static Widget buildComponent(Map<String, dynamic> component, String mode) {
    final type = component['type'] as String?;
    final config = component['config'] as Map<String, dynamic>? ?? {};

    try {
      switch (type) {
        // ==================== COMMON COMPONENTS ====================
        case 'hero_banner':
          return _buildHeroBanner(config, mode);
        
        case 'section_header':
          return _buildSectionHeader(config, mode);
        
        case 'quick_actions':
          return _buildQuickActions(config, mode);

        // ==================== NUTRITION COMPONENTS ====================
        case 'weight_tracker':
          return _buildWeightTracker(config, mode);
        
        case 'calories_graph':
          return _buildCaloriesGraph(config, mode);
        
        case 'meal_log':
          return _buildMealLog(config, mode);
        
        case 'nutrition_summary':
          return _buildNutritionSummary(config, mode);

        // ==================== BEAUTY COMPONENTS ====================
        case 'routine_grid':
          return _buildRoutineGrid(config, mode);
        
        case 'product_tracker':
          return _buildProductTracker(config, mode);
        
        case 'skin_progress':
          return _buildSkinProgress(config, mode);
        
        case 'hair_care_timeline':
          return _buildHairCareTimeline(config, mode);
        
        case 'ingredient_checker':
          return _buildIngredientChecker(config, mode);

        // ==================== CULTURAL COMPONENTS ====================
        case 'cultural_tip':
          return _buildCulturalTip(config, mode);
        
        case 'traditional_remedy':
          return _buildTraditionalRemedy(config, mode);

        // ==================== FALLBACK ====================
        default:
          debugPrint('⚠️ Unknown component type: $type');
          return _buildUnknownComponent(type, config);
      }
    } catch (e) {
      debugPrint('❌ Error building component $type: $e');
      return _buildErrorWidget(type, e.toString());
    }
  }

  // ==================== COMMON WIDGETS ====================

  static Widget _buildHeroBanner(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Welcome';
    final subtitle = config['subtitle'] as String? ?? '';
    final imageUrl = config['image_url'] as String?;
    final actionUrl = config['action_url'] as String?;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: mode == 'beauty' 
              ? [const Color(0xFFFFD700), const Color(0xFFFF6B6B)]
              : [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (imageUrl != null)
            Positioned(
              right: -20,
              bottom: -20,
              child: Opacity(
                opacity: 0.2,
                child: Image.network(
                  imageUrl,
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  static Widget _buildSectionHeader(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Section';
    final showAction = config['show_action'] as bool? ?? false;
    final actionLabel = config['action_label'] as String?;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showAction && actionLabel != null)
            TextButton(
              onPressed: () {
                debugPrint('Action tapped: $actionLabel');
              },
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  static Widget _buildQuickActions(Map<String, dynamic> config, String mode) {
    final actions = config['actions'] as List<dynamic>? ?? [];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: actions.length,
        itemBuilder: (context, index) {
          final action = actions[index] as Map<String, dynamic>;
          final label = action['label'] as String? ?? 'Action';
          final icon = action['icon'] as String? ?? 'star';

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: mode == 'beauty' 
                      ? const Color(0xFFFF6B6B).withOpacity(0.2)
                      : const Color(0xFF4CAF50).withOpacity(0.2),
                  child: Icon(
                    IconData(int.parse(icon), fontFamily: 'MaterialIcons'),
                    color: mode == 'beauty' 
                        ? const Color(0xFFFF6B6B)
                        : const Color(0xFF4CAF50),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== NUTRITION WIDGETS ====================

  static Widget _buildWeightTracker(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Weight Progress';
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Center(child: Text('Weight tracker placeholder')),
          ],
        ),
      ),
    );
  }

  static Widget _buildCaloriesGraph(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Daily Calories';
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Center(child: Text('Calories graph placeholder')),
          ],
        ),
      ),
    );
  }

  static Widget _buildMealLog(Map<String, dynamic> config, String mode) {
    return const Center(child: Text('Meal log placeholder'));
  }

  static Widget _buildNutritionSummary(Map<String, dynamic> config, String mode) {
    return const Center(child: Text('Nutrition summary placeholder'));
  }

  // ==================== BEAUTY WIDGETS ====================

  static Widget _buildRoutineGrid(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Your Routines';
    final routines = config['routines'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            routines.isEmpty
                ? const Center(child: Text('No routines yet. Start your beauty journey!'))
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: routines.length.clamp(0, 4),
                    itemBuilder: (context, index) {
                      final routine = routines[index] as Map<String, dynamic>? ?? {};
                      return Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B6B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(routine['name'] as String? ?? 'Routine'),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  static Widget _buildProductTracker(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Products';
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            const Center(child: Text('Product tracker placeholder')),
          ],
        ),
      ),
    );
  }

  static Widget _buildSkinProgress(Map<String, dynamic> config, String mode) {
    return const Center(child: Text('Skin progress placeholder'));
  }

  static Widget _buildHairCareTimeline(Map<String, dynamic> config, String mode) {
    return const Center(child: Text('Hair care timeline placeholder'));
  }

  static Widget _buildIngredientChecker(Map<String, dynamic> config, String mode) {
    return const Center(child: Text('Ingredient checker placeholder'));
  }

  // ==================== CULTURAL WIDGETS ====================

  static Widget _buildCulturalTip(Map<String, dynamic> config, String mode) {
    final tip = config['tip'] as String? ?? 'Cultural wellness tip';
    final origin = config['origin'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  'Cultural Tip',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(tip, style: const TextStyle(fontSize: 14)),
            if (origin.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '— $origin',
                style: TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _buildTraditionalRemedy(Map<String, dynamic> config, String mode) {
    final remedy = config['remedy'] as String? ?? 'Traditional remedy';
    final ingredients = config['ingredients'] as List<dynamic>? ?? [];

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Traditional Remedy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(remedy),
            if (ingredients.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ingredients
                    .map((i) => Chip(
                          label: Text(i as String),
                          backgroundColor: Colors.green.shade50,
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ==================== ERROR HANDLING ====================

  static Widget _buildUnknownComponent(String? type, Map<String, dynamic> config) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          const Icon(Icons.warning_amber, color: Colors.orange),
          const SizedBox(height: 8),
          Text(
            'Unknown component: ${type ?? "null"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  static Widget _buildErrorWidget(String? type, String error) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(height: 8),
          Text(
            'Error loading component: ${type ?? "null"}',
            style: const TextStyle(fontSize: 12, color: Colors.red),
          ),
          Text(
            error,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
