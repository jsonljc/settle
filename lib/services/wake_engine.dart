import 'dart:ui';

import '../models/approach.dart';
import '../theme/settle_tokens.dart';

/// Pure computation engine for wake window logic.
///
/// Takes the profile age, last wake time, and optional adaptive adjustment,
/// then computes elapsed minutes, progress percentage, arc color, guidance
/// text, and zone. No Flutter / provider dependencies — just math.
class WakeEngine {
  const WakeEngine._();

  // ───────────────────────────────────────────
  //  Progress zones (spec thresholds)
  // ───────────────────────────────────────────

  static const double _watchThreshold = 0.55;
  static const double _soonThreshold = 0.75;
  static const double _nowThreshold = 0.90;

  /// Compute the full wake window state from inputs.
  ///
  /// When [disruptionMode] is true, the effective target is expanded by 20%
  /// to account for travel, illness, teething, etc.
  static WakeComputation compute({
    required AgeBracket ageBracket,
    required DateTime? lastWokeAt,
    required bool isSleeping,
    int? adaptiveTargetMinutes,
    bool disruptionMode = false,
  }) {
    if (isSleeping) {
      return WakeComputation(
        elapsedMinutes: 0,
        targetMinutes: _targetFor(
          ageBracket,
          adaptiveTargetMinutes,
          disruptionMode,
        ),
        progress: 0,
        isSleeping: true,
        zone: WakeZone.sleeping,
        arcColor: T.arc.ok,
        text: '', // Sleeping state text handled by guidance provider
        subtext: '',
        ctaLabel: '',
        windowRange: ageBracket.wakeWindowMinutes,
      );
    }

    final target = _targetFor(
      ageBracket,
      adaptiveTargetMinutes,
      disruptionMode,
    );
    final since = lastWokeAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(since).inMinutes;
    final progress = target > 0 ? (elapsed / target).clamp(0.0, 1.5) : 0.0;

    final zone = _zoneFor(progress);
    final arcColor = _colorFor(zone);

    return WakeComputation(
      elapsedMinutes: elapsed,
      targetMinutes: target,
      progress: progress,
      isSleeping: false,
      zone: zone,
      arcColor: arcColor,
      text: _textFor(zone),
      subtext: _subtextFor(zone),
      ctaLabel: _ctaFor(zone),
      windowRange: ageBracket.wakeWindowMinutes,
    );
  }

  /// Resolve the effective target: adaptive override → profile midpoint.
  /// When [disruption] is true, expand the target by 20%.
  static int _targetFor(AgeBracket bracket, int? adaptive, bool disruption) {
    int base;
    if (adaptive != null) {
      base = adaptive;
    } else {
      final (lo, hi) = bracket.wakeWindowMinutes;
      base = ((lo + hi) / 2).round();
    }
    if (disruption) base = (base * 1.2).round();
    return base;
  }

  static WakeZone _zoneFor(double progress) {
    if (progress < _watchThreshold) return WakeZone.ok;
    if (progress < _soonThreshold) return WakeZone.watch;
    if (progress < _nowThreshold) return WakeZone.soon;
    return WakeZone.now;
  }

  static Color _colorFor(WakeZone zone) => switch (zone) {
    WakeZone.sleeping => T.arc.ok,
    WakeZone.ok => T.arc.ok,
    WakeZone.watch => T.arc.watch,
    WakeZone.soon => T.arc.soon,
    WakeZone.now => T.arc.now,
  };

  static String _textFor(WakeZone zone) => switch (zone) {
    WakeZone.sleeping => '',
    WakeZone.ok => 'Doing great',
    WakeZone.watch => 'Watch for sleepy cues',
    WakeZone.soon => 'Window is opening',
    WakeZone.now => 'Time to settle',
  };

  static String _subtextFor(WakeZone zone) => switch (zone) {
    WakeZone.sleeping => '',
    WakeZone.ok => 'Plenty of time in this wake window',
    WakeZone.watch => 'Yawning, eye rubbing, fussiness',
    WakeZone.soon => 'Start your settling routine now',
    WakeZone.now => 'Overtired risk increases from here',
  };

  static String _ctaFor(WakeZone zone) => switch (zone) {
    WakeZone.sleeping => 'End sleep',
    WakeZone.ok => 'Log sleep',
    WakeZone.watch => 'Log sleep',
    WakeZone.soon => 'Start settling',
    WakeZone.now => 'Start settling',
  };
}

/// The five wake zones per spec.
enum WakeZone { sleeping, ok, watch, soon, now }

/// Immutable result of a wake window computation.
class WakeComputation {
  const WakeComputation({
    required this.elapsedMinutes,
    required this.targetMinutes,
    required this.progress,
    required this.isSleeping,
    required this.zone,
    required this.arcColor,
    required this.text,
    required this.subtext,
    required this.ctaLabel,
    required this.windowRange,
  });

  /// Minutes since the baby last woke.
  final int elapsedMinutes;

  /// Effective target wake window in minutes (may be adaptively adjusted).
  final int targetMinutes;

  /// 0.0–1.5 progress through the wake window.
  final double progress;

  /// True when a sleep session is currently active.
  final bool isSleeping;

  /// Current wake zone.
  final WakeZone zone;

  /// Color for the wake arc.
  final Color arcColor;

  /// Primary guidance text.
  final String text;

  /// Secondary guidance text.
  final String subtext;

  /// CTA button label.
  final String ctaLabel;

  /// The age-bracket wake window range (min, max) in minutes.
  final (int, int) windowRange;
}
