import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/router.dart';
import '../../core/theme.dart';

class MainShell extends StatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
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
    // Check if we're on beauty mode
    if (location == AkeliRoutes.beauty) return 0; // Show home as active
    return 0;
  }

  String _getCurrentMode(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location == AkeliRoutes.beauty) return 'beauty';
    if (location == AkeliRoutes.home) return 'nutrition';
    return 'nutrition';
  }

  void _switchMode(BuildContext context, String mode) {
    if (mode == 'nutrition') {
      context.go(AkeliRoutes.home);
    } else if (mode == 'beauty') {
      context.go(AkeliRoutes.beauty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeIndex = _activeIndex(context);
    final currentMode = _getCurrentMode(context);

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentMode == 'nutrition' ? 'Nutrition' : 'Beauté',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: currentMode == 'nutrition' 
                    ? AkeliColors.primary.withValues(alpha: 0.1)
                    : AkeliColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentMode.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: currentMode == 'nutrition'
                      ? AkeliColors.primary
                      : AkeliColors.secondary,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Mode Switcher
          PopupMenuButton<String>(
            icon: Icon(
              currentMode == 'nutrition' 
                  ? Icons.spa_outlined 
                  : Icons.face_outlined,
              color: currentMode == 'nutrition'
                  ? AkeliColors.primary
                  : AkeliColors.secondary,
            ),
            tooltip: 'Switch mode',
            onSelected: (mode) => _switchMode(context, mode),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'nutrition',
                child: Row(
                  children: [
                    Icon(
                      Icons.restaurant_menu,
                      color: currentMode == 'nutrition' 
                          ? AkeliColors.primary 
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    const Text('Nutrition'),
                    if (currentMode == 'nutrition') ...[
                      const Spacer(),
                      Icon(Icons.check, color: AkeliColors.primary, size: 20),
                    ],
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'beauty',
                child: Row(
                  children: [
                    Icon(
                      Icons.spa,
                      color: currentMode == 'beauty' 
                          ? AkeliColors.secondary 
                          : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    const Text('Beauté'),
                    if (currentMode == 'beauty') ...[
                      const Spacer(),
                      Icon(Icons.check, color: AkeliColors.secondary, size: 20),
                    ],
                  ],
                ),
              ),
            ],
          ),
          // Profile
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.go(AkeliRoutes.profile),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: widget.child,
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
