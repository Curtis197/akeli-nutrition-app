import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends ConsumerState<AccountPage> {
  final _logger = appLogger;

  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _savingPassword = false;
  bool _deletingAccount = false;

  String? _passwordError;

  @override
  void initState() {
    super.initState();
    _logger.provider('AccountPage initState()');
  }

  @override
  void dispose() {
    _logger.provider('AccountPage disposed');
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? '';
    _logger.provider('AccountPage build() | email: ${LogHelper.maskEmail(email)}');

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
                          context.go(AkeliRoutes.settings);
                        }
                      },
                    ),
                  ),
                  const Text(
                    'Mon compte',
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Email section
            _SectionCard(
              title: 'Informations',
              child: _InfoRow(
                icon: Icons.email_outlined,
                label: 'Adresse e-mail',
                value: email,
              ),
            ),

            const SizedBox(height: 24),

            // Password section
            _SectionCard(
              title: 'Mot de passe',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _PasswordField(
                    controller: _currentPasswordCtrl,
                    label: 'Mot de passe actuel',
                    obscure: _obscureCurrent,
                    onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _newPasswordCtrl,
                    label: 'Nouveau mot de passe',
                    obscure: _obscureNew,
                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                  const SizedBox(height: 12),
                  _PasswordField(
                    controller: _confirmPasswordCtrl,
                    label: 'Confirmer le mot de passe',
                    obscure: _obscureConfirm,
                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  if (_passwordError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _passwordError!,
                      style: const TextStyle(color: AkeliColors.error, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _savingPassword ? null : _updatePassword,
                    style: FilledButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: AkeliColors.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _savingPassword
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Mettre à jour', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Danger zone
            _SectionCard(
              title: 'Zone dangereuse',
              titleColor: AkeliColors.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'La suppression de votre compte est irréversible. Toutes vos données seront effacées définitivement.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AkeliColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _deletingAccount ? null : _confirmDeleteAccount,
                    icon: _deletingAccount
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_forever_rounded),
                    label: const Text('Supprimer mon compte', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AkeliColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: AkeliColors.error.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePassword() async {
    _logger.userAction('Update password button tapped', screen: 'AccountPage');
    setState(() => _passwordError = null);

    final current = _currentPasswordCtrl.text.trim();
    final next = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = 'Veuillez remplir tous les champs.');
      return;
    }
    if (next.length < 8) {
      setState(() => _passwordError = 'Le mot de passe doit contenir au moins 8 caractères.');
      return;
    }
    if (next != confirm) {
      setState(() => _passwordError = 'Les mots de passe ne correspondent pas.');
      return;
    }

    setState(() => _savingPassword = true);
    try {
      await ref.read(authNotifierProvider.notifier).updatePassword(
            currentPassword: current,
            newPassword: next,
          );
      _logger.userAction('Password updated successfully', screen: 'AccountPage');
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mot de passe mis à jour avec succès.'),
            backgroundColor: AkeliColors.success,
          ),
        );
      }
    } on Exception catch (e) {
      _logger.auth('updatePassword ERROR | $e', error: e);
      if (mounted) {
        setState(() => _passwordError = _friendlyAuthError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    _logger.userAction('Delete account button tapped', screen: 'AccountPage');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Cette action est irréversible.\n\nToutes vos données, recettes, plans repas et historique seront définitivement supprimés.\n\nÊtes-vous sûr(e) de vouloir continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              _logger.userAction('Delete account cancelled', screen: 'AccountPage');
              Navigator.pop(ctx, false);
            },
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AkeliColors.error),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    _logger.userAction('Delete account confirmed', screen: 'AccountPage');
    setState(() => _deletingAccount = true);
    try {
      await ref.read(authNotifierProvider.notifier).deleteAccount();
    } catch (e, st) {
      _logger.auth('deleteAccount ERROR | $e', error: e, stackTrace: st);
      if (mounted) {
        setState(() => _deletingAccount = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la suppression. Veuillez réessayer.')),
        );
      }
    }
  }

  String _friendlyAuthError(String raw) {
    if (raw.contains('Invalid login credentials') || raw.contains('invalid_credentials')) {
      return 'Mot de passe actuel incorrect.';
    }
    if (raw.contains('too_many_requests')) {
      return 'Trop de tentatives. Veuillez patienter.';
    }
    return 'Une erreur est survenue. Veuillez réessayer.';
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Widget child;

  const _SectionCard({required this.title, required this.child, this.titleColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: titleColor ?? AkeliColors.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AkeliColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AkeliColors.onSurfaceVariant, size: 22),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant)),
            Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AkeliColors.onSurface)),
          ],
        ),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AkeliColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: AkeliColors.onSurfaceVariant, fontSize: 14),
          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AkeliColors.onSurfaceVariant, size: 20),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
            color: AkeliColors.onSurfaceVariant,
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: const TextStyle(fontSize: 15, color: AkeliColors.onSurface),
      ),
    );
  }
}
