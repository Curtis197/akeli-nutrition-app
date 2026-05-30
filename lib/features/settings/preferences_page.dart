// lib/features/settings/preferences_page.dart

import 'dart:ui';
import 'package:akeli/core/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/user_preferences_provider.dart';
import '../../shared/models/user_preferences.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  UserPreferencesModel? _localPrefs;
  bool _saving = false;
  final _logger = appLogger;

  static const _cookingTimeOptions = [
    ('quick', 'Rapide (< 30 min)', Icons.bolt_rounded),
    ('medium', 'Moyen (30–60 min)', Icons.timer_outlined),
    ('any', 'Peu importe', Icons.all_inclusive_rounded),
  ];

  static const _regionOptions = [
    ('west_africa', 'Afrique de l\'Ouest'),
    ('east_africa', 'Afrique de l\'Est'),
    ('north_africa', 'Afrique du Nord'),
    ('central_africa', 'Afrique Centrale'),
    ('south_africa', 'Afrique du Sud'),
    ('caribbean', 'Caraïbes'),
    ('occidental', 'Occidental'),
  ];

  @override
  Widget build(BuildContext context) {
    _logger.provider('PreferencesPage build()');
    final prefsAsync = ref.watch(userPreferencesProvider);

    return prefsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('Erreur: $e')),
      ),
      data: (prefs) {
        _localPrefs ??= prefs;
        final local = _localPrefs!;

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
                            _logger.userAction('PreferencesPage back tapped',
                                screen: 'PreferencesPage');
                            if (context.canPop()) context.pop();
                          },
                        ),
                      ),
                      const Text(
                        'Préférences',
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
                // ── Cuisson ─────────────────────────────────────────────
                const _SectionHeader(title: 'CUISSON'),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _Label('Temps de préparation'),
                      const SizedBox(height: 12),
                      ..._cookingTimeOptions.map((opt) {
                        final (value, label, icon) = opt;
                        return _RadioRow(
                          icon: icon,
                          label: label,
                          selected: local.cookingTime == value,
                          onTap: () {
                            _logger.userAction('Cooking time selected',
                                screen: 'PreferencesPage',
                                metadata: {'value': value});
                            setState(() {
                              _localPrefs = local.copyWith(cookingTime: value);
                            });
                          },
                        );
                      }),
                      const Divider(height: 24),
                      const _Label('Cuisson en batch'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Préparer plusieurs repas à la fois',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AkeliColors.onSurface,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cuire en grande quantité pour la semaine',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AkeliColors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: local.batchCookingEnabled,
                            activeThumbColor: AkeliColors.primary,
                            onChanged: (v) {
                              _logger.userAction('Batch cooking toggled',
                                  screen: 'PreferencesPage',
                                  metadata: {'enabled': v});
                              setState(() {
                                _localPrefs =
                                    local.copyWith(batchCookingEnabled: v);
                              });
                            },
                          ),
                        ],
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: local.batchCookingEnabled
                            ? Padding(
                                key: const ValueKey('portions'),
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Portions max par session',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: AkeliColors.onSurface,
                                      ),
                                    ),
                                    DropdownButton<int>(
                                      value: local.batchMaxPortions,
                                      underline: const SizedBox.shrink(),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AkeliColors.primary,
                                      ),
                                      items: List.generate(6, (i) => i + 2)
                                          .map((n) => DropdownMenuItem(
                                                value: n,
                                                child: Text('$n'),
                                              ))
                                          .toList(),
                                      onChanged: (v) {
                                        if (v == null) return;
                                        _logger.userAction(
                                            'Batch max portions changed',
                                            screen: 'PreferencesPage',
                                            metadata: {'portions': v});
                                        setState(() {
                                          _localPrefs = local.copyWith(
                                              batchMaxPortions: v);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(key: ValueKey('hidden')),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ── Région culinaire ─────────────────────────────────────
                const _SectionHeader(title: 'RÉGION CULINAIRE'),
                const SizedBox(height: 8),
                _Card(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _regionOptions.map((opt) {
                      final (code, name) = opt;
                      final selected = local.cuisineRegion == code;
                      return FilterChip(
                        label: Text(name),
                        selected: selected,
                        onSelected: (_) {
                          _logger.userAction('Region selected',
                              screen: 'PreferencesPage',
                              metadata: {'region': code});
                          setState(() {
                            _localPrefs = selected
                                ? local.copyWith(clearCuisineRegion: true)
                                : local.copyWith(cuisineRegion: code);
                          });
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
                ),

                const SizedBox(height: 24),

                // ── Restrictions alimentaires ─────────────────────────────
                const _SectionHeader(title: 'RESTRICTIONS ALIMENTAIRES'),
                const SizedBox(height: 8),
                _Card(
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: 'Sans porc',
                        icon: Icons.no_meals_rounded,
                        value: local.noPork,
                        onChanged: (v) {
                          _logger.userAction('noPork toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(
                              () => _localPrefs = local.copyWith(noPork: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: 'Sans viande',
                        icon: Icons.grass_rounded,
                        value: local.noMeat,
                        onChanged: (v) {
                          _logger.userAction('noMeat toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(
                              () => _localPrefs = local.copyWith(noMeat: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: 'Sans gluten',
                        icon: Icons.grain_rounded,
                        value: local.noGluten,
                        onChanged: (v) {
                          _logger.userAction('noGluten toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(
                              () => _localPrefs = local.copyWith(noGluten: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: 'Sans lactose',
                        icon: Icons.water_drop_outlined,
                        value: local.noLactose,
                        onChanged: (v) {
                          _logger.userAction('noLactose toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(() =>
                              _localPrefs = local.copyWith(noLactose: v));
                        },
                      ),
                      if (local.allergies.isNotEmpty) ...[
                        const Divider(height: 1, indent: 48),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Allergies',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AkeliColors.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                children: local.allergies
                                    .map((a) => Chip(label: Text(a)))
                                    .toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
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
    if (_localPrefs == null) return;
    _logger.userAction('PreferencesPage save tapped', screen: 'PreferencesPage');
    setState(() => _saving = true);
    try {
      await ref.read(userPreferencesProvider.notifier).save(_localPrefs!);
      _localPrefs = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Préférences enregistrées.')),
        );
        context.pop();
      }
    } catch (e, st) {
      _logger.provider('PreferencesPage save error | $e', error: e, stackTrace: st);
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

// ── Private widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

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

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

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

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

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

class _RadioRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _RadioRow(
      {required this.icon,
      required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
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

class _ToggleRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow(
      {required this.label,
      required this.icon,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AkeliColors.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 15, color: AkeliColors.onSurface)),
            ),
            Switch(
              value: value,
              activeThumbColor: AkeliColors.primary,
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
