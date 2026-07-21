import 'package:flutter/material.dart';
import '../../core/theme.dart';

@immutable
class ColorSetPreset {
  final String name;
  final Color primary;
  final Color secondary;
  final String description;

  const ColorSetPreset({
    required this.name,
    required this.primary,
    required this.secondary,
    required this.description,
  });
}

class ColorSetModal extends StatefulWidget {
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
      name: 'Teal & Amber (Nutrition)',
      primary: Color(0xFF00504A),
      secondary: Color(0xFFFF9F43),
      description: 'Équilibré, sain et énergisant.',
    ),
    ColorSetPreset(
      name: 'Rose & Gold (Beauty)',
      primary: Color(0xFF8A3B58),
      secondary: Color(0xFFD4AF37),
      description: 'Luxe éditorial, soin bio & éclat.',
    ),
    ColorSetPreset(
      name: 'Sage & Bronze (Botanique)',
      primary: Color(0xFF4A6B5D),
      secondary: Color(0xFFCD7F32),
      description: 'Plantes ancestrales & nature.',
    ),
    ColorSetPreset(
      name: 'Terracotta & Clay (Soleil)',
      primary: Color(0xFFB85D3B),
      secondary: Color(0xFFE0A96D),
      description: 'Tonalité terre d\'Afrique & chaleur.',
    ),
  ];

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
  State<ColorSetModal> createState() => _ColorSetModalState();
}

class _ColorSetModalState extends State<ColorSetModal> {
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
            'Personnaliser le Thème de Couleurs',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.textPrimary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Sélectionnez une palette de couleurs Primaire & Secondaire.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AkeliColors.textSecondary,
                ),
          ),
          const SizedBox(height: 24),

          // Presets list
          ...ColorSetModal.presets.map((preset) {
            final isSelected = _selectedPreset.name == preset.name;

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
                  preset.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  preset.description,
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: preset.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedPreset = preset);
                },
              ),
            );
          }),

          const SizedBox(height: 16),

          // Apply button
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
                if (widget.onSelect != null) {
                  widget.onSelect!(_selectedPreset.primary, _selectedPreset.secondary);
                }
                Navigator.of(context).pop(_selectedPreset);
              },
              child: const Text(
                'Appliquer cette Palette',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
