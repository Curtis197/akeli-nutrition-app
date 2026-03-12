import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';

class MainShell extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outlined),
            onPressed: () => context.go(AkeliRoutes.profile),
            tooltip: 'Profile',
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
        indicatorColor: AkeliColors.primary.withOpacity(0.12),
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
