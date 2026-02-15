import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/services/event_bus_service.dart';

void main() {
  setUp(() async {
    final dir = Directory.systemTemp.createTempSync('settle_event_contract');
    Hive.init(dir.path);
    await EventBusService.clearAll();
  });

  tearDown(() async {
    await Hive.close();
    await Hive.deleteFromDisk();
  });

  test(
    'event bus writes schema-versioned events with canonical tags',
    () async {
      await EventBusService.emit(
        childId: 'child-1',
        pillar: Pillars.helpNow,
        type: EventTypes.hnUsedRefusal,
        tags: const [EventTags.screen],
        metadata: const {
          'incident': 'transition_meltdown',
          'near_meal': '1',
          'screen_off_related': '1',
        },
      );

      final events = await EventBusService.allEvents();
      expect(events, hasLength(1));

      final event = events.single;
      expect(event['schema_version'], EventBusService.schemaVersion);
      expect(event['taxonomy_version'], EventBusService.taxonomyVersion);
      expect(event['pillar'], Pillars.helpNow);
      expect(event['type'], EventTypes.hnUsedRefusal);

      final context = Map<String, dynamic>.from(event['context'] as Map);
      expect(context['location'], EventContextLocation.home);
      expect(context['night'], isA<bool>());

      final tags = (event['tags'] as List).map((e) => e.toString()).toList();
      expect(tags, contains(EventTags.screens));
      expect(tags, contains(EventTags.transition));
      expect(tags, contains(EventTags.hunger));
      expect(tags, contains(EventTags.meals));
    },
  );

  test('event bus rejects invalid pillar and pillar/type mismatches', () async {
    await expectLater(
      EventBusService.emit(
        childId: 'child-1',
        pillar: 'UNKNOWN_PILLAR',
        type: EventTypes.hnUsedTantrum,
      ),
      throwsArgumentError,
    );

    await expectLater(
      EventBusService.emit(
        childId: 'child-1',
        pillar: Pillars.helpNow,
        type: EventTypes.stPlanStarted,
      ),
      throwsArgumentError,
    );

    await expectLater(
      EventBusService.emit(
        childId: 'child-1',
        pillar: Pillars.helpNow,
        type: EventTypes.hnUsedTantrum,
        metadata: const {'unexpected_key': 'x'},
      ),
      throwsArgumentError,
    );
  });

  test('event bus normalizes legacy events during read', () async {
    final box = await Hive.openBox<dynamic>('event_bus_v1');
    await box.add({
      'event_id': 'legacy-1',
      'timestamp': '2026-02-10T08:00:00.000',
      'child_id': 'child-1',
      'pillar': Pillars.helpNow,
      'type': EventTypes.hnUsedPublic,
      'context': {
        'night': false,
        'location': EventContextLocation.publicLocation,
      },
      'tags': ['screen', EventTags.publicTag],
      'metadata': {'incident': 'public_meltdown'},
    });

    final events = await EventBusService.allEvents();
    final migrated = events.firstWhere((e) => e['event_id'] == 'legacy-1');
    expect(migrated['schema_version'], EventBusService.schemaVersion);
    expect(migrated['taxonomy_version'], EventBusService.taxonomyVersion);
    expect((migrated['tags'] as List).contains(EventTags.screens), isTrue);

    final stored = Map<String, dynamic>.from(box.values.first as Map);
    expect(stored['schema_version'], EventBusService.schemaVersion);
    expect(stored['taxonomy_version'], EventBusService.taxonomyVersion);
  });
}
