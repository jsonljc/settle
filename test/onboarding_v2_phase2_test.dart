import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/screens/onboarding/onboarding_v2_screen.dart';
import 'package:settle/screens/onboarding/steps/step_regulation_check.dart';
import 'package:settle/screens/sleep/sleep_mini_onboarding.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_v2_onboarding');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive
        ..registerAdapter(ApproachAdapter())
        ..registerAdapter(AgeBracketAdapter())
        ..registerAdapter(FamilyStructureAdapter())
        ..registerAdapter(RegulationLevelAdapter())
        ..registerAdapter(PrimaryChallengeAdapter())
        ..registerAdapter(FeedingTypeAdapter())
        ..registerAdapter(FocusModeAdapter())
        ..registerAdapter(TantrumTypeAdapter())
        ..registerAdapter(TriggerTypeAdapter())
        ..registerAdapter(ParentPatternAdapter())
        ..registerAdapter(ResponsePriorityAdapter())
        ..registerAdapter(TantrumIntensityAdapter())
        ..registerAdapter(PatternTrendAdapter())
        ..registerAdapter(NormalizationStatusAdapter())
        ..registerAdapter(DayBucketAdapter())
        ..registerAdapter(BabyProfileAdapter())
        ..registerAdapter(TantrumProfileAdapter())
        ..registerAdapter(TantrumEventAdapter())
        ..registerAdapter(WeeklyTantrumPatternAdapter())
        ..registerAdapter(SleepSessionAdapter())
        ..registerAdapter(NightWakeAdapter())
        ..registerAdapter(DayPlanAdapter());
    }

    final profileBox = await Hive.openBox<BabyProfile>('profile');
    await profileBox.put(
      'baby',
      BabyProfile(
        name: 'Ari',
        ageBracket: AgeBracket.twoToThreeYears,
        familyStructure: FamilyStructure.twoParents,
        approach: Approach.stayAndSupport,
        primaryChallenge: PrimaryChallenge.fallingAsleep,
        feedingType: FeedingType.solids,
        focusMode: FocusMode.both,
        regulationLevel: RegulationLevel.stressed,
        ageMonths: 30,
        sleepProfileComplete: false,
      ),
    );
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  Future<void> tapText(WidgetTester tester, String label) async {
    final finder = find.text(label).first;
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<void> tapNext(WidgetTester tester) async {
    final cta = find.byKey(const ValueKey('v2_onboarding_next_cta'));
    await tester.ensureVisible(cta);
    await tester.tap(cta);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
  }

  Future<void> waitForText(WidgetTester tester, String label) async {
    for (var i = 0; i < 40; i++) {
      if (find.text(label).evaluate().isNotEmpty) return;
      await tester.pump(const Duration(milliseconds: 100));
    }
    fail('Timed out waiting for "$label"');
  }

  testWidgets('v2 onboarding builds expected profile payload', (tester) async {
    BabyProfile? savedProfile;

    final router = GoRouter(
      initialLocation: '/onboard',
      routes: [
        GoRoute(
          path: '/onboard',
          builder: (_, __) => OnboardingV2Screen(
            onSaveProfile: (profile) async => savedProfile = profile,
          ),
        ),
        GoRoute(
          path: '/plan',
          builder: (_, __) =>
              const Scaffold(body: Center(child: Text('PLAN_DESTINATION'))),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(child: MaterialApp.router(routerConfig: router)),
    );
    await tester.pump();

    await waitForText(tester, 'Tell us about your child');
    await tapNext(tester);

    await waitForText(tester, 'Who is parenting day to day?');
    await tapText(tester, 'Together');
    await tapNext(tester);

    await waitForText(tester, 'What feels hardest right now?');
    await tapText(tester, 'Transitions');
    await tapNext(tester);

    await waitForText(tester, 'Instant value');
    await tapNext(tester);

    await waitForText(tester, 'How are you feeling right now?');
    await tapText(tester, 'Calm');
    await tapNext(tester);

    await waitForText(tester, 'Invite your partner');
    await tapNext(tester);

    await waitForText(tester, 'Try Settle Premium');
    await tapNext(tester);
    await tester.pumpAndSettle();

    expect(savedProfile, isNotNull);
    expect(savedProfile!.name, 'your child');
    expect(savedProfile!.ageMonths, 24);
    expect(savedProfile!.ageBracket, AgeBracket.nineteenToTwentyFourMonths);
    expect(savedProfile!.familyStructure, FamilyStructure.twoParents);
    expect(savedProfile!.regulationLevel, RegulationLevel.calm);
    expect(savedProfile!.approach, Approach.stayAndSupport);
    expect(savedProfile!.primaryChallenge, PrimaryChallenge.fallingAsleep);
    expect(savedProfile!.feedingType, FeedingType.solids);
    expect(savedProfile!.focusMode, FocusMode.both);
    expect(savedProfile!.sleepProfileComplete, isFalse);
    expect(router.routeInformationProvider.value.uri.path, '/plan');
  });

  testWidgets('sleep mini onboarding screen renders profile setup UI', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SleepMiniOnboardingScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('Sleep setup'), findsOneWidget);
    expect(
      find.text('One-time setup before Sleep tools unlock.'),
      findsOneWidget,
    );
  });

  testWidgets('regulation step shows preview for non-calm states', (
    tester,
  ) async {
    RegulationLevel? selected;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: StepRegulationCheck(
                  selected: selected,
                  onSelect: (value) => setState(() => selected = value),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Regulate preview ready'), findsNothing);
    await tapText(tester, 'Stressed');
    expect(find.text('Regulate preview ready'), findsOneWidget);
    expect(
      find.text('Plan will prioritize a fast 30-second breathing reset first.'),
      findsOneWidget,
    );
  });
}
