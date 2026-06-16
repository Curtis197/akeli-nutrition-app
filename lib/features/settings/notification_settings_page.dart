import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/notification_prefs_provider.dart';

class NotificationSettingsPage extends ConsumerWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    appLogger.provider('NotificationSettingsPage build()');

    final loaderAsync = ref.watch(notificationPrefsLoader);
    final prefs = ref.watch(notificationPrefsProvider);
    final notifier = ref.read(notificationPrefsProvider.notifier);

    return Scaffold(
      backgroundColor: AkeliColors.surfaceContainerLowest,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 16),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              color: AkeliColors.surfaceContainerLowest.withValues(alpha: 0.85),
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
                      color: AkeliColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      color: AkeliColors.onSurfaceVariant,
                      onPressed: () {
                        appLogger.userAction('Back button tapped',
                            screen: 'NotificationSettingsPage');
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AkeliRoutes.settings);
                        }
                      },
                    ),
                  ),
                  const Text(
                    'Notifications',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.primaryContainer,
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
      body: loaderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) {
          appLogger.provider('NotificationSettingsPage → error | $e');
          return const Center(
            child: Text(
              'Impossible de charger les préférences.',
              style: TextStyle(color: AkeliColors.onSurfaceVariant),
            ),
          );
        },
        data: (_) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Configurez vos préférences pour rester connecté sans être submergé. La tranquillité de votre sanctuaire numérique est primordiale.',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15,
                    height: 1.6,
                    color: AkeliColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 48,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      _NotifToggleRow(
                        icon: Icons.notifications_outlined,
                        label: 'Push Notifications',
                        subtitle: 'Recevez vos notifications sur votre appareil',
                        value: prefs.pushEnabled,
                        onChanged: notifier.setPush,
                      ),
                      _NotifToggleRow(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Chat',
                        subtitle: 'Messages et conversations',
                        value: prefs.chatEnabled,
                        onChanged: notifier.setChat,
                      ),
                      _NotifToggleRow(
                        icon: Icons.restaurant_outlined,
                        label: 'Rappels de repas',
                        subtitle: 'Heures de repas planifiés',
                        value: prefs.mealRemindersEnabled,
                        onChanged: notifier.setMealReminders,
                      ),
                      _NotifToggleRow(
                        icon: Icons.person_add_outlined,
                        label: 'Demandes de conversation',
                        subtitle: 'Nouvelles demandes de connexion',
                        value: prefs.dmRequestsEnabled,
                        onChanged: notifier.setDmRequests,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const _SaveButton(),
    );
  }
}

class _NotifToggleRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotifToggleRow({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AkeliColors.secondaryContainer.withValues(alpha: 0.35),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AkeliColors.primaryContainer, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AkeliColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    color: AkeliColors.outline,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AkeliColors.surface,
            activeTrackColor: AkeliColors.primaryContainer,
            inactiveThumbColor: AkeliColors.surface,
            inactiveTrackColor: AkeliColors.surfaceContainerHigh,
          ),
        ],
      ),
    );
  }
}

class _SaveButton extends ConsumerStatefulWidget {
  const _SaveButton();

  @override
  ConsumerState<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends ConsumerState<_SaveButton> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AkeliColors.surfaceContainerLowest.withValues(alpha: 0),
            AkeliColors.surfaceContainerLowest.withValues(alpha: 0.95),
            AkeliColors.surfaceContainerLowest,
          ],
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _saving
                  ? [AkeliColors.outline, AkeliColors.outline]
                  : [AkeliColors.primary, AkeliColors.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AkeliColors.primary.withValues(alpha: 0.2),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text(
                    'Enregistrer',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    appLogger.userAction('Save notification prefs tapped',
        screen: 'NotificationSettingsPage');
    setState(() => _saving = true);
    try {
      await ref.read(notificationPrefsProvider.notifier).save();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Préférences enregistrées'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e, st) {
      appLogger.db('ERROR | save notification prefs | $e',
          error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'enregistrement. Réessayez.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
