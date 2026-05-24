import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/notifications_provider.dart';

class MainShell extends ConsumerWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  static const _tabs = [
    _TabItem(
      route: AkeliRoutes.home,
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Home',
    ),
    _TabItem(
      route: AkeliRoutes.mealPlanner,
      icon: Icons.restaurant_menu_outlined,
      activeIcon: Icons.restaurant_menu,
      label: 'Meals',
    ),
    _TabItem(
      route: AkeliRoutes.recipes,
      icon: Icons.menu_book_outlined,
      activeIcon: Icons.menu_book,
      label: 'Recipes',
    ),
    _TabItem(
      route: AkeliRoutes.community,
      icon: Icons.people_outlined,
      activeIcon: Icons.people,
      label: 'Community',
    ),
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
    final activeIndex = _activeIndex(context);
    final profileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: profileAsync.when(
            data: (profile) => GestureDetector(
              onTap: () => context.go(AkeliRoutes.profile),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AkeliColors.surfaceContainerHigh,
                backgroundImage: profile?.avatarUrl != null
                    ? NetworkImage(profile!.avatarUrl!)
                    : null,
                child: profile?.avatarUrl == null
                    ? const Icon(Icons.person_outline,
                        color: AkeliColors.outline, size: 18)
                    : null,
              ),
            ),
            loading: () => const CircleAvatar(
                radius: 18,
                backgroundColor: AkeliColors.surfaceContainerHigh),
            error: (_, __) => GestureDetector(
              onTap: () => context.go(AkeliRoutes.profile),
              child: const CircleAvatar(
                  radius: 18,
                  backgroundColor: AkeliColors.surfaceContainerHigh),
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
              onPressed: () => context.go(AkeliRoutes.profile),
              tooltip: 'Paramètres',
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
        destinations: _tabs
            .map(
              (tab) => NavigationDestination(
                icon: Icon(tab.icon),
                selectedIcon: Icon(tab.activeIcon, color: AkeliColors.primary),
                label: tab.label,
              ),
            )
            .toList(),
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
          tooltip: 'Notifications',
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
  final String label;

  const _TabItem({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
