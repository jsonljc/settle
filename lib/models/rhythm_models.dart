enum RhythmConfidence { high, medium, low }

extension RhythmConfidenceLabel on RhythmConfidence {
  String get label => switch (this) {
    RhythmConfidence.high => 'High',
    RhythmConfidence.medium => 'Medium',
    RhythmConfidence.low => 'Low',
  };

  static RhythmConfidence fromString(String raw) {
    return switch (raw) {
      'high' => RhythmConfidence.high,
      'medium' => RhythmConfidence.medium,
      'low' => RhythmConfidence.low,
      _ => RhythmConfidence.medium,
    };
  }

  String get wire => switch (this) {
    RhythmConfidence.high => 'high',
    RhythmConfidence.medium => 'medium',
    RhythmConfidence.low => 'low',
  };
}

class RhythmLocks {
  const RhythmLocks({
    required this.bedtimeAnchorLocked,
    required this.daycareNapBlocksLocked,
    required this.hardConstraintBlocksLocked,
  });

  final bool bedtimeAnchorLocked;
  final bool daycareNapBlocksLocked;
  final bool hardConstraintBlocksLocked;

  RhythmLocks copyWith({
    bool? bedtimeAnchorLocked,
    bool? daycareNapBlocksLocked,
    bool? hardConstraintBlocksLocked,
  }) {
    return RhythmLocks(
      bedtimeAnchorLocked: bedtimeAnchorLocked ?? this.bedtimeAnchorLocked,
      daycareNapBlocksLocked:
          daycareNapBlocksLocked ?? this.daycareNapBlocksLocked,
      hardConstraintBlocksLocked:
          hardConstraintBlocksLocked ?? this.hardConstraintBlocksLocked,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bedtime_anchor_locked': bedtimeAnchorLocked,
      'daycare_nap_blocks_locked': daycareNapBlocksLocked,
      'hard_constraint_blocks_locked': hardConstraintBlocksLocked,
    };
  }

  static RhythmLocks fromMap(Map<String, dynamic> raw) {
    return RhythmLocks(
      bedtimeAnchorLocked: raw['bedtime_anchor_locked'] as bool? ?? true,
      daycareNapBlocksLocked:
          raw['daycare_nap_blocks_locked'] as bool? ?? false,
      hardConstraintBlocksLocked:
          raw['hard_constraint_blocks_locked'] as bool? ?? false,
    );
  }
}

class Rhythm {
  const Rhythm({
    required this.id,
    required this.ageMonths,
    required this.napCountTarget,
    required this.napTargetsBySlotMinutes,
    required this.wakeWindowsBySlotMinutes,
    required this.bedtimeAnchorMinutes,
    required this.softWindowMinutes,
    required this.rescueNapEnabled,
    required this.locks,
    required this.confidence,
    required this.hysteresisMinutes,
    required this.updatedAt,
  });

  final String id;
  final int ageMonths;
  final int napCountTarget;
  final Map<String, int> napTargetsBySlotMinutes;

  /// Wake windows keyed by nap slot id (`nap1`, `nap2`, ...) and `bedtime`.
  final Map<String, int> wakeWindowsBySlotMinutes;
  final int bedtimeAnchorMinutes;
  final int softWindowMinutes;
  final bool rescueNapEnabled;
  final RhythmLocks locks;
  final RhythmConfidence confidence;
  final int hysteresisMinutes;
  final DateTime updatedAt;

