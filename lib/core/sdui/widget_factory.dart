import 'package:flutter/material.dart';
import '../../core/theme.dart';

/// Widget factory for Server-Driven UI
/// Maps component types from remote JSON to Flutter widgets
class SDUIWidgetFactory {
  /// Build a widget from layout component JSON
  Widget buildComponent(Map<String, dynamic> component, {Map<String, dynamic>? data}) {
    final type = component['type'] as String;
    final config = component['config'] as Map<String, dynamic>? ?? {};

    switch (type) {
      // Nutrition-specific components
      case 'weight_tracker':
        return _buildWeightTracker(config, data);
      case 'calories_graph':
        return _buildCaloriesGraph(config, data);
      case 'macro_card':
        return _buildMacroCard(config, data);
      
      // Beauty-specific components
      case 'skin_care_progress':
        return _buildSkinCareProgress(config, data);
      case 'hair_care_routine':
        return _buildHairCareRoutine(config, data);
      case 'product_tracker':
        return _buildProductTracker(config, data);
      case 'beauty_tips_grid':
        return _buildBeautyTipsGrid(config, data);
      
      // Generic components (shared across modes)
      case 'hero_banner':
        return _buildHeroBanner(config, data);
      case 'section_header':
        return _buildSectionHeader(config, data);
      case 'card_grid':
        return _buildCardGrid(config, data);
      case 'action_button':
        return _buildActionButton(config, data);
      case 'stats_row':
        return _buildStatsRow(config, data);
      
      default:
        debugPrint('[SDUIWidgetFactory] Unknown component type: $type');
        return Container(
          padding: const EdgeInsets.all(16),
          color: Colors.red.withValues(alpha: 0.1),
          child: Text(
            'Unknown component: $type',
            style: const TextStyle(color: Colors.red),
          ),
        );
    }
  }

  // ========== Nutrition Components ==========

