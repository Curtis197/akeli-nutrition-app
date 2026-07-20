import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/push_token_provider.dart';
import '../../providers/badge_sync_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/notifications_provider.dart';
import '../../providers/mode_provider.dart';
import '../../widgets/mode_selector.dart';
import '../../shared/widgets/avatar.dart';
import '../../l10n/app_localizations.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(route: AkeliRoutes.home, icon: Icons.home_outlined, activeIcon: Icons.home),
    _TabItem(route: AkeliRoutes.mealPlanner, icon: Icons.restaurant_menu_outlined, activeIcon: Icons.restaurant_menu),
    _TabItem(route: AkeliRoutes.recipes, icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book),
    _TabItem(route: AkeliRoutes.community, icon: Icons.people_outlined, activeIcon: Icons.people),
  ];

  int _activeIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].route) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(pushTokenProvider);
    ref.watch(badgeSyncProvider);
    final activeIndex = _activeIndex(context);
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(currentModeProvider);
    final isBeauty = mode == AppMode.beauty;
    final modeColor = getAppModeColor(mode);

    final tabLabels = isBeauty
        ? [l10n.navHome, 'Routines', 'Remèdes', l10n.navCommunity]
        : [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity];

    final currentTabs = isBeauty
        ? const [
            _TabItem(route: AkeliRoutes.home, icon: Icons.home_outlined, activeIcon: Icons.home),
            _TabItem(route: AkeliRoutes.mealPlanner, icon: Icons.spa_outlined, activeIcon: Icons.spa),
            _TabItem(route: AkeliRoutes.recipes, icon: Icons.eco_outlined, activeIcon: Icons.eco),
            _TabItem(route: AkeliRoutes.community, icon: Icons.people_outlined, activeIcon: Icons.people),
          ]
        : _tabs;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: profileAsync.when(
            data: (profile) => GestureDetector(
              onTap: () => context.go(AkeliRoutes.profile),
              child: AkeliAvatar(
                imageUrl: profile?.avatarUrl,
                initials: profile?.displayName.isNotEmpty == true
                    ? profile!.displayName[0].toUpperCase()
                    : 'A',
                size: AvatarSize.sm,
              ),
            ),
            loading: () => const AkeliAvatar(
              size: AvatarSize.sm,
              initials: 'A',
            ),
            error: (_, __) => GestureDetector(
              onTap: () => context.go(AkeliRoutes.profile),
              child: const AkeliAvatar(
                size: AvatarSize.sm,
                initials: 'A',
              ),
            ),
          ),
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(currentModeProvider);
              final color = getAppModeColor(mode);
              final icon = getAppModeIcon(mode);

              return GestureDetector(
                onTap: () => showModeSelectorDialog(context, ref),
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 16, color: color),
                      const SizedBox(width: 4),
                      Text(
                        mode.displayName,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const _NotificationBell(),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: AkeliColors.secondary),
              onPressed: () => context.go(AkeliRoutes.settings),
              tooltip: l10n.tooltipSettings,
            ),
          ),
        ],
      ),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: activeIndex,
        onDestinationSelected: (index) {
          context.go(currentTabs[index].route);
        },
        backgroundColor: AkeliColors.surface,
        indicatorColor: modeColor.withValues(alpha: 0.12),
        destinations: List.generate(currentTabs.length, (i) => NavigationDestination(
          icon: Icon(currentTabs[i].icon),
          selectedIcon: Icon(currentTabs[i].activeIcon, color: modeColor),
          label: tabLabels[i],
        )),
      ),
    );
  }
}

class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(unreadNotificationCountProvider);
    final hasUnread =
        countAsync.maybeWhen(data: (n) => n > 0, orElse: () => false);

    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded,
              color: AkeliColors.secondary),
          onPressed: () => context.push(AkeliRoutes.notifications),
          tooltip: AppLocalizations.of(context).tooltipNotifications,
        ),
        if (hasUnread)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _TabItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;

  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
  });
}
