import 'package:flutter_test/flutter_test.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/tantrum/services/tantrum_insights_service.dart';

void main() {
  TantrumEvent event({
    required int hour,
    required TantrumIntensity intensity,
    required String trigger,
    String? reaction,
    String? location,
  }) {
    return TantrumEvent(
      id: '${hour}_${intensity.name}_$trigger',
      timestamp: DateTime(2026, 2, 15, hour),
      intensity: intensity,
      whatHelped: const [],
      trigger: TriggerType.transitions,
      captureTrigger: trigger,
      parentReaction: reaction,
      location: location,
      captureIntensity: intensity == TantrumIntensity.mild
          ? 'mild'
          : intensity == TantrumIntensity.moderate
          ? 'medium'
          : 'intense',
    );
  }

  test('returns empty before unlock threshold', () {
    final lines = TantrumInsightsService.buildInsights([
      event(hour: 8, intensity: TantrumIntensity.mild, trigger: 'transition'),
      event(
        hour: 9,
        intensity: TantrumIntensity.moderate,
        trigger: 'transition',
      ),
      event(hour: 10, intensity: TantrumIntensity.intense, trigger: 'no_limit'),
      event(hour: 11, intensity: TantrumIntensity.mild, trigger: 'unknown'),
    ]);

    expect(lines, isEmpty);
  });

  test('builds supportive insights once unlocked', () {
    final lines = TantrumInsightsService.buildInsights([
      event(
        hour: 18,
        intensity: TantrumIntensity.moderate,
        trigger: 'transition',
        reaction: 'stayed_calm',
        location: 'home',
      ),
      event(
        hour: 19,
        intensity: TantrumIntensity.intense,
        trigger: 'transition',
        reaction: 'raised_voice',
        location: 'home',
      ),
      event(
        hour: 20,
        intensity: TantrumIntensity.moderate,
        trigger: 'transition',
        reaction: 'stayed_calm',
        location: 'home',
      ),
      event(
        hour: 7,
        intensity: TantrumIntensity.mild,
        trigger: 'no_limit',
        reaction: 'stayed_calm',
        location: 'car',
      ),
      event(
        hour: 21,
        intensity: TantrumIntensity.intense,
        trigger: 'sibling_conflict',
        reaction: 'raised_voice',
        location: 'home',
      ),
      event(
        hour: 17,
        intensity: TantrumIntensity.moderate,
        trigger: 'transition',
        reaction: 'stayed_calm',
        location: 'public',
      ),
    ]);

    expect(lines, isNotEmpty);
    expect(lines.length, lessThanOrEqualTo(3));
    for (final line in lines) {
      expect(line.startsWith('You may notice'), isTrue);
      expect(line.toLowerCase().contains('you should'), isFalse);
    }

    expect(
      lines.any((line) => line.toLowerCase().contains('transitions')),
      isTrue,
    );
  });
}
