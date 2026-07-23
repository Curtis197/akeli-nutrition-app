// lib/features/settings/health_profile_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/locale_provider.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../core/unit_converter.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/health_profile_provider.dart';
import '../../providers/mode_provider.dart';
import 'models/health_profile_model.dart';
import 'widgets/settings_widgets.dart';

class HealthProfilePage extends ConsumerStatefulWidget {
  const HealthProfilePage({super.key});

  @override
  ConsumerState<HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends ConsumerState<HealthProfilePage> {
  HealthProfileModel? _local;
  bool _saving = false;
  final _logger = appLogger;

  final _heightCtrl = TextEditingController();
  final _heightFeetCtrl = TextEditingController();
  final _heightInchesCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  static const Color _rosewood = Color(0xFF8A3B58);
  static const Color _gold = Color(0xFFD4AF37);

  final List<String> _hairTypes = const [
    'Type 1A - Lisse fin',
    'Type 1B - Lisse moyen',
    'Type 1C - Lisse épais',
    'Type 2A - Ondulé fin',
    'Type 2B - Ondulé moyen',
    'Type 2C - Ondulé épais',
    'Type 3A - Bouclé lâche',
    'Type 3B - Bouclé serré',
    'Type 3C - Frisé / Tirbouchon',
    'Type 4A - Crépu doux',
    'Type 4B - Crépu en Z',
    'Type 4C - Crépu très dense',
    'Locks / Dreadlocks',
    'Cheveux en Transition',
    'Soin Sous Tresses / Perruque',
  ];

  final List<String> _skinTypologies = const [
    'Peau Mixte (Zone T brillante)',
    'Peau Sèche & Déshydratée',
    'Peau Grasse & Acnéique',
    'Peau Sensible & Réactive',
    'Peau Hyperpigmentée / Taches',
    'Peau Mature / Perte de Fermeté',
    'Peau Normale & Équilibrée',
  ];

  final List<String> _allSkinConcerns = const [
    'Hyperpigmentation & Taches',
    'Acné & Imperfections',
    'Déshydratation & Tiraillements',
    'Barrière Cutanée Fragilisée',
    'Excès de Sébum & Brillance',
    'Perte d\'Élasticité & Fermeté',
  ];

  final List<String> _allBeautyGoals = const [
    'Pousse & Longueur',
    'Densité & Volume',
    'Force & Anti-Casse',
    'Hydratation Capillaire',
    'Apaisement Cuir Chevelu',
    'Éclat du Teint',
    'Atténuation des Taches',
    'Hydratation Cutanée',
    'Clarification Anti-Imperfections',
    'Fortification Barrière Cutanée',
  ];

  @override
  void dispose() {
    _logger.provider('HealthProfilePage disposed');
    _heightCtrl.dispose();
    _heightFeetCtrl.dispose();
    _heightInchesCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  void _initControllers(HealthProfileModel prefs, bool isUs) {
    if (prefs.heightCm != null) {
      if (isUs) {
        if (_heightFeetCtrl.text.isEmpty && _heightInchesCtrl.text.isEmpty) {
          final (feet, inches) = UnitConverter.cmToFeetIn(prefs.heightCm!);
          _heightFeetCtrl.text = feet.toString();
          _heightInchesCtrl.text = inches.toString();
        }
      } else if (_heightCtrl.text.isEmpty) {
        _heightCtrl.text = prefs.heightCm!.toStringAsFixed(1);
      }
    }
    if (_weightCtrl.text.isEmpty && prefs.weightKg != null) {
      _weightCtrl.text = (isUs
              ? UnitConverter.kgToLb(prefs.weightKg!)
              : prefs.weightKg!)
          .toStringAsFixed(1);
    }
    if (_targetWeightCtrl.text.isEmpty && prefs.targetWeightKg != null) {
      _targetWeightCtrl.text = (isUs
              ? UnitConverter.kgToLb(prefs.targetWeightKg!)
              : prefs.targetWeightKg!)
          .toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('HealthProfilePage build()');
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(healthProfileProvider);
    final isUs = ref.watch(localeProvider).isUsLocale;
    final currentMode = ref.watch(currentModeProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('${l10n.healthProfileError}: $e')),
      ),
      data: (prefs) {
        if (_local == null) {
          _local = prefs;
          _initControllers(prefs, isUs);
        }
        final local = _local!;

        return Scaffold(
          backgroundColor: AkeliColors.background,
          extendBodyBehindAppBar: true,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight + 16),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: AkeliColors.surface.withValues(alpha: 0.8),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    bottom: 8,
                    left: 16,
                    right: 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: AkeliColors.surfaceContainerHighest,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: AkeliColors.onSurfaceVariant,
                          onPressed: () {
                            _logger.userAction('HealthProfilePage back tapped',
                                screen: 'HealthProfilePage');
                            if (context.canPop()) context.pop();
                          },
                        ),
                      ),
                      Text(
                        currentMode == AppMode.beauty ? 'Diagnostic & Profil Beauté 🌸' : l10n.healthProfileTitle,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: getAppModeColor(currentMode),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
              left: 16,
              right: 16,
              bottom: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentMode == AppMode.beauty)
                  _buildBeautyHealthForm(local)
                else
                  _buildNutritionHealthForm(local, l10n, isUs),
                
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: currentMode == AppMode.beauty ? _rosewood : AkeliColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Enregistrer le Profil',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBeautyHealthForm(HealthProfileModel local) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section 1: Empreinte Capillaire
        const SettingsSectionHeader(title: 'Empreinte Capillaire 👑'),
        const SizedBox(height: 8),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsLabel('Type / Texture Capillaire'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _hairTypes.contains(local.hairType) ? local.hairType : _hairTypes.first,
                dropdownColor: AkeliColors.surfaceContainerHighest,
                style: const TextStyle(color: AkeliColors.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AkeliColors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _hairTypes.map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (val) {
                  setState(() => _local = local.copyWith(hairType: val));
                },
              ),
              const SizedBox(height: 16),
              const SettingsLabel('Porosité'),
              const SizedBox(height: 8),
              Row(
                children: ['Faible', 'Moyenne', 'Élevée'].map((p) {
                  final selected = local.porosity == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text(p),
                        selected: selected,
                        selectedColor: _rosewood.withOpacity(0.3),
                        checkmarkColor: _gold,
                        labelStyle: TextStyle(
                          color: selected ? _gold : AkeliColors.onSurfaceVariant,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (_) {
                          setState(() => _local = local.copyWith(porosity: p));
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: _gold,
                title: const Text('Cuir Chevelu Sensible / Réactif', style: TextStyle(color: AkeliColors.onSurface, fontSize: 14)),
                subtitle: const Text('Tendance aux démangeaisons ou rougeurs', style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 12)),
                value: local.sensitiveScalp ?? false,
                onChanged: (val) {
                  setState(() => _local = local.copyWith(sensitiveScalp: val));
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section 2: Diagnostic Cutané Profond
        const SettingsSectionHeader(title: 'Diagnostic Cutané Profond ✨'),
        const SizedBox(height: 8),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsLabel('Typologie de Peau'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _skinTypologies.contains(local.skinType) ? local.skinType : _skinTypologies.first,
                dropdownColor: AkeliColors.surfaceContainerHighest,
                style: const TextStyle(color: AkeliColors.onSurface, fontSize: 14),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AkeliColors.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                items: _skinTypologies.map((skin) => DropdownMenuItem(value: skin, child: Text(skin))).toList(),
                onChanged: (val) {
                  setState(() => _local = local.copyWith(skinType: val));
                },
              ),
              const SizedBox(height: 16),
              const SettingsLabel('Préoccupations Dermatologiques'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allSkinConcerns.map((concern) {
                  final isSelected = local.skinConcerns.contains(concern);
                  return FilterChip(
                    label: Text(concern),
                    selected: isSelected,
                    selectedColor: _rosewood.withOpacity(0.3),
                    checkmarkColor: _gold,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? _gold : AkeliColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      final updated = List<String>.from(local.skinConcerns);
                      if (selected) {
                        updated.add(concern);
                      } else {
                        updated.remove(concern);
                      }
                      setState(() => _local = local.copyWith(skinConcerns: updated));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Section 3: Objectifs Rituel Beauté
        const SettingsSectionHeader(title: 'Objectifs Rituel Beauté 🌸'),
        const SizedBox(height: 8),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SettingsLabel('Priorités Capillaires & Cutanées'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allBeautyGoals.map((goal) {
                  final isSelected = local.beautyGoals.contains(goal);
                  return FilterChip(
                    label: Text(goal),
                    selected: isSelected,
                    selectedColor: _rosewood.withOpacity(0.3),
                    checkmarkColor: _gold,
                    labelStyle: TextStyle(
                      fontSize: 12,
                      color: isSelected ? _gold : AkeliColors.onSurfaceVariant,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (selected) {
                      final updated = List<String>.from(local.beautyGoals);
                      if (selected) {
                        updated.add(goal);
                      } else {
                        updated.remove(goal);
                      }
                      setState(() => _local = local.copyWith(beautyGoals: updated));
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionHealthForm(HealthProfileModel local, AppLocalizations l10n, bool isUs) {
    final activityOptions = [
      ('sedentary',  l10n.healthActivitySedentary,  Icons.weekend_outlined),
      ('light',      l10n.healthActivityLight,       Icons.directions_walk_rounded),
      ('moderate',   l10n.healthActivityModerate,    Icons.directions_bike_outlined),
      ('active',     l10n.healthActivityActive,      Icons.fitness_center_rounded),
      ('very_active',l10n.healthActivityVeryActive,  Icons.bolt_rounded),
    ];

    final sexOptions = [
      ('male',   l10n.healthSexMale),
      ('female', l10n.healthSexFemale),
      ('other',  l10n.healthSexOther),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: l10n.healthParamsSection),
        const SizedBox(height: 8),
        SettingsCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsLabel(l10n.healthSex),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: sexOptions.map((opt) {
                  final sel = local.sex == opt.$1;
                  return ChoiceChip(
                    label: Text(opt.$2),
                    selected: sel,
                    onSelected: (s) {
                      if (s) {
                        setState(() => _local = local.copyWith(sex: opt.$1));
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SettingsLabel(l10n.healthHeight),
              const SizedBox(height: 8),
              TextField(
                controller: _heightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: isUs ? 'in' : 'cm',
                  hintText: isUs ? '67.0' : '170.0',
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    final cm = isUs ? (parsed * 2.54) : parsed;
                    setState(() => _local = local.copyWith(heightCm: cm));
                  }
                },
              ),
              const SizedBox(height: 20),
              SettingsLabel(l10n.healthWeightGoal),
              const SizedBox(height: 8),
              TextField(
                controller: _weightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: isUs ? 'lbs' : 'kg',
                  hintText: isUs ? '154.0' : '70.0',
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    final kg = isUs ? UnitConverter.lbToKg(parsed) : parsed;
                    setState(() => _local = local.copyWith(weightKg: kg));
                  }
                },
              ),
              const SizedBox(height: 20),
              SettingsLabel(l10n.healthTargetWeight),
              const SizedBox(height: 8),
              TextField(
                controller: _targetWeightCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: isUs ? 'lbs' : 'kg',
                  hintText: isUs ? '143.0' : '65.0',
                ),
                onChanged: (val) {
                  final parsed = double.tryParse(val);
                  if (parsed != null) {
                    final kg = isUs ? UnitConverter.lbToKg(parsed) : parsed;
                    setState(() => _local = local.copyWith(targetWeightKg: kg));
                  }
                },
              ),
              const SizedBox(height: 20),
              SettingsLabel(l10n.healthActivityLevel),
              const SizedBox(height: 12),
              Column(
                children: activityOptions.map((opt) {
                  final sel = local.activityLevel == opt.$1;
                  return RadioListTile<String>(
                    title: Text(opt.$2),
                    secondary: Icon(opt.$3, size: 20),
                    value: opt.$1,
                    groupValue: local.activityLevel,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _local = local.copyWith(activityLevel: val));
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_local == null) return;
    setState(() => _saving = true);
    try {
      await ref.read(healthProfileProvider.notifier).save(_local!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil enregistré avec succès !')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
