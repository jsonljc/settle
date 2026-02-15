import 'package:flutter_test/flutter_test.dart';
import 'package:settle/services/family_rules_guidance_service.dart';
import 'package:settle/services/help_now_guidance_service.dart';
import 'package:settle/services/plan_progress_guidance_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'help now guidance resolves deterministic output by incident and age',
    () async {
      final outputYoung = await HelpNowGuidanceService.instance
          .resolveIncidentOutput(
            incidentId: 'screaming_crying',
            ageBand: '1-2',
          );
      expect(outputYoung.timerMinutes, 2);
      expect(outputYoung.say, isNotEmpty);
      expect(outputYoung.doStep, isNotEmpty);

      final outputOlder = await HelpNowGuidanceService.instance
          .resolveIncidentOutput(
            incidentId: 'screaming_crying',
            ageBand: '3-5',
          );
      expect(outputOlder.timerMinutes, 3);
      expect(outputOlder.evidenceRefs.isNotEmpty, isTrue);
    },
  );

  test(
    'plan progress guidance returns deterministic recommendation from events',
    () async {
      final events = [
        {'type': 'ST_NIGHT_WAKE_LOGGED'},
        {'type': 'ST_NIGHT_WAKE_LOGGED'},
        {'type': 'ST_NIGHT_WAKE_LOGGED'},
        {'type': 'HN_USED_PUBLIC'},
      ];

      final recommendation = await PlanProgressGuidanceService.instance
          .recommendFromEvents(events);
      expect(recommendation, isNotNull);
      expect(recommendation!.bottleneck, 'Night wakes after bedtime');
      expect(recommendation.triggerEventType, 'ST_NIGHT_WAKE_LOGGED');
      expect(recommendation.triggerCount, 3);
      expect(recommendation.evidenceRefs.isNotEmpty, isTrue);
    },
  );

  test('plan progress guidance ignores non-signal admin events', () async {
    final events = [
      {'type': 'FR_RULE_UPDATED'},
      {'type': 'FR_RULE_UPDATED'},
      {'type': 'FR_RULE_UPDATED'},
      {'type': 'PP_RHYTHM_UPDATED'},
    ];

    final recommendation = await PlanProgressGuidanceService.instance
        .recommendFromEvents(events);
    expect(recommendation, isNull);
  });

  test(
    'plan progress guidance fallback can trigger from eligible signal events',
    () async {
      final events = [
        {'type': 'HN_USED_AGGRESSION'},
        {'type': 'HN_USED_AGGRESSION'},
        {'type': 'HN_USED_AGGRESSION'},
      ];

      final recommendation = await PlanProgressGuidanceService.instance
          .recommendFromEvents(events);
      expect(recommendation, isNotNull);
      expect(recommendation!.triggerEventType, 'HN_USED_AGGRESSION');
      expect(recommendation.triggerCount, 3);
      expect(recommendation.bottleneck, 'High-friction moments');
    },
  );

  test(
    'family rules guidance exposes deterministic defaults and rule ids',
    () async {
      final defaults = await FamilyRulesGuidanceService.instance.defaultRules();
      expect(defaults.keys, contains('boundary_public'));
      expect(defaults.keys, contains('screens_default'));
      expect(defaults.keys, contains('snacks_default'));
      expect(defaults.keys, contains('bedtime_routine'));

      final allowed = await FamilyRulesGuidanceService.instance
          .allowedRuleIds();
      expect(allowed, containsAll(defaults.keys));

      final refs = await FamilyRulesGuidanceService.instance
          .evidenceRefsForRule('boundary_public');
      expect(refs.isNotEmpty, isTrue);
    },
  );
}
