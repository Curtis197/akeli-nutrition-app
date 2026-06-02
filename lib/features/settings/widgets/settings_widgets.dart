// lib/features/settings/widgets/settings_widgets.dart

import 'package:akeli/core/logger.dart';
import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  const SettingsSectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 8, bottom: 4),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AkeliColors.onSurfaceVariant,
            letterSpacing: 1.2,
          ),
        ),
      );
}

class SettingsCard extends StatelessWidget {
  final Widget child;
  const SettingsCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );
}

class SettingsLabel extends StatelessWidget {
  final String text;
  const SettingsLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AkeliColors.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      );
}

class SettingsRadioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const SettingsRadioRow({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static final _logger = appLogger;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          _logger.userAction('SettingsRadioRow tapped', screen: 'Settings',
              metadata: {'label': label});
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? AkeliColors.primary
                      : AkeliColors.onSurfaceVariant),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    color: selected
                        ? AkeliColors.primary
                        : AkeliColors.onSurface,
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded,
                    color: AkeliColors.primary, size: 20),
            ],
          ),
        ),
      );
}
