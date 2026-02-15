import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('overlay back action falls back to shell when no stack exists', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/overlay',
      routes: [
        GoRoute(
          path: '/overlay',
          builder: (context, state) => const _BackFallbackScreen(),
        ),
        GoRoute(
          path: '/now',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('SHELL_SCREEN'))),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    expect(find.text('back'), findsOneWidget);

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(find.text('SHELL_SCREEN'), findsOneWidget);
  });
}

class _BackFallbackScreen extends StatelessWidget {
  const _BackFallbackScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onTap: () => context.canPop() ? context.pop() : context.go('/now'),
          child: const Text('back'),
        ),
      ),
    );
  }
}
