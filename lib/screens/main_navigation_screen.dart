import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  final Widget child;
  final int initialIndex;

  const MainNavigationScreen({
    super.key,
    required this.child,
    this.initialIndex = 0,
  });

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  // Map routes to tab indices
  int _getTabIndexFromRoute(String location) {
    if (location.startsWith('/interviews')) return 0;
    if (location.startsWith('/offers')) return 1;
    if (location.startsWith('/commissions')) return 2;
    if (location.startsWith('/account')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Automatically sync selected tab with current route
    final currentLocation = GoRouterState.of(context).uri.toString();
    final selectedIndex = _getTabIndexFromRoute(currentLocation);

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (int index) {
          // Navigate to the corresponding route
          switch (index) {
            case 0:
              context.go('/interviews');
              break;
            case 1:
              context.go('/offers');
              break;
            case 2:
              context.go('/commissions');
              break;
            case 3:
              context.go('/account');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Wywiady',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article),
            label: 'Oferty',
          ),
          NavigationDestination(
            icon: Icon(Icons.attach_money_outlined),
            selectedIcon: Icon(Icons.attach_money),
            label: 'Prowizje',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Konto',
          ),
        ],
      ),
    );
  }
}
