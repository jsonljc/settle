import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/providers/tantrum_providers.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_tantrum_capture');
    Hive.init(dir.path);
    if (!Hive.isAdapterRegistered(30)) {
      Hive
        ..registerAdapter(FocusModeAdapter())
        ..registerAdapter(TantrumTypeAdapter())
        ..registerAdapter(TriggerTypeAdapter())
        ..registerAdapter(ParentPatternAdapter())
        ..registerAdapter(ResponsePriorityAdapter())
        ..registerAdapter(TantrumIntensityAdapter())
        ..registerAdapter(PatternTrendAdapter())
        ..registerAdapter(NormalizationStatusAdapter())
        ..registerAdapter(DayBucketAdapter())
        ..registerAdapter(TantrumProfileAdapter())
        ..registerAdapter(TantrumEventAdapter())
        ..registerAdapter(WeeklyTantrumPatternAdapter());
    }
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test('addCapture stores v2 capture metadata and mapped fields', () async {
    final notifier = TantrumEventsNotifier();

    final eventId = await notifier.addCapture(
      trigger: 'transition',
      intensity: 'medium',
      location: 'home',
      parentReaction: 'stayed_calm',
      selectedCardId: 'transition_medium_raised_voice',
    );

    expect(eventId, isNotEmpty);
    expect(notifier.state, isNotEmpty);

    final event = notifier.state.first;
    expect(event.captureTrigger, 'transition');
    expect(event.captureIntensity, 'medium');
    expect(event.location, 'home');
    expect(event.parentReaction, 'stayed_calm');
    expect(event.selectedCardId, 'transition_medium_raised_voice');

    expect(event.trigger, TriggerType.transitions);
    expect(event.intensity, TantrumIntensity.moderate);
  });
}