  Widget _buildWeightTracker(Map<String, dynamic> config, Map<String, dynamic>? data) {
    // Placeholder - will be replaced with actual weight tracker widget
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Text(
        config['title'] as String? ?? 'Poids',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildCaloriesGraph(Map<String, dynamic> config, Map<String, dynamic>? data) {
    // Placeholder - will integrate with fl_chart
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Center(
        child: Text(
          config['title'] as String? ?? 'Calories Graph',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMacroCard(Map<String, dynamic> config, Map<String, dynamic>? data) {
    // Placeholder - reuse existing MacroCard widget
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Text(
        config['title'] as String? ?? 'Macros',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  // ========== Beauty Components ==========

  Widget _buildSkinCareProgress(Map<String, dynamic> config, Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.secondaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.spa_outlined,
                color: AkeliColors.secondary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                config['title'] as String? ?? 'Progression Soin de la Peau',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (data?['progress'] as num?)?.toDouble() ?? 0.0,
            backgroundColor: AkeliColors.surfaceContainerHighest,
            valueColor: const AlwaysStoppedAnimation<Color>(AkeliColors.secondary),
            minHeight: 8,
          ),
          if (config['show_metrics'] == true) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _MetricChip(label: 'Hydratation', value: '${data?['hydration'] ?? 0}%'),
                _MetricChip(label: 'Texture', value: '${data?['texture'] ?? 0}%'),
                _MetricChip(label: 'Éclat', value: '${data?['radiance'] ?? 0}%'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHairCareRoutine(Map<String, dynamic> config, Map<String, dynamic>? data) {
    final steps = config['steps'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.air_outlined,
                color: AkeliColors.tertiary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  config['title'] as String? ?? 'Routine Capillaire',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.only(bottom: index < steps.length - 1 ? 12 : 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AkeliColors.tertiary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step['name'] as String? ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AkeliColors.onSurface,
                          ),
                        ),
                        if (step['description'] != null)
                          Text(
                            step['description'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AkeliColors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProductTracker(Map<String, dynamic> config, Map<String, dynamic>? data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AkeliRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                color: AkeliColors.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                config['title'] as String? ?? 'Produits Utilisés',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Product list placeholder
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 3,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  margin: EdgeInsets.only(right: index < 2 ? 12 : 0),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(AkeliRadius.md),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AkeliColors.primary, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        'Produit ${index + 1}',
                        style: const TextStyle(fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeautyTipsGrid(Map<String, dynamic> config, Map<String, dynamic>? data) {
    final tips = config['tips'] as List<dynamic>? ?? [];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (config['title'] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              config['title'] as String,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AkeliColors.onSurface,
              ),
            ),
          ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: tips.isEmpty ? 4 : tips.length,
          itemBuilder: (context, index) {
            final tip = tips.isEmpty ? {'title': 'Astuce ${index + 1}'} : tips[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AkeliColors.primaryContainer.withValues(alpha: 0.3),
                    AkeliColors.secondaryContainer.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AkeliRadius.lg),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AkeliColors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Text(
                      tip['title'] as String? ?? 'Astuce',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AkeliColors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ========== Generic Components ==========

  Widget _buildHeroBanner(Map<String, dynamic> config, Map<String, dynamic>? data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config['gradient_colors'] != null
              ? (config['gradient_colors'] as List).map((c) => Color(c)).toList()
              : [AkeliColors.primary, AkeliColors.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AkeliRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (config['badge'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                config['badge'] as String,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(
            config['title'] as String? ?? '',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (config['subtitle'] != null) ...[
            const SizedBox(height: 8),
            Text(
              config['subtitle'] as String,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
          if (config['action_label'] != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Handle action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AkeliColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                ),
              ),
              child: Text(config['action_label'] as String),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(Map<String, dynamic> config, Map<String, dynamic>? data) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          config['title'] as String? ?? '',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AkeliColors.onSurface,
          ),
        ),
        if (config['action_label'] != null)
          InkWell(
            onTap: () {
              // TODO: Handle action
            },
            child: Text(
              config['action_label'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AkeliColors.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCardGrid(Map<String, dynamic> config, Map<String, dynamic>? data) {
    final items = config['items'] as List<dynamic>? ?? [];
    
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: config['columns'] as int? ?? 2,
        mainAxisSpacing: config['spacing'] as double? ?? 12,
        crossAxisSpacing: config['spacing'] as double? ?? 12,
        childAspectRatio: config['aspect_ratio'] as double? ?? 1.0,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index] as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AkeliColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AkeliRadius.lg),
            boxShadow: [AkeliShadows.sm],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item['icon'] != null)
                Icon(
                  IconData(int.parse(item['icon']), fontFamily: 'MaterialIcons'),
                  color: AkeliColors.primary,
                  size: 28,
                ),
              const SizedBox(height: 12),
              Text(
                item['title'] as String? ?? '',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurface,
                ),
              ),
              if (item['subtitle'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  item['subtitle'] as String,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(Map<String, dynamic> config, Map<String, dynamic>? data) {
    final isOutlined = config['style'] == 'outlined';
    
    return SizedBox(
      width: double.infinity,
      child: isOutlined
          ? OutlinedButton(
              onPressed: () {
                // TODO: Handle action
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AkeliColors.primary,
                side: const BorderSide(color: AkeliColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                ),
              ),
              child: Text(config['label'] as String? ?? 'Action'),
            )
          : ElevatedButton(
              onPressed: () {
                // TODO: Handle action
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: config['color'] != null
                    ? Color(config['color'] as int)
                    : AkeliColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AkeliRadius.md),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (config['icon'] != null) ...[
                    Icon(
                      IconData(int.parse(config['icon']), fontFamily: 'MaterialIcons'),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(config['label'] as String? ?? 'Action'),
                ],
              ),
            ),
    );
  }

  Widget _buildStatsRow(Map<String, dynamic> config, Map<String, dynamic>? data) {
    final stats = config['stats'] as List<dynamic>? ?? [];
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: stats.map((stat) {
        final statMap = stat as Map<String, dynamic>;
        return Column(
          children: [
            Text(
              statMap['value'] as String? ?? '0',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AkeliColors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              statMap['label'] as String? ?? '',
              style: const TextStyle(
                fontSize: 12,
                color: AkeliColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// Helper widget for metric chips
class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AkeliRadius.md),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AkeliColors.onSurface,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AkeliColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
