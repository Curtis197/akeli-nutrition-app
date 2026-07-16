import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final email = user?.email ?? '';
    final providers =
        (user?.appMetadata['providers'] as List?)?.cast<String>() ?? const <String>[];
    // No providers info → assume email auth (fail open so the section stays usable).
    final canChangePassword = providers.isEmpty || providers.contains('email');
    _logger.provider(
      'AccountPage build() | email: ${LogHelper.maskEmail(email)} | canChangePassword: $canChangePassword',
    );

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
                  Text(
                    l10n.accountTitle,
                    style: const TextStyle(
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
            _SectionCard(
              title: l10n.accountInfoSection,
              child: _InfoRow(
                icon: Icons.email_outlined,
                label: l10n.accountEmail,
                value: email,
              ),
            ),

            if (canChangePassword) ...[
              const SizedBox(height: 24),

              _SectionCard(
                title: l10n.accountPasswordSection,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _PasswordField(
                      controller: _currentPasswordCtrl,
                      label: l10n.accountCurrentPassword,
                      obscure: _obscureCurrent,
                      onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _newPasswordCtrl,
                      label: l10n.accountNewPassword,
                      obscure: _obscureNew,
                      onToggle: () => setState(() => _obscureNew = !_obscureNew),
                    ),
                    const SizedBox(height: 12),
                    _PasswordField(
                      controller: _confirmPasswordCtrl,
                      label: l10n.accountConfirmPassword,
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
                          : Text(l10n.accountUpdatePassword,
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            _SectionCard(
              title: l10n.accountDangerZone,
              titleColor: AkeliColors.error,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.accountDeleteConfirmContent,
                    style: const TextStyle(
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
                    label: Text(l10n.accountDeleteAccount,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
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
    final l10n = AppLocalizations.of(context);
    setState(() => _passwordError = null);

    final current = _currentPasswordCtrl.text.trim();
    final next = _newPasswordCtrl.text.trim();
    final confirm = _confirmPasswordCtrl.text.trim();

    if (current.isEmpty || next.isEmpty || confirm.isEmpty) {
      setState(() => _passwordError = l10n.accountPasswordRequired);
      return;
    }
    if (next.length < 8) {
      setState(() => _passwordError = l10n.accountPasswordTooShort);
      return;
    }
    if (next != confirm) {
      setState(() => _passwordError = l10n.accountPasswordMismatch);
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
          SnackBar(
            content: Text(l10n.accountPasswordUpdated),
            backgroundColor: AkeliColors.success,
          ),
        );
      }
    } on Exception catch (e) {
      _logger.auth('updatePassword ERROR | $e', error: e);
      if (mounted) {
        setState(() => _passwordError = _friendlyAuthError(l10n, e.toString()));
      }
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  Future<void> _confirmDeleteAccount() async {
    _logger.userAction('Delete account button tapped', screen: 'AccountPage');
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          l10n.accountDeleteConfirmTitle,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(l10n.accountDeleteConfirmContent),
        actions: [
          TextButton(
            onPressed: () {
              _logger.userAction('Delete account cancelled', screen: 'AccountPage');
              Navigator.pop(ctx, false);
            },
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AkeliColors.error),
            child: Text(l10n.commonDelete),
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
          SnackBar(content: Text(AppLocalizations.of(context).accountDeleteError)),
        );
      }
    }
  }

  String _friendlyAuthError(AppLocalizations l10n, String raw) {
    if (raw.contains('Invalid login credentials') || raw.contains('invalid_credentials')) {
      return l10n.accountErrorInvalidPassword;
    }
    if (raw.contains('too_many_requests')) {
      return l10n.accountErrorTooManyRequests;
    }
    return l10n.accountErrorGeneric;
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
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AkeliColors.onSurface)),
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
          prefixIcon: const Icon(Icons.lock_outline_rounded,
              color: AkeliColors.onSurfaceVariant, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
                obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                size: 20),
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
