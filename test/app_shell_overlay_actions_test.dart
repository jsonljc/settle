import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:settle/screens/app_shell.dart';
import 'package:settle/widgets/nav_item.dart';

const _navItems = [
  SettleBottomNavItem(
    label: 'Now',
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
  ),
  SettleBottomNavItem(
    label: 'Sleep',
    icon: Icons.nightlight_outlined,
    activeIcon: Icons.nightlight_round,
  ),
  SettleBottomNavItem(
    label: 'Library',
    icon: Icons.menu_book_outlined,
    activeIcon: Icons.menu_book_rounded,
  ),
];

AppShell _shell(String marker) {
  return AppShell(
    currentIndex: 0,
    onTabTap: (_) {},
    navItems: _navItems,
    child: Scaffold(body: Center(child: Text(marker))),
  );
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(path: '/plan', builder: (_, __) => _shell('PLAN_ROOT')),
      GoRoute(path: '/sleep', builder: (_, __) => _shell('SLEEP_ROOT')),
      GoRoute(path: '/library', builder: (_, __) => _shell('LIBRARY_ROOT')),
      GoRoute(path: '/plan/moment', builder: (_, __) => _shell('PLAN_MOMENT')),
      GoRoute(
        path: '/sleep/tonight',
        builder: (_, __) => _shell('SLEEP_TONIGHT'),
      ),
      GoRoute(
        path: '/library/progress',
        builder: (_, __) => _shell('LIBRARY_PROGRESS'),
      ),
      GoRoute(
        path: '/family',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('FAMILY_SCREEN'))),
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) =>
            const Scaffold(body: Center(child: Text('SETTINGS_SCREEN'))),
      ),
    ],
  );
}

void main() {
  testWidgets(
    'root tabs show quick actions and action sheet routes to family',
    (tester) async {
      final router = _buildRouter(initialLocation: '/plan');
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.text('Menu'), findsOneWidget);

      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Quick actions'), findsOneWidget);
      expect(find.text('Family'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.tap(find.text('Family'));
      await tester.pumpAndSettle();

      expect(find.text('FAMILY_SCREEN'), findsOneWidget);
    },
  );

  testWidgets('deep routes hide quick actions menu', (tester) async {
    final router = _buildRouter(initialLocation: '/plan/moment');
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('Menu'), findsNothing);

    router.go('/sleep');
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsOneWidget);

    router.go('/sleep/tonight');
    await tester.pumpAndSettle();
    expect(find.text('Menu'), findsNothing);
  });
}
