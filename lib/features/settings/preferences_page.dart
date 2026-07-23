// lib/features/settings/preferences_page.dart

import 'dart:ui';
import 'package:akeli/core/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/user_preferences_provider.dart';
import '../../providers/mode_provider.dart';
import '../../shared/models/user_preferences.dart';
import 'widgets/allergen_picker_widget.dart';
import 'widgets/settings_widgets.dart';
import 'saved_recipes_eligibility_page.dart';

class PreferencesPage extends ConsumerStatefulWidget {
  const PreferencesPage({super.key});

  @override
  ConsumerState<PreferencesPage> createState() => _PreferencesPageState();
}

class _PreferencesPageState extends ConsumerState<PreferencesPage> {
  UserPreferencesModel? _localPrefs;
  bool _saving = false;
  final _logger = appLogger;

  @override
  Widget build(BuildContext context) {
    _logger.provider('PreferencesPage build()');
    final l10n = AppLocalizations.of(context);
    final prefsAsync = ref.watch(userPreferencesProvider);

    final cookingTimeOptions = [
      ('quick',  l10n.preferencesCookingTimeQuick,  Icons.bolt_rounded),
      ('medium', l10n.preferencesCookingTimeMedium, Icons.timer_outlined),
      ('any',    l10n.preferencesCookingTimeAny,    Icons.all_inclusive_rounded),
    ];

    final regionOptions = [
      ('west_africa',    l10n.preferencesRegionWestAfrica),
      ('east_africa',    l10n.preferencesRegionEastAfrica),
      ('north_africa',   l10n.preferencesRegionNorthAfrica),
      ('central_africa', l10n.preferencesRegionCentralAfrica),
      ('south_africa',   l10n.preferencesRegionSouthAfrica),
      ('caribbean',      l10n.preferencesRegionCaribbean),
      ('occidental',     l10n.preferencesRegionWestern),
    ];

    return prefsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        body: Center(child: Text('${l10n.preferencesError}: $e')),
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
                      Text(
                        ref.watch(currentModeProvider) == AppMode.beauty ? 'Préférences Cosmétiques & Soins' : l10n.preferencesTitle,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: getAppModeColor(ref.watch(currentModeProvider)),
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
                // ── Meal plan ───────────────────────────────────────────────
                SettingsSectionHeader(title: l10n.preferencesMealPlanSection),
                const SizedBox(height: 8),
                SettingsCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bookmark_rounded, color: AkeliColors.primary),
                    title: Text(
                      l10n.preferencesMealPlanFromFavorites,
                      style: const TextStyle(fontWeight: FontWeight.w500, color: AkeliColors.onSurface),
                    ),
                    subtitle: Text(
                      l10n.preferencesMealPlanFromFavoritesDesc,
                      style: const TextStyle(fontSize: 13, color: AkeliColors.onSurfaceVariant),
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AkeliColors.onSurfaceVariant),
                    onTap: () {
                      _logger.userAction('Navigate to SavedRecipesEligibilityPage', screen: 'PreferencesPage');
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedRecipesEligibilityPage()),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // ── Cooking ─────────────────────────────────────────────────
                SettingsSectionHeader(title: l10n.preferencesCookingSection),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SettingsLabel(l10n.preferencesCookingTimeLabel),
                      const SizedBox(height: 12),
                      ...cookingTimeOptions.map((opt) {
                        final (value, label, icon) = opt;
                        return SettingsRadioRow(
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
                      SettingsLabel(l10n.preferencesBatchCookingLabel),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.preferencesBatchCookingDesc,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AkeliColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  l10n.preferencesBatchCookingDetail,
                                  style: const TextStyle(
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
                                _localPrefs = local.copyWith(batchCookingEnabled: v);
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
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      l10n.preferencesBatchPortions,
                                      style: const TextStyle(
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
                                        _logger.userAction('Batch max portions changed',
                                            screen: 'PreferencesPage',
                                            metadata: {'portions': v});
                                        setState(() {
                                          _localPrefs = local.copyWith(batchMaxPortions: v);
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

                // ── Cuisine region ───────────────────────────────────────────
                SettingsSectionHeader(title: l10n.preferencesCuisineSection),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: regionOptions.map((opt) {
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
                        selectedColor: AkeliColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AkeliColors.primary,
                        labelStyle: TextStyle(
                          color: selected ? AkeliColors.primary : AkeliColors.onSurface,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // ── Dietary restrictions ─────────────────────────────────────
                SettingsSectionHeader(title: l10n.preferencesDietSection),
                const SizedBox(height: 8),
                SettingsCard(
                  child: Column(
                    children: [
                      _ToggleRow(
                        label: l10n.preferencesNoPork,
                        icon: Icons.no_meals_rounded,
                        value: local.noPork,
                        onChanged: (v) {
                          _logger.userAction('noPork toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(() => _localPrefs = local.copyWith(noPork: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: l10n.preferencesNoMeat,
                        icon: Icons.grass_rounded,
                        value: local.noMeat,
                        onChanged: (v) {
                          _logger.userAction('noMeat toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(() => _localPrefs = local.copyWith(noMeat: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: l10n.preferencesNoGluten,
                        icon: Icons.grain_rounded,
                        value: local.noGluten,
                        onChanged: (v) {
                          _logger.userAction('noGluten toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(() => _localPrefs = local.copyWith(noGluten: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      _ToggleRow(
                        label: l10n.preferencesNoLactose,
                        icon: Icons.water_drop_outlined,
                        value: local.noLactose,
                        onChanged: (v) {
                          _logger.userAction('noLactose toggled',
                              screen: 'PreferencesPage',
                              metadata: {'value': v});
                          setState(() => _localPrefs = local.copyWith(noLactose: v));
                        },
                      ),
                      const Divider(height: 1, indent: 48),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.preferencesAllergens,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AkeliColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            AllergenPickerWidget(
                              selectedAllergens: local.allergens,
                              onChanged: (updated) {
                                setState(() {
                                  _localPrefs = local.copyWith(allergens: updated);
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // ── Save button ──────────────────────────────────────────────
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
                        : Text(
                            l10n.preferencesSave,
                            style: const TextStyle(
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
    final l10n = AppLocalizations.of(context);
    setState(() => _saving = true);
    try {
      await ref.read(userPreferencesProvider.notifier).save(_localPrefs!);
      _localPrefs = null;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.preferencesSaved)),
        );
        context.pop();
      }
    } catch (e, st) {
      _logger.provider('PreferencesPage save error | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.preferencesError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

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
