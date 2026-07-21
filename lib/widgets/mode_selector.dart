import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/logger.dart';
import '../core/theme.dart';
import '../providers/mode_provider.dart';

final _logger = appLogger;

/// Helper to get Material icon for each AppMode
IconData getAppModeIcon(AppMode mode) {
  switch (mode) {
    case AppMode.nutrition:
      return Icons.restaurant_rounded;
    case AppMode.beauty:
      return Icons.auto_awesome_rounded;
    case AppMode.health:
      return Icons.favorite_rounded;
    case AppMode.sport:
      return Icons.fitness_center_rounded;
    case AppMode.family:
      return Icons.family_restroom_rounded;
  }
}

/// Helper to get description for each AppMode
String getAppModeDescription(AppMode mode) {
  switch (mode) {
    case AppMode.nutrition:
      return 'Planification de repas, macros et recettes adaptées';
    case AppMode.beauty:
      return 'Routines soins peau & cheveux, remèdes traditionnels';
    case AppMode.health:
      return 'Suivi paramètres de santé, poids et constantes';
    case AppMode.sport:
      return 'Programmes d\'entraînement et suivi d\'activité';
    case AppMode.family:
      return 'Gestion de la nutrition et des repas familiaux';
  }
}

/// Interactive Dialog to select the active SDUI App Mode
Future<void> showModeSelectorDialog(BuildContext context, WidgetRef ref) async {
  _logger.userAction('Opening App Mode Selector Dialog', screen: 'SettingsPage');
  final currentMode = ref.read(currentModeProvider);

  await showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AkeliColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.dashboard_customize_rounded,
                color: AkeliColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Mode d\'application (SDUI)',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: AppMode.values.where((m) => m == AppMode.nutrition || m == AppMode.beauty).map((mode) {
              final isSelected = mode == currentMode;
              final color = getAppModeColor(mode);
              final icon = getAppModeIcon(mode);

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.12)
                      : AkeliColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : AkeliColors.outlineVariant,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  title: Row(
                    children: [
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isSelected ? color : AkeliColors.onSurface,
                        ),
                      ),
                      if (mode == AppMode.beauty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'SDUI V1',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Text(
                    getAppModeDescription(mode),
                    style: TextStyle(
                      fontSize: 12,
                      color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: color, size: 24)
                      : const Icon(Icons.radio_button_unchecked_rounded,
                          color: AkeliColors.outline, size: 20),
                  onTap: () {
                    _logger.userAction('Selected AppMode: ${mode.name}', screen: 'SettingsPage');
                    ref.read(currentModeProvider.notifier).switchMode(mode);
                    Navigator.pop(ctx);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Icon(icon, color: Colors.white, size: 20),
                            const SizedBox(width: 10),
                            Text('Passé en mode ${mode.displayName}'),
                          ],
                        ),
                        backgroundColor: color,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(color: AkeliColors.onSurfaceVariant)),
          ),
        ],
      );
    },
  );
}

/// Menu item tile for SettingsPage
class ModeSelectorTile extends ConsumerWidget {
  const ModeSelectorTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(currentModeProvider);
    final color = getAppModeColor(currentMode);
    final icon = getAppModeIcon(currentMode);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: const Text(
        'Mode d\'application (SDUI)',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: AkeliColors.onSurface,
        ),
      ),
      subtitle: Text(
        'Basculer entre Nutrition et Beauté',
        style: TextStyle(
          fontSize: 12,
          color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8),
        ),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentMode.displayName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.unfold_more_rounded, size: 16, color: color),
          ],
        ),
      ),
      onTap: () => showModeSelectorDialog(context, ref),
    );
  }
}
