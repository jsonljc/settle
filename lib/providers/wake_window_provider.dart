import 'dart:async';
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/approach.dart';
import '../models/sleep_session.dart';
import '../services/wake_engine.dart';
import 'adaptive_provider.dart';
import 'disruption_provider.dart';
import 'profile_provider.dart';
import 'session_provider.dart';

/// Derived state: elapsed wake minutes, progress, zone, arc color, guidance.
///
/// Recomputes when profile, session, or adaptive recommendation changes.
/// Ticks every minute while baby is awake.
final wakeWindowProvider =
    StateNotifierProvider<WakeWindowNotifier, WakeWindowState>((ref) {
  final profile = ref.watch(profileProvider);
  final activeSession = ref.watch(sessionProvider);
  final sessionNotifier = ref.read(sessionProvider.notifier);
  final adaptive = ref.watch(adaptiveProvider);
  final disruption = ref.watch(disruptionProvider);

  final lastWokeAt = sessionNotifier.lastWokeAt;
  final ageBracket = profile?.ageBracket ?? AgeBracket.fourToFiveMonths;
  final name = profile?.name ?? 'Baby';

  return WakeWindowNotifier(
    ageBracket: ageBracket,
    name: name,
    activeSession: activeSession,
    lastWokeAt: lastWokeAt,
    adaptiveTargetMinutes: adaptive.recommendedMinutes,
    disruptionMode: disruption,
  );
});

class WakeWindowState {
  const WakeWindowState({
    required this.elapsedMinutes,
    required this.targetMinutes,
    required this.progress,
    required this.isSleeping,
    required this.zone,
    required this.arcColor,
    required this.text,
    required this.subtext,
    required this.ctaLabel,
    required this.isAdaptive,
    required this.windowRange,
    this.isFirstDay = false,
  });

  /// Minutes since the baby last woke.
  final int elapsedMinutes;

  /// Effective target wake window in minutes.
  final int targetMinutes;

  /// 0.0–1.5 progress through the wake window.
  final double progress;

  /// True when a sleep session is currently active.
  final bool isSleeping;

  /// Current wake zone.
  final WakeZone zone;

  /// Color for the wake arc.
  final Color arcColor;

  /// Primary guidance text (zone-aware).
  final String text;

  /// Secondary guidance text.
  final String subtext;

  /// CTA button label.
  final String ctaLabel;

  /// True if the target was adjusted by the adaptive scheduler.
  final bool isAdaptive;

  /// The age-bracket wake window range (min, max) in minutes.
  final (int, int) windowRange;

  /// True on first use when no sleep sessions have been logged yet.
  final bool isFirstDay;

  static const initial = WakeWindowState(
    elapsedMinutes: 0,
    targetMinutes: 90,
    progress: 0,
    isSleeping: false,
    zone: WakeZone.ok,
    arcColor: Color(0xFF6EE7B7),
    text: '',
    subtext: '',
    ctaLabel: 'Log sleep',
    isAdaptive: false,
    windowRange: (90, 120),
  );
}

class WakeWindowNotifier extends StateNotifier<WakeWindowState> {
  WakeWindowNotifier({
    required this.ageBracket,
    required this.name,
    required this.activeSession,
    required this.lastWokeAt,
    required this.adaptiveTargetMinutes,
    this.disruptionMode = false,
  }) : super(WakeWindowState.initial) {
    _update();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _update());
  }

  final AgeBracket ageBracket;
  final String name;
  final SleepSession? activeSession;
  final DateTime? lastWokeAt;
  final int? adaptiveTargetMinutes;
  final bool disruptionMode;
  Timer? _ticker;

  void _update() {
    final computation = WakeEngine.compute(
      ageBracket: ageBracket,
      lastWokeAt: lastWokeAt,
      isSleeping: activeSession != null,
      adaptiveTargetMinutes: adaptiveTargetMinutes,
      disruptionMode: disruptionMode,
    );

    // For sleeping state, personalise the text
    final text = computation.isSleeping ? '$name is sleeping' : computation.text;
    final subtext =
        computation.isSleeping ? 'Rest while you can' : computation.subtext;
    final ctaLabel =
        computation.isSleeping ? 'End sleep' : computation.ctaLabel;

    // Personalise the "doing great" message
    final personalText = computation.zone == WakeZone.ok && !computation.isSleeping
        ? '$name is doing great'
        : text;

    state = WakeWindowState(
      elapsedMinutes: computation.elapsedMinutes,
      targetMinutes: computation.targetMinutes,
      progress: computation.progress,
      isSleeping: computation.isSleeping,
      zone: computation.zone,
      arcColor: computation.arcColor,
      text: personalText,
      subtext: subtext,
      ctaLabel: ctaLabel,
      isAdaptive: adaptiveTargetMinutes != null,
      windowRange: computation.windowRange,
      isFirstDay: lastWokeAt == null && activeSession == null,
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }
}
