import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/widgets/avatar.dart';
import '../../shared/widgets/section_header.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);
    appLogger.provider('ProfilePage build() | isPremium: $isPremium');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: const Text('Mon profil'),
        backgroundColor: AkeliColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              appLogger.userAction('Settings button tapped', screen: 'ProfilePage');
              _showSettings(context, ref);
            },
            tooltip: 'Paramètres',
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur: $err')),
        data: (profile) => SingleChildScrollView(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AkeliSpacing.xl),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        AkeliAvatar(
                          imageUrl: profile?.avatarUrl,
                          initials: (profile?.displayName.isNotEmpty == true
                                  ? profile!.displayName[0]
                                  : 'A')
                              .toUpperCase(),
                          size: AvatarSize.lg,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () {
                              appLogger.userAction('Edit profile avatar tapped', screen: 'ProfilePage');
                              _editProfile(context, ref);
                            },
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: AkeliColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AkeliSpacing.md),
                    Text(
                      profile?.displayName ?? 'Utilisateur',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    if (isPremium) ...[
                      const SizedBox(height: AkeliSpacing.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AkeliSpacing.sm, vertical: 4),
                        decoration: BoxDecoration(
                          color: AkeliColors.secondary.withValues(alpha: 0.15),
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.full),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: AkeliColors.secondary, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Premium',
                              style: TextStyle(
                                  color: AkeliColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const Divider(height: 1),

              // Menu sections
              _Section(
                title: 'Mon compte',
                items: [
                  _MenuItem(
                    icon: Icons.person_outline_rounded,
                    label: 'Modifier mon profil',
                    onTap: () {
                      appLogger.userAction('Edit profile menu tapped', screen: 'ProfilePage');
                      _editProfile(context, ref);
                    },
                  ),
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
                    trailing: const Text('Français',
                        style: TextStyle(
                            color: AkeliColors.textSecondary, fontSize: 13)),
                    onTap: () {
                      appLogger.userAction('Language menu tapped', screen: 'ProfilePage');
                    },
                  ),
                ],
              ),

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

              // Sign out
              Padding(
                padding: const EdgeInsets.all(AkeliSpacing.lg),
                child: OutlinedButton.icon(
                  onPressed: () {
                    appLogger.userAction('Sign out button tapped', screen: 'ProfilePage');
                    _signOut(context, ref);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Se déconnecter'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AkeliColors.error,
                    side: const BorderSide(color: AkeliColors.error),
                  ),
                ),
              ),

              const SizedBox(height: AkeliSpacing.lg),
              Text(
                'Akeli V1.0',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AkeliColors.textSecondary),
              ),
              const SizedBox(height: AkeliSpacing.xl),
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
        title: const Text('Se déconnecter'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () {
                appLogger.userAction('Sign out cancelled', screen: 'ProfilePage');
                Navigator.pop(ctx, false);
              },
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: AkeliColors.error),
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
          padding: const EdgeInsets.fromLTRB(
              AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.xs),
          child: AkeliSectionHeader(
            title: title,
            color: AkeliColors.textSecondary,
          ),
        ),
        ...items,
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
    return ListTile(
      leading: Icon(icon, color: AkeliColors.textPrimary),
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      trailing: trailing ??
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: AkeliColors.textSecondary),
      onTap: onTap,
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _EditProfileSheet({required this.ref});

  @override
  ConsumerState<_EditProfileSheet> createState() =>
      _EditProfileSheetState();
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
    return Padding(
      padding: EdgeInsets.only(
        left: AkeliSpacing.lg,
        right: AkeliSpacing.lg,
        top: AkeliSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AkeliSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Modifier le profil',
                  style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  _logger.userAction('Edit profile sheet closed', screen: 'ProfilePage');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Prénom / Pseudo',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: AkeliSpacing.md),
          TextField(
            controller: _bioCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio (optionnel)',
              prefixIcon: Icon(Icons.edit_outlined),
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AkeliSpacing.lg),
          FilledButton(
            onPressed: _saving ? null : () {
              _logger.userAction('Save profile button tapped', screen: 'ProfilePage');
              _save();
            },
            child: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Enregistrer'),
          ),
        ],
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
