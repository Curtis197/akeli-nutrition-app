import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

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
    final rawConfig = component['config'];
    final config = rawConfig is Map<String, dynamic>
        ? rawConfig
        : rawConfig is Map
            ? Map<String, dynamic>.from(rawConfig)
            : <String, dynamic>{};

    try {
      switch (type) {
        // ==================== COMMON COMPONENTS ====================
        case 'header':
          return _buildHeader(config, mode);

        case 'hero_banner':
          return _buildHeroBanner(config, mode);

        case 'section_header':
          return _buildSectionHeader(config, mode);

        case 'quick_actions':
          return _buildQuickActions(config, mode);

        case 'cultural_spotlight':
          return _buildCulturalSpotlight(config, mode);

        // ==================== NUTRITION COMPONENTS ====================
        case 'weight_tracker':
        case 'weight_tracker_card':
          return _buildWeightTracker(config, mode);

        case 'calories_graph':
        case 'calorie_summary':
          return _buildCaloriesGraph(config, mode);

        case 'meal_log':
          return _buildMealLog(config, mode);

        case 'nutrition_summary':
          return _buildNutritionSummary(config, mode);

        // ==================== BEAUTY COMPONENTS ====================
        case 'routine_grid':
          return _buildRoutineGrid(config, mode);

        case 'routine_progress':
          return _buildRoutineProgress(config, mode);

        case 'product_tracker':
          return _buildProductTracker(config, mode);

        case 'skin_progress':
          return _buildSkinProgress(config, mode);

        case 'skin_hair_status':
          return _buildSkinHairStatus(config, mode);

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
          _logger.provider('SDUIWidgetFactory | unknown type: $type');
          return _buildUnknownComponent(type, config);
      }
    } catch (e) {
      _logger.provider('SDUIWidgetFactory | error: $type | $e', error: e);
      return _buildErrorWidget(type, e.toString());
    }
  }

  // ==================== COMMON WIDGETS ====================

  static Widget _buildHeader(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? '';
    final subtitle = config['subtitle'] as String? ?? '';
    final isBeauty = mode == 'beauty';
    final accent = isBeauty ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: accent,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 15, color: Colors.black54),
            ),
          ],
        ],
      ),
    );
  }

  static Widget _buildCulturalSpotlight(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Spotlight';
    final item = config['item'] as String? ?? '';
    final isBeauty = mode == 'beauty';
    final accent = isBeauty ? const Color(0xFFFF6B6B) : const Color(0xFF4CAF50);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isBeauty ? Icons.auto_awesome : Icons.eco_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: accent,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: accent),
        ],
      ),
    );
  }

  static Widget _buildRoutineProgress(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Weekly Routine';
    final completed = config['completed'] as int? ?? 0;
    final total = config['total'] as int? ?? 1;
    final progress = total > 0 ? completed / total : 0.0;
    const accent = Color(0xFFFF6B6B);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: accent.withValues(alpha: 0.06),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  '$completed / $total',
                  style: const TextStyle(fontSize: 14, color: accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: accent.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$completed routines completed this week',
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSkinHairStatus(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Current Focus';
    final metric = config['metric'] as String? ?? '';
    final value = config['value'] as String? ?? '';
    const accent = Color(0xFFFF6B6B);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.water_drop_outlined, color: accent, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    metric,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildHeroBanner(Map<String, dynamic> config, String mode) {
    final title = config['title'] as String? ?? 'Welcome';
    final subtitle = config['subtitle'] as String? ?? '';
    final imageUrl = config['image_url'] as String?;

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
                _logger.userAction('Section action tapped: $actionLabel', screen: 'SDUIWidgetFactory');
              },
              child: Text(actionLabel),
            ),
        ],
      ),
    );
  }

  static Widget _buildQuickActions(Map<String, dynamic> config, String mode) {
    // DB stores items as List<String>; legacy format uses List<Map> under 'actions'.
    final items = config['items'] as List<dynamic>?
        ?? config['actions'] as List<dynamic>?
        ?? [];

    if (items.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final String label;
          IconData iconData;

          if (item is Map<String, dynamic>) {
            label = item['label'] as String? ?? 'Action';
            final iconStr = item['icon'] as String? ?? '';
            final codePoint = int.tryParse(iconStr);
            iconData = codePoint != null
                ? IconData(codePoint, fontFamily: 'MaterialIcons')
                : Icons.star_outline;
          } else {
            // String key from DB e.g. "log_meal", "scan_product"
            label = _actionLabel(item as String);
            iconData = _actionIcon(item);
          }

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: mode == 'beauty'
                      ? const Color(0xFFFF6B6B).withValues(alpha: 0.2)
                      : const Color(0xFF4CAF50).withValues(alpha: 0.2),
                  child: Icon(
                    iconData,
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

  static String _actionLabel(String key) {
    const labels = {
      'log_meal': 'Log Meal',
      'scan_product': 'Scan',
      'view_plan': 'My Plan',
      'log_routine': 'Routine',
      'remedy_finder': 'Remedies',
    };
    return labels[key] ?? key;
  }

  static IconData _actionIcon(String key) {
    const icons = {
      'log_meal': Icons.restaurant,
      'scan_product': Icons.qr_code_scanner,
      'view_plan': Icons.calendar_today,
      'log_routine': Icons.spa,
      'remedy_finder': Icons.local_florist,
    };
    return icons[key] ?? Icons.star_outline;
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
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
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
