import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/family_rules_provider.dart';
import 'package:settle/providers/sleep_tonight_provider.dart';
import 'package:settle/screens/home.dart';

void main() {
  final profile = BabyProfile(
    name: 'Ari',
    ageBracket: AgeBracket.twoToThreeYears,
    familyStructure: FamilyStructure.twoParents,
    approach: Approach.stayAndSupport,
    primaryChallenge: PrimaryChallenge.nightWaking,
    feedingType: FeedingType.combo,
    focusMode: FocusMode.both,
    createdAt: 'child-1',
  );

  const sleepState = SleepTonightState(
    isLoading: false,
    activePlan: null,
    breathingDifficulty: false,
    dehydrationSigns: false,
    repeatedVomiting: false,
    severePainIndicators: false,
    feedingRefusalWithPainSigns: false,
    safeSleepConfirmed: false,
    comfortMode: false,
    somethingFeelsOff: false,
    lastError: null,
  );

  const rulesState = FamilyRulesState(
    isLoading: false,
    rulesetVersion: 1,
    rules: {
      'boundary_public': 'One script.',
      'screens_default': 'No screens before breakfast.',
      'snacks_default': 'Snack windows only.',
      'bedtime_routine': 'Bath, books, bed.',
    },
    pendingDiffs: [],
    changeFeed: [],
    error: null,
  );

  Widget buildHome({
    required DateTime now,
    SleepTonightState sleepOverride = sleepState,
    FamilyRulesState rulesOverride = rulesState,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(
          useMaterial3: true,
        ).copyWith(scaffoldBackgroundColor: Colors.transparent),
        home: HomeScreen(
          now: () => now,
          profileOverride: profile,
          sleepStateOverride: sleepOverride,
          rulesStateOverride: rulesOverride,
        ),
      ),
    );
  }

  testWidgets(
    'Home keeps one primary action with collapsed secondary actions',
    (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildHome(now: DateTime(2026, 2, 13, 14)));

      expect(find.text('Help with what\'s happening'), findsWidgets);
      expect(find.text('More actions'), findsOneWidget);

      await tester.tap(find.text('More actions'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Continue tonight\'s plan'), findsOneWidget);
      expect(find.text('Take a breath'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Rules'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    },
  );

  testWidgets('Home night messaging uses calm night subtitle', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildHome(now: DateTime(2026, 2, 13, 21)));

    expect(
      find.text('It\'s nighttime. You\'re here \u2014 that\'s the first step.'),
      findsOneWidget,
    );
    expect(find.text('Help with what\'s happening'), findsWidgets);
  });
}
