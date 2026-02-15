import 'package:hive_flutter/hive_flutter.dart';

part 'tantrum_profile.g.dart';

@HiveType(typeId: 30)
enum FocusMode {
  @HiveField(0)
  sleepOnly,
  @HiveField(1)
  tantrumOnly,
  @HiveField(2)
  both;

  String get label => switch (this) {
    sleepOnly => 'Sleep',
    tantrumOnly => 'Tantrums',
    both => 'Both',
  };
}

@HiveType(typeId: 31)
enum TantrumType {
  @HiveField(0)
  explosive,
  @HiveField(1)
  shutdown,
  @HiveField(2)
  escalating,
  @HiveField(3)
  mixed;

  String get label => switch (this) {
    explosive => 'Fast intensity',
    shutdown => 'Shutdown',
    escalating => 'Builds over time',
    mixed => 'Unpredictable',
  };
}

@HiveType(typeId: 32)
enum TriggerType {
  @HiveField(0)
  transitions,
  @HiveField(1)
  frustration,
  @HiveField(2)
  sensory,
  @HiveField(3)
  boundaries,
  @HiveField(4)
  unpredictable;

  String get label => switch (this) {
    transitions => 'Transitions',
    frustration => 'Frustration',
    sensory => 'Sensory overload',
    boundaries => 'Boundaries',
    unpredictable => 'Unpredictable',
  };
}

@HiveType(typeId: 33)
enum ParentPattern {
  @HiveField(0)
  reasons,
  @HiveField(1)
  givesIn,
  @HiveField(2)
  getsAngry,
  @HiveField(3)
  freezes;

  String get label => switch (this) {
    reasons => 'Try to reason or explain',
    givesIn => 'Ease the limit to get through the moment',
    getsAngry => 'Voice gets sharp when stressed',
    freezes => 'Feel stuck and unsure what to do',
  };
}

@HiveType(typeId: 34)
enum ResponsePriority {
  @HiveField(0)
  coRegulation,
  @HiveField(1)
  structure,
  @HiveField(2)
  insight,
  @HiveField(3)
  scripts;

  String get label => switch (this) {
    coRegulation => 'Stay calm and present',
    structure => 'Set clear boundaries',
    insight => 'Understand why it happens',
    scripts => 'Use short ready-to-use scripts',
  };
}

@HiveType(typeId: 35)
enum TantrumIntensity {
  @HiveField(0)
  mild,
  @HiveField(1)
  moderate,
  @HiveField(2)
  intense;

  String get label => switch (this) {
    mild => 'Mild',
    moderate => 'Moderate',
    intense => 'Intense',
  };
}

@HiveType(typeId: 36)
enum PatternTrend {
  @HiveField(0)
  decreasing,
  @HiveField(1)
  stable,
  @HiveField(2)
  increasing,
}

@HiveType(typeId: 37)
enum NormalizationStatus {
  @HiveField(0)
  withinNormal,
  @HiveField(1)
  approachingConcern,
  @HiveField(2)
  flagged;

  String get title => switch (this) {
    withinNormal => 'Within typical range',
    approachingConcern => 'Higher than usual range',
    flagged => 'Consider pediatric check-in',
  };
}

@HiveType(typeId: 38)
enum DayBucket {
  @HiveField(0)
  morning,
  @HiveField(1)
  midday,
  @HiveField(2)
  afternoon,
  @HiveField(3)
  evening;

  static DayBucket fromDateTime(DateTime t) {
    final h = t.hour;
    if (h < 11) return DayBucket.morning;
    if (h < 14) return DayBucket.midday;
    if (h < 18) return DayBucket.afternoon;
    return DayBucket.evening;
  }

  String get label => switch (this) {
    morning => 'Morning',
    midday => 'Midday',
    afternoon => 'Afternoon',
    evening => 'Evening',
  };
}

@HiveType(typeId: 40)
class TantrumProfile extends HiveObject {
  @HiveField(0)
  TantrumType tantrumType;

  @HiveField(1)
  List<TriggerType> commonTriggers;

  @HiveField(2)
  ParentPattern parentPattern;

  @HiveField(3)
  ResponsePriority responsePriority;

  TantrumProfile({
    required this.tantrumType,
    required this.commonTriggers,
    required this.parentPattern,
    required this.responsePriority,
  });

  TantrumProfile copyWith({
    TantrumType? tantrumType,
    List<TriggerType>? commonTriggers,
    ParentPattern? parentPattern,
    ResponsePriority? responsePriority,
  }) {
    return TantrumProfile(
      tantrumType: tantrumType ?? this.tantrumType,
      commonTriggers: commonTriggers ?? this.commonTriggers,
      parentPattern: parentPattern ?? this.parentPattern,
      responsePriority: responsePriority ?? this.responsePriority,
    );
  }
}

@HiveType(typeId: 41)
class TantrumEvent extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime timestamp;

  @HiveField(2)
  TriggerType? trigger;

  @HiveField(3)
  TantrumIntensity intensity;

  @HiveField(4)
  int? durationSeconds;

  @HiveField(5)
  List<String> whatHelped;

  @HiveField(6)
  String? notes;

  @HiveField(7)
  bool flashcardUsed;

  TantrumEvent({
    required this.id,
    required this.timestamp,
    required this.intensity,
    required this.whatHelped,
    this.trigger,
    this.durationSeconds,
    this.notes,
    this.flashcardUsed = false,
  });

  Duration? get duration =>
      durationSeconds == null ? null : Duration(seconds: durationSeconds!);
}

@HiveType(typeId: 42)
class WeeklyTantrumPattern extends HiveObject {
  @HiveField(0)
  DateTime weekStart;

  @HiveField(1)
  int totalEvents;

  @HiveField(2)
  Map<TriggerType, int> triggerCounts;

  @HiveField(3)
  Map<DayBucket, int> timeOfDayCounts;

  @HiveField(4)
  Map<TantrumIntensity, int> intensityDistribution;

  @HiveField(5)
  List<String> topHelpers;

  @HiveField(6)
  PatternTrend trend;

  @HiveField(7)
  NormalizationStatus normalizationStatus;

  WeeklyTantrumPattern({
    required this.weekStart,
    required this.totalEvents,
    required this.triggerCounts,
    required this.timeOfDayCounts,
    required this.intensityDistribution,
    required this.topHelpers,
    required this.trend,
    required this.normalizationStatus,
  });
}
