import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:settle/data/app_repository.dart';
import 'package:settle/models/approach.dart';
import 'package:settle/models/baby_profile.dart';
import 'package:settle/models/day_plan.dart';
import 'package:settle/models/night_wake.dart';
import 'package:settle/models/reset_event.dart';
import 'package:settle/models/sleep_session.dart';
import 'package:settle/models/tantrum_profile.dart';
import 'package:settle/models/user_card.dart';

void main() {
  late Directory hiveDir;
  final repo = AppRepositoryImpl.instance;

  setUpAll(() async {
    hiveDir = Directory.systemTemp.createTempSync('settle_repo_storage');
    Hive.init(hiveDir.path);
    _registerAdapters();
    await Future.wait([
      Hive.openBox<dynamic>('spine_store'),
      Hive.openBox<UserCard>('user_cards'),
      Hive.openBox<BabyProfile>('profile'),
    ]);
  });

  tearDown(() async {
    await Hive.box<dynamic>('spine_store').clear();
    await Hive.box<UserCard>('user_cards').clear();
    await Hive.box<BabyProfile>('profile').clear();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDir.existsSync()) {
      hiveDir.deleteSync(recursive: true);
    }
  });

  test('save/load reset events', () async {
    await repo.addResetEvent(context: 'general');
    await Future<void>.delayed(const Duration(milliseconds: 2));
    await repo.addResetEvent(context: 'sleep');

    final events = await repo.getResetEvents();
    expect(events, hasLength(2));
    expect(events.first.context, 'sleep');
    expect(events.last.context, 'general');
    expect(events.first.timestamp.isAfter(events.last.timestamp), isTrue);
  });

  test('save/remove playbook cards', () async {
    expect(await repo.getSavedCardIds(), isEmpty);

    await repo.addSavedCard('card-alpha');
    await repo.addSavedCard('card-beta', pinned: true);
    final savedIds = await repo.getSavedCardIds();

    expect(savedIds, contains('card-alpha'));
    expect(savedIds, contains('card-beta'));

    await repo.removeSavedCard('card-alpha');
    final afterRemove = await repo.getSavedCardIds();
    expect(afterRemove, isNot(contains('card-alpha')));
    expect(afterRemove, contains('card-beta'));
  });

  test('settings round-trip for child name and age', () async {
    final profileBox = Hive.box<BabyProfile>('profile');
    await profileBox.put('baby', _sampleProfile());

    expect(await repo.getChildName(), 'Avery');
    final before = await repo.getChildAge();
    expect(before.$1, AgeBracket.nineToTwelveMonths);
    expect(before.$2, 11);

    await repo.setChildName('Rowan');
    await repo.setChildAge(AgeBracket.twelveToEighteenMonths, 14);

    expect(await repo.getChildName(), 'Rowan');
    final after = await repo.getChildAge();
    expect(after.$1, AgeBracket.twelveToEighteenMonths);
    expect(after.$2, 14);
  });

  test('graceful fallback on corrupted storage data', () async {
    final spineBox = Hive.box<dynamic>('spine_store');
    await spineBox.put('schema_version', 'corrupted');
    await spineBox.put('reset_events', [
      'bad',
      123,
      {'unexpected': true},
    ]);

    expect(repo.schemaVersion, 0);
    expect(await repo.getResetEvents(), isEmpty);

    await expectLater(repo.addResetEvent(context: 'tantrum'), completes);
    final recovered = await repo.getResetEvents();
    expect(recovered, hasLength(1));
    expect(recovered.first.context, 'tantrum');

    // Missing profile data should not throw and should return safe defaults.
    expect(await repo.getChildName(), isNull);
    final age = await repo.getChildAge();
    expect(age.$1, isNull);
    expect(age.$2, isNull);
    await expectLater(repo.setChildName('Any'), completes);
    await expectLater(repo.setChildAge(AgeBracket.newborn, 1), completes);
  });
}

BabyProfile _sampleProfile() {
  return BabyProfile(
    name: 'Avery',
    ageBracket: AgeBracket.nineToTwelveMonths,
    familyStructure: FamilyStructure.twoParents,
    approach: Approach.stayAndSupport,
    primaryChallenge: PrimaryChallenge.nightWaking,
    feedingType: FeedingType.combo,
    ageMonths: 11,
  );
}

void _registerAdapters() {
  if (Hive.isAdapterRegistered(0)) {
    return;
  }

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
    ..registerAdapter(DayPlanAdapter())
    ..registerAdapter(UserCardAdapter())
    ..registerAdapter(ResetEventAdapter());
}
