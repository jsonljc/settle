import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/sleep_guidance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('sleep stop-rules honor explicit red-flag toggles', () async {
    final service = SleepGuidanceService.instance;

    final dehydrationStop = await service.evaluateStopRules(
      redFlagHealthFlag: false,
      unsafeSleepEnvironmentFlag: false,
      dehydrationSigns: true,
      repeatedVomiting: false,
      severePainIndicators: false,
      feedingRefusalWithPainSigns: false,
    );
    expect(dehydrationStop.blocked, isTrue);
    expect(dehydrationStop.triggeredRuleIds, contains('stop_if_red_flag'));
    expect(dehydrationStop.evidenceRefs, isNotEmpty);

    final vomitingStop = await service.evaluateStopRules(
      redFlagHealthFlag: false,
      unsafeSleepEnvironmentFlag: false,
      dehydrationSigns: false,
      repeatedVomiting: true,
      severePainIndicators: false,
      feedingRefusalWithPainSigns: false,
    );
    expect(vomitingStop.blocked, isTrue);
    expect(vomitingStop.triggeredRuleIds, contains('stop_if_red_flag'));

    final painStop = await service.evaluateStopRules(
      redFlagHealthFlag: false,
      unsafeSleepEnvironmentFlag: false,
      dehydrationSigns: false,
      repeatedVomiting: false,
      severePainIndicators: true,
      feedingRefusalWithPainSigns: false,
    );
    expect(painStop.blocked, isTrue);
    expect(painStop.triggeredRuleIds, contains('stop_if_red_flag'));

    final unsafeSleepStop = await service.evaluateStopRules(
      redFlagHealthFlag: false,
      unsafeSleepEnvironmentFlag: true,
      dehydrationSigns: false,
      repeatedVomiting: false,
      severePainIndicators: false,
      feedingRefusalWithPainSigns: false,
    );
    expect(unsafeSleepStop.blocked, isTrue);
    expect(
      unsafeSleepStop.triggeredRuleIds,
      contains('stop_if_unsafe_sleep_env'),
    );
  });

  test('night adapter builds deterministic executable plan shape', () async {
    final plan = await SleepGuidanceService.instance.buildTonightPlan(
      ageMonths: 8,
      scenario: 'night_wakes',
      preference: 'gentle',
      feedingAssociation: true,
      feedMode: 'reduce_gradually',
    );

    expect(plan.methodId, isNotEmpty);
    expect(plan.flowId, isNotEmpty);
    expect(plan.feedPolicyId, isNotEmpty);
    expect(plan.policyVersion, contains('|'));
    expect(plan.evidenceRefs, isNotEmpty);
    expect(plan.steps, isNotEmpty);
    expect(plan.escalationRule, isNotEmpty);

    for (final step in plan.steps) {
      expect(step.stepId, isNotEmpty);
      expect(step.title, isNotEmpty);
      expect(step.say, isNotEmpty);
      expect(step.doStep, isNotEmpty);
      expect(step.minutes, greaterThanOrEqualTo(1));
    }
  });

  test('day planner adapter emits runtime windows + evidence refs', () async {
    final runtime = await SleepGuidanceService.instance.buildDayPlannerRuntime(
      ageMonths: 10,
      wakeAnchorMinutes: 7 * 60,
      bedtimeTargetMinutes: 19 * 60,
      shortNapsRecent: true,
      overtiredSignsToday: true,
      minutesUntilBedtime: 180,
    );

    expect(runtime.ageBandId, isNotEmpty);
    expect(runtime.templateId, isNotEmpty);
    expect(runtime.wakeWindowProfileId, isNotEmpty);
    expect(runtime.rulesetId, isNotEmpty);
    expect(runtime.policyVersion, contains('|'));
    expect(runtime.evidenceRefs, isNotEmpty);
    expect(runtime.napWindows, isNotEmpty);
    expect(runtime.appliedConstraintIds, isA<List<String>>());
    expect(runtime.appliedRuleIds, isNotEmpty);

    for (final nap in runtime.napWindows) {
      expect(nap.slotId, isNotEmpty);
      expect(nap.startWindowMinutes, lessThanOrEqualTo(nap.endWindowMinutes));
      expect(nap.targetDurationMinutes, greaterThan(0));
    }
  });
}
