// lib/features/settings/health_profile_page.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/health_profile_provider.dart';
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
  final _weightCtrl = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  static const _activityOptions = [
    ('sedentary', 'Sédentaire', Icons.weekend_outlined),
    ('light', 'Légèrement actif', Icons.directions_walk_rounded),
    ('moderate', 'Modérément actif', Icons.directions_bike_outlined),
    ('active', 'Actif', Icons.fitness_center_rounded),
    ('very_active', 'Très actif', Icons.bolt_rounded),
  ];

  static const _goalTypeOptions = [
    ('weight_loss', 'Perte de poids'),
    ('muscle_gain', 'Prise de muscle'),
    ('maintenance', 'Maintien'),
    ('health', 'Santé'),
    ('performance', 'Performance'),
  ];

  static const _weightGoalOptions = [
    ('loss', 'Perdre'),
    ('maintenance', 'Maintenir'),
    ('gain', 'Prendre'),
  ];

  static const _muscleGoalOptions = [
    ('loss', 'Perdre'),
    ('maintenance', 'Maintenir'),
    ('gain', 'Prendre'),
  ];

  static const _sexOptions = [
    ('male', 'Homme'),
    ('female', 'Femme'),
    ('other', 'Autre'),
  ];

  @override
  void dispose() {
    _logger.provider('HealthProfilePage disposed');
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  void _initControllers(HealthProfileModel prefs) {
    if (_heightCtrl.text.isEmpty && prefs.heightCm != null) {
      _heightCtrl.text = prefs.heightCm!.toStringAsFixed(1);
    }
    if (_weightCtrl.text.isEmpty && prefs.weightKg != null) {
      _weightCtrl.text = prefs.weightKg!.toStringAsFixed(1);
    }
    if (_targetWeightCtrl.text.isEmpty && prefs.targetWeightKg != null) {
      _targetWeightCtrl.text = prefs.targetWeightKg!.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('HealthProfilePage build()');
    final profileAsync = ref.watch(healthProfileProvider);

    return profileAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (prefs) {
        if (_local == null) {
          _local = prefs;
          _initControllers(prefs);
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
                      const Text(
                        'Santé & Objectifs',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.primary,
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
                // ── Paramètres de santé ──────────────────────────────────
                const SettingsSectionHeader(title: 'PARAMÈTRES DE SANTÉ'),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sexe
                      const SettingsLabel('Sexe'),
                      const SizedBox(height: 12),
                      _ChipSelector(
                        options: _sexOptions,
                        selected: local.sex,
                        onSelected: (v) {
                          _logger.userAction('Sex selected',
                              screen: 'HealthProfilePage',
                              metadata: {'value': v});
                          setState(() => _local = local.copyWith(sex: v));
                        },
                        onCleared: () {
                          _logger.userAction('Sex cleared',
                              screen: 'HealthProfilePage');
                          setState(() => _local = local.copyWith(clearSex: true));
                        },
                      ),

                      const Divider(height: 24),

                      // Date de naissance
                      const SettingsLabel('Date de naissance'),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () async {
                          _logger.userAction('Birth date tapped',
                              screen: 'HealthProfilePage');
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: local.birthDate ?? DateTime(1990, 1, 1),
                            firstDate: DateTime(1920),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            _logger.userAction('Birth date picked',
                                screen: 'HealthProfilePage',
                                metadata: {'date': picked.toIso8601String()});
                            setState(() =>
                                _local = local.copyWith(birthDate: picked));
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 20,
                                  color: AkeliColors.onSurfaceVariant),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  local.birthDate != null
                                      ? DateFormat('d MMMM yyyy', 'fr')
                                          .format(local.birthDate!)
                                      : 'Non renseignée',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: local.birthDate != null
                                        ? AkeliColors.onSurface
                                        : AkeliColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AkeliColors.outline, size: 20),
                            ],
                          ),
                        ),
                      ),

                      const Divider(height: 24),

                      // Taille
                      const SettingsLabel('Taille'),
                      const SizedBox(height: 8),
                      _NumericField(
                        controller: _heightCtrl,
                        suffix: 'cm',
                        onChanged: (v) {
                          _logger.userAction('Height changed',
                              screen: 'HealthProfilePage');
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() =>
                                _local = local.copyWith(heightCm: parsed));
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Poids actuel
                      const SettingsLabel('Poids actuel'),
                      const SizedBox(height: 8),
                      _NumericField(
                        controller: _weightCtrl,
                        suffix: 'kg',
                        onChanged: (v) {
                          _logger.userAction('Weight changed',
                              screen: 'HealthProfilePage');
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() =>
                                _local = local.copyWith(weightKg: parsed));
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Poids cible
                      const SettingsLabel('Poids cible'),
                      const SizedBox(height: 8),
                      _NumericField(
                        controller: _targetWeightCtrl,
                        suffix: 'kg',
                        onChanged: (v) {
                          _logger.userAction('Target weight changed',
                              screen: 'HealthProfilePage');
                          final parsed = double.tryParse(v);
                          if (parsed != null && parsed > 0) {
                            setState(() =>
                                _local = local.copyWith(targetWeightKg: parsed));
                          }
                        },
                      ),

                      const Divider(height: 24),

                      // Niveau d'activité
                      const SettingsLabel("Niveau d'activité"),
                      const SizedBox(height: 12),
                      ..._activityOptions.map((opt) {
                        final (value, label, icon) = opt;
                        return SettingsRadioRow(
                          icon: icon,
                          label: label,
                          selected: local.activityLevel == value,
                          onTap: () {
                            _logger.userAction('Activity level selected',
                                screen: 'HealthProfilePage',
                                metadata: {'value': value});
                            setState(() => _local =
                                local.copyWith(activityLevel: value));
                          },
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Objectif ─────────────────────────────────────────────
                const SettingsSectionHeader(title: 'OBJECTIF'),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type d'objectif
                      const SettingsLabel("Type d'objectif"),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _goalTypeOptions.map((opt) {
                          final (code, name) = opt;
                          final selected = local.goalType == code;
                          return FilterChip(
                            label: Text(name),
                            selected: selected,
                            onSelected: (_) {
                              _logger.userAction('Goal type selected',
                                  screen: 'HealthProfilePage',
                                  metadata: {'goalType': code});
                              setState(() => selected
                                  ? _local =
                                      local.copyWith(clearGoalType: true)
                                  : _local = local.copyWith(goalType: code));
                            },
                            selectedColor:
                                AkeliColors.primary.withValues(alpha: 0.15),
                            checkmarkColor: AkeliColors.primary,
                            labelStyle: TextStyle(
                              color: selected
                                  ? AkeliColors.primary
                                  : AkeliColors.onSurface,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                      ),

                      const Divider(height: 24),

                      // Objectif poids
                      const SettingsLabel('Objectif poids'),
                      const SizedBox(height: 12),
                      _ChipSelector(
                        options: _weightGoalOptions,
                        selected: local.weightGoal,
                        onSelected: (v) {
                          _logger.userAction('Weight goal selected',
                              screen: 'HealthProfilePage',
                              metadata: {'value': v});
                          setState(() => _local = local.copyWith(weightGoal: v));
                        },
                        onCleared: () {
                          _logger.userAction('Weight goal cleared',
                              screen: 'HealthProfilePage');
                          setState(() =>
                              _local = local.copyWith(clearWeightGoal: true));
                        },
                      ),

                      const Divider(height: 24),

                      // Objectif muscle
                      const SettingsLabel('Objectif muscle'),
                      const SizedBox(height: 12),
                      _ChipSelector(
                        options: _muscleGoalOptions,
                        selected: local.muscleGoal,
                        onSelected: (v) {
                          _logger.userAction('Muscle goal selected',
                              screen: 'HealthProfilePage',
                              metadata: {'value': v});
                          setState(() => _local = local.copyWith(muscleGoal: v));
                        },
                        onCleared: () {
                          _logger.userAction('Muscle goal cleared',
                              screen: 'HealthProfilePage');
                          setState(() =>
                              _local = local.copyWith(clearMuscleGoal: true));
                        },
                      ),

                      const Divider(height: 24),

                      // Durée cible
                      const SettingsLabel('Durée cible'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: (local.targetTimeWeeks ?? 12).toDouble(),
                              min: 4,
                              max: 52,
                              divisions: 48,
                              activeColor: AkeliColors.primary,
                              label:
                                  '${local.targetTimeWeeks ?? 12} semaines',
                              onChanged: (v) {
                                _logger.userAction('Target weeks changed',
                                    screen: 'HealthProfilePage',
                                    metadata: {'weeks': v.round()});
                                setState(() => _local = local.copyWith(
                                    targetTimeWeeks: v.round()));
                              },
                            ),
                          ),
                          SizedBox(
                            width: 72,
                            child: Text(
                              '${local.targetTimeWeeks ?? 12} sem.',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AkeliColors.primary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Save button ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Enregistrer',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
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

  Future<void> _save() async {
    if (_local == null) return;
    _logger.userAction('HealthProfilePage save tapped',
        screen: 'HealthProfilePage');
    final saved = _local!;
    setState(() => _saving = true);
    try {
      await ref.read(healthProfileProvider.notifier).save(saved);
      _local = null;
      if (mounted) {
        final kcal = computeCalorieGoal(saved);
        final msg = kcal != null
            ? 'Profil mis à jour · $kcal kcal/jour'
            : 'Profil mis à jour';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        context.pop();
      }
    } catch (e, st) {
      _logger.provider('HealthProfilePage save error | $e',
          error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _ChipSelector extends StatelessWidget {
  final List<(String, String)> options;
  final String? selected;
  final ValueChanged<String> onSelected;
  final VoidCallback onCleared;

  const _ChipSelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    required this.onCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final (code, name) = opt;
        final isSelected = selected == code;
        return ChoiceChip(
          label: Text(name),
          selected: isSelected,
          onSelected: (_) => isSelected ? onCleared() : onSelected(code),
          selectedColor: AkeliColors.primary.withValues(alpha: 0.15),
          checkmarkColor: AkeliColors.primary,
          labelStyle: TextStyle(
            color: isSelected ? AkeliColors.primary : AkeliColors.onSurface,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }
}

class _NumericField extends StatelessWidget {
  final TextEditingController controller;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _NumericField({
    required this.controller,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: AkeliColors.onSurfaceVariant,
          fontSize: 15,
        ),
        filled: true,
        fillColor: AkeliColors.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: const TextStyle(
        fontSize: 15,
        color: AkeliColors.onSurface,
      ),
      onChanged: onChanged,
    );
  }
}
