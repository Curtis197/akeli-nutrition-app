import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/locale_provider.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/mode_provider.dart';
import '../../widgets/mode_selector.dart';
import '../../shared/widgets/avatar.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final localeState = ref.watch(localeProvider);
    final currentMode = ref.watch(currentModeProvider);
    final String currentLangText;
    if (localeState.isUsLocale) {
      currentLangText = l10n.preferencesLocaleUsImperial;
    } else if (localeState.languageCode == 'fr') {
      currentLangText = l10n.languageFrench;
    } else {
      currentLangText = l10n.languageEnglish;
    }
    appLogger.provider('SettingsPage build() | isPremium: $isPremium | currentLangText: $currentLangText');

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
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AkeliRoutes.profile);
                        }
                      },
                    ),
                  ),
                  Text(
                    l10n.settingsTitle,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 48), // Spacer for balance
                ],
              ),
            ),
          ),
        ),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(l10n.settingsAvatarError(err.toString()))),
        data: (profile) => SingleChildScrollView(
          child: Column(
            children: [
              // Header Section: Hero & Profile
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Decorative Gradient Background
                  Positioned(
                    top: -100,
                    left: -50,
                    right: -50,
                    height: 400,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            AkeliColors.surface.withValues(alpha: 0.8),
                            AkeliColors.tertiary.withValues(alpha: 0.05),
                          ],
                          radius: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + kToolbarHeight + 32,
                      left: 24,
                      right: 24,
                      bottom: 40,
                    ),
                    child: Column(
                      children: [
                        // Avatar
                        Container(
                          width: 120,
                          height: 120,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).colorScheme.primary,
                                Theme.of(context).colorScheme.primaryContainer,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              color: AkeliColors.surfaceContainerLowest,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: AkeliAvatar(
                                imageUrl: profile?.avatarUrl,
                                initials: (profile?.displayName.isNotEmpty == true
                                        ? profile!.displayName[0]
                                        : 'A')
                                    .toUpperCase(),
                                size: AvatarSize.lg,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Identity
                        Text(
                          profile?.displayName ?? '',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AkeliColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (profile?.bio?.isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            profile!.bio!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AkeliColors.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        if (isPremium) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AkeliColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.star_rounded, color: AkeliColors.secondary, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.settingsPremium,
                                  style: const TextStyle(color: AkeliColors.secondary, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              appLogger.userAction('Edit profile button tapped', screen: 'SettingsPage');
                              _editProfile(context, ref);
                            },
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: Text(l10n.settingsEdit, style: const TextStyle(fontWeight: FontWeight.bold)),
                            style: FilledButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: AkeliColors.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Content Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 24, bottom: 48, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerLowest,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 48,
                      offset: const Offset(0, -8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _Section(
                      title: l10n.settingsSectionMenu,
                      items: [
                        _MenuItem(
                          icon: currentMode == AppMode.beauty ? Icons.spa_outlined : Icons.monitor_weight_outlined,
                          label: currentMode == AppMode.beauty ? 'Suivi Rituel Beauté' : l10n.settingsNutritionTracking,
                          onTap: () {
                            if (currentMode == AppMode.beauty) {
                              appLogger.userAction('Beauty tracking menu tapped', screen: 'SettingsPage');
                              context.push(AkeliRoutes.beautyAnalytics);
                            } else {
                              appLogger.userAction('Nutrition tracking menu tapped', screen: 'SettingsPage');
                              context.push(AkeliRoutes.nutrition);
                            }
                          },
                        ),
                        _MenuItem(
                          icon: currentMode == AppMode.beauty ? Icons.auto_awesome_outlined : Icons.bookmark_outline_rounded,
                          label: currentMode == AppMode.beauty ? 'Remèdes & Recettes Favoris' : l10n.settingsSavedRecipes,
                          onTap: () {
                            appLogger.userAction('Saved recipes menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.savedRecipes);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.manage_accounts_outlined,
                          label: l10n.settingsAccount,
                          onTap: () {
                            appLogger.userAction('Account menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.account);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.favorite_outline_rounded,
                          label: l10n.settingsFanMode,
                          onTap: () {
                            appLogger.userAction('Fan mode menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.fanMode);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.tune_rounded,
                          label: l10n.settingsPreferences,
                          onTap: () {
                            appLogger.userAction('Preferences menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.preferences);
                          },
                        ),
                        _MenuItem(
                          icon: currentMode == AppMode.beauty ? Icons.face_retouching_natural_outlined : Icons.monitor_heart_outlined,
                          label: currentMode == AppMode.beauty ? 'Diagnostic Cheveux & Peau' : l10n.settingsHealthGoals,
                          onTap: () {
                            appLogger.userAction('Health profile menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.healthProfile);
                          },
                        ),
                        _MenuItem(
                          icon: currentMode == AppMode.beauty ? Icons.calendar_month_outlined : Icons.restaurant_outlined,
                          label: currentMode == AppMode.beauty ? 'Planification des Soins' : l10n.mealScheduleTitle,
                          onTap: () {
                            appLogger.userAction('Meal schedule settings tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.mealSchedule);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: l10n.settingsSectionApp,
                      items: [
                        _MenuItem(
                          icon: getAppModeIcon(ref.watch(currentModeProvider)),
                          label: 'Mode d\'application (SDUI)',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: getAppModeColor(ref.watch(currentModeProvider)).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  ref.watch(currentModeProvider).displayName,
                                  style: TextStyle(
                                    color: getAppModeColor(ref.watch(currentModeProvider)),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.unfold_more_rounded, size: 16, color: getAppModeColor(ref.watch(currentModeProvider))),
                              ],
                            ),
                          ),
                          onTap: () {
                            showModeSelectorDialog(context, ref);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: l10n.settingsNotifications,
                          onTap: () {
                            appLogger.userAction('Notifications menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.notificationSettings);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.language_rounded,
                          label: l10n.settingsLanguage,
                          trailing: Text(currentLangText, style: const TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14)),
                          onTap: () {
                            appLogger.userAction('Language menu tapped', screen: 'SettingsPage');
                            showDialog<void>(
                              context: context,
                              builder: (ctx) {
                                final dialogL10n = AppLocalizations.of(ctx);
                                return AlertDialog(
                                  title: Text(dialogL10n.languageSelectorTitle),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        title: Text(dialogL10n.languageEnglish),
                                        onTap: () {
                                          appLogger.userAction('Language selected: en', screen: 'SettingsPage');
                                          ref.read(localeProvider.notifier).setLocale(const Locale('en'));
                                          ref.invalidate(recipeDetailProvider);
                                          ref.invalidate(activeMealPlanProvider);
                                          ref.invalidate(shoppingListProvider);
                                          ref.invalidate(cookingSessionsProvider);
                                          Navigator.pop(ctx);
                                        },
                                      ),
                                      ListTile(
                                        title: Text(dialogL10n.languageFrench),
                                        onTap: () {
                                          appLogger.userAction('Language selected: fr', screen: 'SettingsPage');
                                          ref.read(localeProvider.notifier).setLocale(const Locale('fr'));
                                          ref.invalidate(recipeDetailProvider);
                                          ref.invalidate(activeMealPlanProvider);
                                          ref.invalidate(shoppingListProvider);
                                          ref.invalidate(cookingSessionsProvider);
                                          Navigator.pop(ctx);
                                        },
                                      ),
                                      ListTile(
                                        title: Text(dialogL10n.preferencesLocaleUsImperial),
                                        onTap: () {
                                          appLogger.userAction('Language selected: en-US', screen: 'SettingsPage');
                                          ref.read(localeProvider.notifier).setLocale(const Locale('en', 'US'));
                                          ref.invalidate(recipeDetailProvider);
                                          ref.invalidate(activeMealPlanProvider);
                                          ref.invalidate(shoppingListProvider);
                                          ref.invalidate(cookingSessionsProvider);
                                          Navigator.pop(ctx);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: l10n.settingsSectionPrivacy,
                      items: [
                        _SwitchItem(
                          icon: Icons.lock_outline_rounded,
                          label: l10n.settingsPrivateProfile,
                          value: profile?.isPrivate ?? false,
                          onChanged: (val) {
                            appLogger.userAction('Private profile toggled',
                                screen: 'SettingsPage',
                                metadata: {'isPrivate': val});
                            ref.read(userProfileNotifierProvider.notifier)
                                .updateProfile(isPrivate: val);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: l10n.settingsSectionSupport,
                      items: [
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: l10n.settingsHelpFaq,
                          onTap: () {
                            appLogger.userAction('Help FAQ menu tapped', screen: 'SettingsPage');
                            context.push(AkeliRoutes.support);
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () {
                                  appLogger.userAction('Privacy policy link tapped', screen: 'SettingsPage');
                                  context.push(AkeliRoutes.privacyPolicy);
                                },
                                child: Text(
                                  l10n.settingsPrivacyPolicy,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: () {
                                  appLogger.userAction('Terms link tapped', screen: 'SettingsPage');
                                  context.push(AkeliRoutes.termsOfService);
                                },
                                child: Text(
                                  l10n.settingsTerms,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).colorScheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          appLogger.userAction('Sign out button tapped', screen: 'SettingsPage');
                          _signOut(context, ref);
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: Text(l10n.settingsSignOut, style: const TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AkeliColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AkeliColors.error.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      l10n.appVersion,
                      style: const TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(l10n.settingsSignOutTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(l10n.settingsSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () {
              appLogger.userAction('Sign out cancelled', screen: 'SettingsPage');
              Navigator.pop(ctx, false);
            },
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AkeliColors.error),
            child: Text(l10n.settingsSignOutConfirmBtn),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      appLogger.userAction('Sign out confirmed', screen: 'SettingsPage');
      await ref.read(authNotifierProvider.notifier).signOut();
    }
  }

  void _editProfile(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditProfileSheet(ref: ref),
    );
  }


}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> items;

  const _Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    appLogger.d('ProfileSection build() | title: $title');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AkeliColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AkeliColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(height: 1, indent: 48, color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _SwitchItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: AkeliColors.onSurfaceVariant, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AkeliColors.onSurface)),
          ),
          Switch(value: value, onChanged: onChanged, activeThumbColor: Theme.of(context).colorScheme.primary),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    appLogger.d('ProfileMenuItem build() | label: $label');
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AkeliColors.onSurfaceVariant, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, color: AkeliColors.onSurface, fontWeight: FontWeight.w500),
                ),
              ),
              if (trailing != null) trailing!,
              if (trailing == null)
                const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AkeliColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _EditProfileSheet({required this.ref});

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  final _nameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();
  bool _saving = false;
  bool _isUploading = false;
  final _logger = appLogger;

  Future<void> _pickAndUploadImage() async {
    final l10n = AppLocalizations.of(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _isUploading = true);
      _logger.userAction('Avatar upload started', screen: 'SettingsPage');
      try {
        await ref.read(userProfileNotifierProvider.notifier).updateAvatar(File(pickedFile.path));
        _logger.userAction('Avatar upload success', screen: 'SettingsPage');
      } catch (e, st) {
        _logger.db('ERROR | avatar upload | $e', error: e, stackTrace: st);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.settingsAvatarError(e.toString()))));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _logger.provider('EditProfileSheet initState()');
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      _nameCtrl.text = profile.username ?? '';
      _bioCtrl.text = profile.bio ?? '';
    }
  }

  @override
  void dispose() {
    _logger.provider('EditProfileSheet disposed');
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('EditProfileSheet build()');
    final l10n = AppLocalizations.of(context);
    return Container(
      decoration: const BoxDecoration(
        color: AkeliColors.background,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(32), topRight: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 32,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  l10n.settingsEditProfile,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, letterSpacing: -0.5),
                ),
                const Spacer(),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.close_rounded, color: AkeliColors.onSurfaceVariant),
                    onPressed: () {
                      _logger.userAction('Edit profile sheet closed', screen: 'SettingsPage');
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _isUploading ? null : _pickAndUploadImage,
                child: Stack(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: const BoxDecoration(
                        color: AkeliColors.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: AkeliAvatar(
                          imageUrl: ref.watch(userProfileProvider).valueOrNull?.avatarUrl,
                          initials: (ref.watch(userProfileProvider).valueOrNull?.displayName.isNotEmpty == true
                                  ? ref.watch(userProfileProvider).valueOrNull!.displayName[0]
                                  : 'A')
                              .toUpperCase(),
                          size: AvatarSize.lg,
                        ),
                      ),
                    ),
                    if (_isUploading)
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        ),
                      ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AkeliColors.background, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AkeliColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 32, offset: const Offset(0, 12)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.settingsName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AkeliColors.onSurface)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, color: AkeliColors.outline),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 16, color: AkeliColors.onSurface),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(l10n.settingsDescription, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AkeliColors.onSurface)),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
                    ),
                    child: TextField(
                      controller: _bioCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 32), // Align icon to top
                          child: Icon(Icons.description_outlined, color: AkeliColors.outline),
                        ),
                        hintText: l10n.settingsDescriptionHint,
                        hintStyle: const TextStyle(color: AkeliColors.outline),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      style: const TextStyle(fontSize: 16, color: AkeliColors.onSurface),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : () {
                _logger.userAction('Save profile button tapped', screen: 'SettingsPage');
                _save();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: Theme.of(context).colorScheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 4,
                shadowColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : Text(l10n.settingsSave, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    _logger.userAction('Profile save executed', screen: 'SettingsPage');
    setState(() => _saving = true);
    try {
      await ref.read(userProfileNotifierProvider.notifier).updateProfile(
            username: _nameCtrl.text.trim(),
            bio: _bioCtrl.text.trim(),
          );
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

