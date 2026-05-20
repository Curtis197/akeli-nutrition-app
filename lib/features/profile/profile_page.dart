import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/widgets/avatar.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);
    appLogger.provider('ProfilePage build() | isPremium: $isPremium');

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
                    child: const BackButton(color: AkeliColors.onSurfaceVariant),
                  ),
                  const Text(
                    'Akeli Oasis',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.primary,
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
        error: (err, _) => Center(child: Text('Erreur: $err')),
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
                            AkeliColors.primary.withValues(alpha: 0.15),
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
                            gradient: const LinearGradient(
                              colors: [AkeliColors.primary, AkeliColors.primaryContainer],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AkeliColors.primary.withValues(alpha: 0.2),
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
                          profile?.displayName ?? 'Utilisateur',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AkeliColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          profile?.bio?.isNotEmpty == true
                              ? profile!.bio!
                              : 'Curating wellness & culinary serenity.',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (isPremium) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AkeliColors.secondary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.star_rounded, color: AkeliColors.secondary, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  'Premium',
                                  style: TextStyle(color: AkeliColors.secondary, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () {
                                  appLogger.userAction('Edit profile button tapped', screen: 'ProfilePage');
                                  _editProfile(context, ref);
                                },
                                icon: const Icon(Icons.edit_rounded, size: 20),
                                label: const Text('Modifier', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AkeliColors.primary,
                                  foregroundColor: AkeliColors.onPrimary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  appLogger.userAction('Settings button tapped', screen: 'ProfilePage');
                                  _showSettings(context, ref);
                                },
                                icon: const Icon(Icons.settings_outlined, size: 20),
                                label: const Text('Paramètres', style: TextStyle(fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AkeliColors.primary,
                                  backgroundColor: AkeliColors.surfaceContainerLowest,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
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
                      title: 'Menu',
                      items: [
                        _MenuItem(
                          icon: Icons.monitor_weight_outlined,
                          label: 'Suivi nutritionnel',
                          onTap: () {
                            appLogger.userAction('Nutrition tracking menu tapped', screen: 'ProfilePage');
                            context.push(AkeliRoutes.nutrition);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.star_outline_rounded,
                          label: 'Mon abonnement',
                          trailing: isPremium
                              ? const Chip(
                                  label: Text('Premium'),
                                  backgroundColor: AkeliColors.primary,
                                  labelStyle: TextStyle(color: Colors.white, fontSize: 11),
                                  padding: EdgeInsets.zero,
                                )
                              : null,
                          onTap: () {
                            appLogger.userAction('Subscription menu tapped', screen: 'ProfilePage');
                            context.push(AkeliRoutes.subscription);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.favorite_outline_rounded,
                          label: 'Mode Fan',
                          onTap: () {
                            appLogger.userAction('Fan mode menu tapped', screen: 'ProfilePage');
                            context.push(AkeliRoutes.fanMode);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Application',
                      items: [
                        _MenuItem(
                          icon: Icons.chat_bubble_outline_rounded,
                          label: 'Assistant IA',
                          onTap: () {
                            appLogger.userAction('AI assistant menu tapped', screen: 'ProfilePage');
                            context.push(AkeliRoutes.aiChat);
                          },
                        ),
                        _MenuItem(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          onTap: () {
                            appLogger.userAction('Notifications menu tapped', screen: 'ProfilePage');
                          },
                        ),
                        _MenuItem(
                          icon: Icons.language_rounded,
                          label: 'Langue',
                          trailing: const Text('Français', style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14)),
                          onTap: () {
                            appLogger.userAction('Language menu tapped', screen: 'ProfilePage');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _Section(
                      title: 'Support',
                      items: [
                        _MenuItem(
                          icon: Icons.help_outline_rounded,
                          label: 'Aide & FAQ',
                          onTap: () {
                            appLogger.userAction('Help FAQ menu tapped', screen: 'ProfilePage');
                          },
                        ),
                        _MenuItem(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Politique de confidentialité',
                          onTap: () {
                            appLogger.userAction('Privacy policy menu tapped', screen: 'ProfilePage');
                          },
                        ),
                        _MenuItem(
                          icon: Icons.description_outlined,
                          label: 'Conditions d\'utilisation',
                          onTap: () {
                            appLogger.userAction('Terms menu tapped', screen: 'ProfilePage');
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Sign out
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          appLogger.userAction('Sign out button tapped', screen: 'ProfilePage');
                          _signOut(context, ref);
                        },
                        icon: const Icon(Icons.logout_rounded),
                        label: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AkeliColors.error,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: AkeliColors.error.withValues(alpha: 0.3)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Akeli V1.0',
                      style: TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 12),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Se déconnecter', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () {
              appLogger.userAction('Sign out cancelled', screen: 'ProfilePage');
              Navigator.pop(ctx, false);
            },
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AkeliColors.error),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      appLogger.userAction('Sign out confirmed', screen: 'ProfilePage');
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

  void _showSettings(BuildContext context, WidgetRef ref) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Paramètres bientôt disponibles.')),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

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
  final _logger = appLogger;

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
                const Text(
                  'Modifier le profil',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AkeliColors.primary, letterSpacing: -0.5),
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
                      _logger.userAction('Edit profile sheet closed', screen: 'ProfilePage');
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
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
                  const Text('Nom', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AkeliColors.onSurface)),
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
                  const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AkeliColors.onSurface)),
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
                      decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 32), // Align icon to top
                          child: Icon(Icons.description_outlined, color: AkeliColors.outline),
                        ),
                        hintText: 'Parlez-nous un peu de vous...',
                        hintStyle: TextStyle(color: AkeliColors.outline),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
                _logger.userAction('Save profile button tapped', screen: 'ProfilePage');
                _save();
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                backgroundColor: AkeliColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                elevation: 4,
                shadowColor: AkeliColors.primary.withValues(alpha: 0.4),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('Enregistrer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    _logger.userAction('Profile save executed', screen: 'ProfilePage');
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