  Rhythm copyWith({
    String? id,
    int? ageMonths,
    int? napCountTarget,
    Map<String, int>? napTargetsBySlotMinutes,
    Map<String, int>? wakeWindowsBySlotMinutes,
    int? bedtimeAnchorMinutes,
    int? softWindowMinutes,
    bool? rescueNapEnabled,
    RhythmLocks? locks,
    RhythmConfidence? confidence,
    int? hysteresisMinutes,
    DateTime? updatedAt,
  }) {
    return Rhythm(
      id: id ?? this.id,
      ageMonths: ageMonths ?? this.ageMonths,
      napCountTarget: napCountTarget ?? this.napCountTarget,
      napTargetsBySlotMinutes:
          napTargetsBySlotMinutes ?? this.napTargetsBySlotMinutes,
      wakeWindowsBySlotMinutes:
          wakeWindowsBySlotMinutes ?? this.wakeWindowsBySlotMinutes,
      bedtimeAnchorMinutes: bedtimeAnchorMinutes ?? this.bedtimeAnchorMinutes,
      softWindowMinutes: softWindowMinutes ?? this.softWindowMinutes,
      rescueNapEnabled: rescueNapEnabled ?? this.rescueNapEnabled,
      locks: locks ?? this.locks,
      confidence: confidence ?? this.confidence,
      hysteresisMinutes: hysteresisMinutes ?? this.hysteresisMinutes,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'age_months': ageMonths,
      'nap_count_target': napCountTarget,
      'nap_targets_by_slot_minutes': napTargetsBySlotMinutes,
      'wake_windows_by_slot_minutes': wakeWindowsBySlotMinutes,
      'bedtime_anchor_minutes': bedtimeAnchorMinutes,
      'soft_window_minutes': softWindowMinutes,
      'rescue_nap_enabled': rescueNapEnabled,
      'locks': locks.toMap(),
      'confidence': confidence.wire,
      'hysteresis_minutes': hysteresisMinutes,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static Rhythm fromMap(Map<String, dynamic> raw) {
    final napCount = raw['nap_count_target'] as int? ?? 3;
    final napTargetsRaw = (raw['nap_targets_by_slot_minutes'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 75),
    );
    final wakeWindowsRaw = (raw['wake_windows_by_slot_minutes'] as Map?)?.map(
      (k, v) => MapEntry(k.toString(), int.tryParse(v.toString()) ?? 120),
    );

    return Rhythm(
      id: raw['id']?.toString() ?? 'rhythm_default',
      ageMonths: raw['age_months'] as int? ?? 6,
      napCountTarget: napCount,
      napTargetsBySlotMinutes: napTargetsRaw ?? _defaultNapTargets(napCount),
      wakeWindowsBySlotMinutes:
          wakeWindowsRaw ?? const {'nap1': 120, 'nap2': 150, 'bedtime': 180},
      bedtimeAnchorMinutes: raw['bedtime_anchor_minutes'] as int? ?? 1140,
      softWindowMinutes: raw['soft_window_minutes'] as int? ?? 20,
      rescueNapEnabled: raw['rescue_nap_enabled'] as bool? ?? true,
      locks: RhythmLocks.fromMap(
        (raw['locks'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      confidence: RhythmConfidenceLabel.fromString(
        raw['confidence']?.toString() ?? 'medium',
      ),
      hysteresisMinutes: raw['hysteresis_minutes'] as int? ?? 20,
      updatedAt:
          DateTime.tryParse(raw['updated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static Map<String, int> _defaultNapTargets(int napCount) {
    final profile = switch (napCount) {
      4 => const [55, 55, 45, 35],
      3 => const [80, 75, 45],
      2 => const [90, 75],
      _ => const [120],
    };
    return {
      for (var i = 1; i <= napCount; i++)
        'nap$i': profile[(i - 1).clamp(0, profile.length - 1)],
    };
  }
}

enum RhythmDayEventType { shortNap, skippedNap, earlyWake }

extension RhythmDayEventTypeWire on RhythmDayEventType {
  String get wire => switch (this) {
    RhythmDayEventType.shortNap => 'short_nap',
    RhythmDayEventType.skippedNap => 'skipped_nap',
    RhythmDayEventType.earlyWake => 'early_wake',
  };

  static RhythmDayEventType fromString(String raw) {
    return switch (raw) {
      'short_nap' => RhythmDayEventType.shortNap,
      'skipped_nap' => RhythmDayEventType.skippedNap,
      'early_wake' => RhythmDayEventType.earlyWake,
      _ => RhythmDayEventType.shortNap,
    };
  }
}

class RhythmDayEvent {
  const RhythmDayEvent({
    required this.type,
    required this.napIndex,
    required this.createdAt,
  });

  final RhythmDayEventType type;
  final int napIndex;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'type': type.wire,
      'nap_index': napIndex,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static RhythmDayEvent fromMap(Map<String, dynamic> raw) {
    return RhythmDayEvent(
      type: RhythmDayEventTypeWire.fromString(raw['type']?.toString() ?? ''),
      napIndex: raw['nap_index'] as int? ?? 1,
      createdAt:
          DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class RhythmScheduleBlock {
  const RhythmScheduleBlock({
    required this.id,
    required this.label,
    required this.centerlineMinutes,
    required this.windowStartMinutes,
    required this.windowEndMinutes,
    required this.anchorLocked,
    this.expectedDurationMinMinutes,
    this.expectedDurationMaxMinutes,
  });

  final String id;
  final String label;
  final int centerlineMinutes;
  final int windowStartMinutes;
  final int windowEndMinutes;
  final bool anchorLocked;
  final int? expectedDurationMinMinutes;
  final int? expectedDurationMaxMinutes;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'centerline_minutes': centerlineMinutes,
      'window_start_minutes': windowStartMinutes,
      'window_end_minutes': windowEndMinutes,
      'anchor_locked': anchorLocked,
      'expected_duration_min_minutes': expectedDurationMinMinutes,
      'expected_duration_max_minutes': expectedDurationMaxMinutes,
    };
  }

  static RhythmScheduleBlock fromMap(Map<String, dynamic> raw) {
    return RhythmScheduleBlock(
      id: raw['id']?.toString() ?? 'block',
      label: raw['label']?.toString() ?? 'Block',
      centerlineMinutes: raw['centerline_minutes'] as int? ?? 0,
      windowStartMinutes: raw['window_start_minutes'] as int? ?? 0,
      windowEndMinutes: raw['window_end_minutes'] as int? ?? 0,
      anchorLocked: raw['anchor_locked'] as bool? ?? false,
      expectedDurationMinMinutes: raw['expected_duration_min_minutes'] as int?,
      expectedDurationMaxMinutes: raw['expected_duration_max_minutes'] as int?,
    );
  }
}

class DaySchedule {
  const DaySchedule({
    required this.dateKey,
    required this.wakeTimeMinutes,
    required this.wakeTimeKnown,
    required this.blocks,
    required this.confidence,
    required this.appliedHysteresis,
    required this.generatedAt,
  });

  final String dateKey;
  final int wakeTimeMinutes;
  final bool wakeTimeKnown;
  final List<RhythmScheduleBlock> blocks;
  final RhythmConfidence confidence;
  final bool appliedHysteresis;
  final DateTime generatedAt;

  DaySchedule copyWith({
    String? dateKey,
    int? wakeTimeMinutes,
    bool? wakeTimeKnown,
    List<RhythmScheduleBlock>? blocks,
    RhythmConfidence? confidence,
    bool? appliedHysteresis,
    DateTime? generatedAt,
  }) {
    return DaySchedule(
      dateKey: dateKey ?? this.dateKey,
      wakeTimeMinutes: wakeTimeMinutes ?? this.wakeTimeMinutes,
      wakeTimeKnown: wakeTimeKnown ?? this.wakeTimeKnown,
      blocks: blocks ?? this.blocks,
      confidence: confidence ?? this.confidence,
      appliedHysteresis: appliedHysteresis ?? this.appliedHysteresis,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date_key': dateKey,
      'wake_time_minutes': wakeTimeMinutes,
      'wake_time_known': wakeTimeKnown,
      'blocks': blocks.map((b) => b.toMap()).toList(),
      'confidence': confidence.wire,
      'applied_hysteresis': appliedHysteresis,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  static DaySchedule fromMap(Map<String, dynamic> raw) {
    return DaySchedule(
      dateKey: raw['date_key']?.toString() ?? '',
      wakeTimeMinutes: raw['wake_time_minutes'] as int? ?? 420,
      wakeTimeKnown: raw['wake_time_known'] as bool? ?? false,
      blocks: (raw['blocks'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => RhythmScheduleBlock.fromMap(e.cast<String, dynamic>()))
          .toList(),
      confidence: RhythmConfidenceLabel.fromString(
        raw['confidence']?.toString() ?? 'medium',
      ),
      appliedHysteresis: raw['applied_hysteresis'] as bool? ?? false,
      generatedAt:
          DateTime.tryParse(raw['generated_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

enum MorningRecapNightQuality { good, ok, rough }

extension MorningRecapNightQualityWire on MorningRecapNightQuality {
  String get wire => switch (this) {
    MorningRecapNightQuality.good => 'good',
    MorningRecapNightQuality.ok => 'ok',
    MorningRecapNightQuality.rough => 'rough',
  };

  String get label => switch (this) {
    MorningRecapNightQuality.good => 'Good',
    MorningRecapNightQuality.ok => 'OK',
    MorningRecapNightQuality.rough => 'Rough',
  };

  static MorningRecapNightQuality fromString(String raw) {
    return switch (raw) {
      'good' => MorningRecapNightQuality.good,
      'ok' => MorningRecapNightQuality.ok,
      'rough' => MorningRecapNightQuality.rough,
      _ => MorningRecapNightQuality.ok,
    };
  }
}

enum MorningRecapWakesBucket { zero, oneToTwo, threePlus }

extension MorningRecapWakesBucketWire on MorningRecapWakesBucket {
  String get wire => switch (this) {
    MorningRecapWakesBucket.zero => '0',
    MorningRecapWakesBucket.oneToTwo => '1-2',
    MorningRecapWakesBucket.threePlus => '3+',
  };

  String get label => wire;

  static MorningRecapWakesBucket fromString(String raw) {
    return switch (raw) {
      '0' => MorningRecapWakesBucket.zero,
      '1-2' => MorningRecapWakesBucket.oneToTwo,
      '3+' => MorningRecapWakesBucket.threePlus,
      _ => MorningRecapWakesBucket.oneToTwo,
    };
  }
}

enum MorningRecapLongestAwakeBucket { under10, tenTo30, over30 }

extension MorningRecapLongestAwakeBucketWire on MorningRecapLongestAwakeBucket {
  String get wire => switch (this) {
    MorningRecapLongestAwakeBucket.under10 => '<10',
    MorningRecapLongestAwakeBucket.tenTo30 => '10-30',
    MorningRecapLongestAwakeBucket.over30 => '30+',
  };

  String get label => wire;

  static MorningRecapLongestAwakeBucket fromString(String raw) {
    return switch (raw) {
      '<10' => MorningRecapLongestAwakeBucket.under10,
      '10-30' => MorningRecapLongestAwakeBucket.tenTo30,
      '30+' => MorningRecapLongestAwakeBucket.over30,
      _ => MorningRecapLongestAwakeBucket.tenTo30,
    };
  }
}

class MorningRecapEntry {
  const MorningRecapEntry({
    required this.dateKey,
    required this.nightQuality,
    required this.wakesBucket,
    required this.longestAwakeBucket,
    required this.createdAt,
  });

  final String dateKey;
  final MorningRecapNightQuality nightQuality;
  final MorningRecapWakesBucket wakesBucket;
  final MorningRecapLongestAwakeBucket longestAwakeBucket;
  final DateTime createdAt;

  Map<String, dynamic> toMap() {
    return {
      'date_key': dateKey,
      'night_quality': nightQuality.wire,
      'wakes_bucket': wakesBucket.wire,
      'longest_awake_bucket': longestAwakeBucket.wire,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static MorningRecapEntry fromMap(Map<String, dynamic> raw) {
    return MorningRecapEntry(
      dateKey: raw['date_key']?.toString() ?? '',
      nightQuality: MorningRecapNightQualityWire.fromString(
        raw['night_quality']?.toString() ?? '',
      ),
      wakesBucket: MorningRecapWakesBucketWire.fromString(
        raw['wakes_bucket']?.toString() ?? '',
      ),
      longestAwakeBucket: MorningRecapLongestAwakeBucketWire.fromString(
        raw['longest_awake_bucket']?.toString() ?? '',
      ),
      createdAt:
          DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class RhythmDailySignal {
  const RhythmDailySignal({
    required this.dateKey,
    required this.shortNapCount,
    required this.skippedNapCount,
    this.okNapCount = 0,
    this.longNapCount = 0,
    this.advancedNapStartCount = 0,
    this.advancedNapEndCount = 0,
    required this.earlyWakeLogged,
    required this.bedtimeResistance,
    required this.bedtimeDelayMinutes,
    required this.createdAt,
  });

  final String dateKey;
  final int shortNapCount;
  final int skippedNapCount;
  final int okNapCount;
  final int longNapCount;
  final int advancedNapStartCount;
  final int advancedNapEndCount;
  final bool earlyWakeLogged;
  final bool bedtimeResistance;
  final int bedtimeDelayMinutes;
  final DateTime createdAt;

  int get dayTapCount =>
      shortNapCount +
      skippedNapCount +
      okNapCount +
      longNapCount +
      advancedNapStartCount +
      advancedNapEndCount;

  RhythmDailySignal copyWith({
    String? dateKey,
    int? shortNapCount,
    int? skippedNapCount,
    int? okNapCount,
    int? longNapCount,
    int? advancedNapStartCount,
    int? advancedNapEndCount,
    bool? earlyWakeLogged,
    bool? bedtimeResistance,
    int? bedtimeDelayMinutes,
    DateTime? createdAt,
  }) {
    return RhythmDailySignal(
      dateKey: dateKey ?? this.dateKey,
      shortNapCount: shortNapCount ?? this.shortNapCount,
      skippedNapCount: skippedNapCount ?? this.skippedNapCount,
      okNapCount: okNapCount ?? this.okNapCount,
      longNapCount: longNapCount ?? this.longNapCount,
      advancedNapStartCount:
          advancedNapStartCount ?? this.advancedNapStartCount,
      advancedNapEndCount: advancedNapEndCount ?? this.advancedNapEndCount,
      earlyWakeLogged: earlyWakeLogged ?? this.earlyWakeLogged,
      bedtimeResistance: bedtimeResistance ?? this.bedtimeResistance,
      bedtimeDelayMinutes: bedtimeDelayMinutes ?? this.bedtimeDelayMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date_key': dateKey,
      'short_nap_count': shortNapCount,
      'skipped_nap_count': skippedNapCount,
      'ok_nap_count': okNapCount,
      'long_nap_count': longNapCount,
      'advanced_nap_start_count': advancedNapStartCount,
      'advanced_nap_end_count': advancedNapEndCount,
      'early_wake_logged': earlyWakeLogged,
      'bedtime_resistance': bedtimeResistance,
      'bedtime_delay_minutes': bedtimeDelayMinutes,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static RhythmDailySignal fromMap(Map<String, dynamic> raw) {
    return RhythmDailySignal(
      dateKey: raw['date_key']?.toString() ?? '',
      shortNapCount: raw['short_nap_count'] as int? ?? 0,
      skippedNapCount: raw['skipped_nap_count'] as int? ?? 0,
      okNapCount: raw['ok_nap_count'] as int? ?? 0,
      longNapCount: raw['long_nap_count'] as int? ?? 0,
      advancedNapStartCount: raw['advanced_nap_start_count'] as int? ?? 0,
      advancedNapEndCount: raw['advanced_nap_end_count'] as int? ?? 0,
      earlyWakeLogged: raw['early_wake_logged'] as bool? ?? false,
      bedtimeResistance: raw['bedtime_resistance'] as bool? ?? false,
      bedtimeDelayMinutes: raw['bedtime_delay_minutes'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(raw['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

enum RhythmShiftReasonType {
  roughNights,
  earlyWakes,
  shortNaps,
  bedtimeDrift,
  ageTransition,
}

class RhythmShiftReason {
  const RhythmShiftReason({
    required this.type,
    required this.title,
    required this.detail,
    required this.hardTrigger,
  });

  final RhythmShiftReasonType type;
  final String title;
  final String detail;
  final bool hardTrigger;
}

class RhythmShiftAssessment {
  const RhythmShiftAssessment({
    required this.shouldSuggestUpdate,
    required this.softPromptOnly,
    required this.reasons,
    required this.explanation,
  });

  static const none = RhythmShiftAssessment(
    shouldSuggestUpdate: false,
    softPromptOnly: false,
    reasons: [],
    explanation: 'No pattern shift detected. Keep current rhythm for now.',
  );

  final bool shouldSuggestUpdate;
  final bool softPromptOnly;
  final List<RhythmShiftReason> reasons;
  final String explanation;
}

enum RhythmUpdateIssue { earlyWakes, nightWakes, shortNaps, bedtimeBattles }

extension RhythmUpdateIssueWire on RhythmUpdateIssue {
  String get wire => switch (this) {
    RhythmUpdateIssue.earlyWakes => 'early_wakes',
    RhythmUpdateIssue.nightWakes => 'night_wakes',
    RhythmUpdateIssue.shortNaps => 'short_naps',
    RhythmUpdateIssue.bedtimeBattles => 'bedtime_battles',
  };

  String get label => switch (this) {
    RhythmUpdateIssue.earlyWakes => 'Early wakes',
    RhythmUpdateIssue.nightWakes => 'Night wakes',
    RhythmUpdateIssue.shortNaps => 'Short naps',
    RhythmUpdateIssue.bedtimeBattles => 'Bedtime battles',
  };

  static RhythmUpdateIssue fromString(String raw) {
    return switch (raw) {
      'early_wakes' => RhythmUpdateIssue.earlyWakes,
      'night_wakes' => RhythmUpdateIssue.nightWakes,
      'short_naps' => RhythmUpdateIssue.shortNaps,
      'bedtime_battles' => RhythmUpdateIssue.bedtimeBattles,
      _ => RhythmUpdateIssue.nightWakes,
    };
  }
}

class RhythmUpdatePlan {
  const RhythmUpdatePlan({
    required this.rhythm,
    required this.anchorRecommendation,
    required this.confidence,
    required this.changeSummary,
    required this.whyNow,
  });

  final Rhythm rhythm;
  final String anchorRecommendation;
  final RhythmConfidence confidence;
  final List<String> changeSummary;
  final String whyNow;
}

enum NapQualityTap { short, ok, long }
