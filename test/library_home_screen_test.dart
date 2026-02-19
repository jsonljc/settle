import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:settle/screens/library/library_home_screen.dart';

void main() {
  void setPhoneViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/library',
      routes: [
        GoRoute(
          path: '/library',
          builder: (context, state) => const LibraryHomeScreen(),
        ),
        GoRoute(
          path: '/library/progress',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('PROGRESS_SCREEN'))),
        ),
        GoRoute(
          path: '/library/logs',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LOGS_SCREEN'))),
        ),
        GoRoute(
          path: '/library/learn',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LEARN_SCREEN'))),
        ),
        GoRoute(
          path: '/library/saved',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('SAVED_SCREEN'))),
        ),
        GoRoute(
          path: '/library/patterns',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('PATTERNS_SCREEN'))),
        ),
        GoRoute(
          path: '/library/insights',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('INSIGHTS_SCREEN'))),
        ),
      ],
    );
  }

  testWidgets('library shows calmer hierarchy with disclosure', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Progress'), findsOneWidget);
    expect(find.text('REVIEW'), findsOneWidget);
    expect(find.text('More tools'), findsOneWidget);
    expect(find.text('Saved'), findsNothing);
  });

  testWidgets('more tools expands and routes still work', (tester) async {
    setPhoneViewport(tester);
    await tester.pumpWidget(MaterialApp.router(routerConfig: buildRouter()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('More tools'));
    await tester.pumpAndSettle();
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Patterns'), findsOneWidget);

    await tester.tap(find.text('Saved'));
    await tester.pumpAndSettle();
    expect(find.text('SAVED_SCREEN'), findsOneWidget);
  });
}
