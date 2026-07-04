import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/push_token_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/notifications_provider.dart';
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
    final activeIndex = _activeIndex(context);
    final profileAsync = ref.watch(userProfileProvider);
    final l10n = AppLocalizations.of(context);
    final tabLabels = [l10n.navHome, l10n.navMeals, l10n.navRecipes, l10n.navCommunity];

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
          context.go(_tabs[index].route);
        },
        backgroundColor: AkeliColors.surface,
        indicatorColor: AkeliColors.primary.withValues(alpha: 0.12),
        destinations: List.generate(_tabs.length, (i) => NavigationDestination(
          icon: Icon(_tabs[i].icon),
          selectedIcon: Icon(_tabs[i].activeIcon, color: AkeliColors.primary),
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
