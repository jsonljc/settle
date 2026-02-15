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

  Widget buildHome({required DateTime now}) {
    return ProviderScope(
      child: MaterialApp(
        theme: ThemeData.dark(
          useMaterial3: true,
        ).copyWith(scaffoldBackgroundColor: Colors.transparent),
        home: HomeScreen(
          now: () => now,
          profileOverride: profile,
          sleepStateOverride: sleepState,
          rulesStateOverride: rulesState,
        ),
      ),
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  testWidgets('Home day baseline', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildHome(now: DateTime(2026, 2, 13, 14)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_day.png'),
    );
  });

  testWidgets('Home night baseline', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildHome(now: DateTime(2026, 2, 13, 21)));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(HomeScreen),
      matchesGoldenFile('goldens/home_night.png'),
    );
  });
}
