import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final isPremium = ref.watch(isPremiumProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettings(context, ref),
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
                        CircleAvatar(
                          radius: 48,
                          backgroundColor: AkeliColors.primary.withOpacity(0.1),
                          backgroundImage: profile?.avatarUrl != null
                              ? NetworkImage(profile!.avatarUrl!)
                              : null,
                          child: profile?.avatarUrl == null
                              ? Text(
                                  (profile != null && profile.displayName.isNotEmpty
                                          ? profile.displayName[0]
                                          : 'A')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: AkeliColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 36,
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _editProfile(context, ref),
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
                          color: AkeliColors.secondary.withOpacity(0.15),
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
                    onTap: () => _editProfile(context, ref),
                  ),
                  _MenuItem(
                    icon: Icons.monitor_weight_outlined,
                    label: 'Suivi nutritionnel',
                    onTap: () => context.push(AkeliRoutes.nutrition),
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
                    onTap: () => context.push(AkeliRoutes.subscription),
                  ),
                  _MenuItem(
                    icon: Icons.favorite_outline_rounded,
                    label: 'Mode Fan',
                    onTap: () => context.push(AkeliRoutes.fanMode),
                  ),
                ],
              ),

              _Section(
                title: 'Application',
                items: [
                  _MenuItem(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Assistant IA',
                    onTap: () => context.push(AkeliRoutes.aiChat),
                  ),
                  _MenuItem(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.language_rounded,
                    label: 'Langue',
                    trailing: const Text('Français',
                        style: TextStyle(
                            color: AkeliColors.textSecondary, fontSize: 13)),
                    onTap: () {},
                  ),
                ],
              ),

              _Section(
                title: 'Support',
                items: [
                  _MenuItem(
                    icon: Icons.help_outline_rounded,
                    label: 'Aide & FAQ',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.privacy_tip_outlined,
                    label: 'Politique de confidentialité',
                    onTap: () {},
                  ),
                  _MenuItem(
                    icon: Icons.description_outlined,
                    label: 'Conditions d\'utilisation',
                    onTap: () {},
                  ),
                ],
              ),

              // Sign out
              Padding(
                padding: const EdgeInsets.all(AkeliSpacing.lg),
                child: OutlinedButton.icon(
                  onPressed: () => _signOut(context, ref),
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
              onPressed: () => Navigator.pop(ctx, false),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.lg, AkeliSpacing.xs),
          child: Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(color: AkeliColors.textSecondary)),
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

  @override
  void initState() {
    super.initState();
    final profile = ref.read(userProfileProvider).valueOrNull;
    if (profile != null) {
      _nameCtrl.text = profile.username ?? '';
      _bioCtrl.text = profile.bio ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                onPressed: () => Navigator.pop(context),
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
            onPressed: _saving ? null : _save,
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
