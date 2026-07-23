import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/color_set_provider.dart';

@immutable
class ColorSetPreset {
  final String id;
  final Color primary;
  final Color secondary;

  const ColorSetPreset({
    required this.id,
    required this.primary,
    required this.secondary,
  });
}

class ColorSetModal extends ConsumerStatefulWidget {
  final Color initialPrimary;
  final Color initialSecondary;
  final Function(Color primary, Color secondary)? onSelect;

  const ColorSetModal({
    super.key,
    required this.initialPrimary,
    required this.initialSecondary,
    this.onSelect,
  });

  static const List<ColorSetPreset> presets = [
    ColorSetPreset(
      id: 'teal_nutrition',
      primary: Color(0xFF00504A),
      secondary: Color(0xFFFF9F43),
    ),
    ColorSetPreset(
      id: 'rose_beauty',
      primary: Color(0xFF8A3B58),
      secondary: Color(0xFFD4AF37),
    ),
    ColorSetPreset(
      id: 'sage_botanique',
      primary: Color(0xFF4A6B5D),
      secondary: Color(0xFFCD7F32),
    ),
    ColorSetPreset(
      id: 'terracotta_soleil',
      primary: Color(0xFFB85D3B),
      secondary: Color(0xFFE0A96D),
    ),
  ];

  static String presetName(AppLocalizations l10n, String id) {
    switch (id) {
      case 'teal_nutrition':
        return l10n.colorSetModalPresetTealName;
      case 'rose_beauty':
        return l10n.colorSetModalPresetRoseName;
      case 'sage_botanique':
        return l10n.colorSetModalPresetSageName;
      case 'terracotta_soleil':
        return l10n.colorSetModalPresetTerracottaName;
      default:
        return id;
    }
  }

  static String presetDescription(AppLocalizations l10n, String id) {
    switch (id) {
      case 'teal_nutrition':
        return l10n.colorSetModalPresetTealDesc;
      case 'rose_beauty':
        return l10n.colorSetModalPresetRoseDesc;
      case 'sage_botanique':
        return l10n.colorSetModalPresetSageDesc;
      case 'terracotta_soleil':
        return l10n.colorSetModalPresetTerracottaDesc;
      default:
        return '';
    }
  }

  static Future<ColorSetPreset?> show(
    BuildContext context, {
    Color initialPrimary = const Color(0xFF00504A),
    Color initialSecondary = const Color(0xFFFF9F43),
  }) {
    return showModalBottomSheet<ColorSetPreset>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ColorSetModal(
        initialPrimary: initialPrimary,
        initialSecondary: initialSecondary,
      ),
    );
  }

  @override
  ConsumerState<ColorSetModal> createState() => _ColorSetModalState();
}

class _ColorSetModalState extends ConsumerState<ColorSetModal> {
  final _logger = appLogger;
  late ColorSetPreset _selectedPreset;

  @override
  void initState() {
    super.initState();
    _selectedPreset = ColorSetModal.presets.firstWhere(
      (p) => p.primary == widget.initialPrimary,
      orElse: () => ColorSetModal.presets.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.colorSetModalTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AkeliColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.colorSetModalSubtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AkeliColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 24),

            ...ColorSetModal.presets.map((preset) {
              final isSelected = _selectedPreset.id == preset.id;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isSelected
                        ? preset.primary
                        : AkeliColors.outlineVariant.withValues(alpha: 0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                elevation: 0,
                color: isSelected
                    ? preset.primary.withValues(alpha: 0.05)
                    : Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: preset.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: preset.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  title: Text(
                    ColorSetModal.presetName(l10n, preset.id),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    ColorSetModal.presetDescription(l10n, preset.id),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle, color: preset.primary)
                      : null,
                  onTap: () {
                    _logger.userAction('Color preset selected', screen: 'ColorSetModal', metadata: {'preset': preset.id});
                    setState(() => _selectedPreset = preset);
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                key: const Key('apply_color_set_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedPreset.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  _logger.userAction('Apply color palette tapped', screen: 'ColorSetModal', metadata: {'preset': _selectedPreset.id});
                  ref.read(colorSetProvider.notifier).selectPreset(_selectedPreset);
                  if (widget.onSelect != null) {
                    widget.onSelect!(_selectedPreset.primary, _selectedPreset.secondary);
                  }
                  Navigator.of(context).pop(_selectedPreset);
                },
                child: Text(
                  l10n.colorSetModalApplyButton,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}