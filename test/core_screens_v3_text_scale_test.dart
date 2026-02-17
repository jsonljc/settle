import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/screens/onboarding/onboarding_v2_screen.dart';
import 'package:settle/screens/plan/plan_home_screen.dart';

Widget _host({required double textScale, required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: child,
      ),
    ),
  );
}

void main() {
  final scales = <double>[1.0, 1.3, 1.6];

  for (final scale in scales) {
    testWidgets('v3 plan card route remains stable at text scale $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          textScale: scale,
          child: const PlanCardScreen(cardId: 'no_everything_offer_two'),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Script'), findsOneWidget);
    });

    testWidgets('v3 onboarding remains stable at text scale $scale', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(textScale: scale, child: const OnboardingV2Screen()),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Continue'), findsOneWidget);
    });
  }
}
