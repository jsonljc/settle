import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/wake_engine.dart';
import 'profile_provider.dart';
import 'wake_window_provider.dart';

/// Derived state: contextual guidance text, CTA label, and arc color
/// based on wake window progress and baby profile.
///
/// Per spec: "guidance text changes are the primary UX mechanism, not the
/// arc color. The arc is peripheral information. The text tells you what to do."
///
/// Now delegates computation to [WakeEngine] via [wakeWindowProvider] and
/// enriches with profile context (baby name).
final guidanceProvider = Provider<GuidanceState>((ref) {
  final ww = ref.watch(wakeWindowProvider);
  final profile = ref.watch(profileProvider);
  final name = profile?.name ?? 'Baby';

  return GuidanceState(
    text: ww.isSleeping ? '$name is sleeping' : ww.text,
    subtext: ww.subtext,
    ctaLabel: ww.ctaLabel,
    arcColor: ww.arcColor,
    zone: ww.zone,
    isAdaptive: ww.isAdaptive,
    targetMinutes: ww.targetMinutes,
    windowRange: ww.windowRange,
  );
});

class GuidanceState {
  const GuidanceState({
    required this.text,
    required this.subtext,
    required this.ctaLabel,
    required this.arcColor,
    required this.zone,
    this.isAdaptive = false,
    this.targetMinutes = 90,
    this.windowRange = const (90, 120),
  });

  final String text;
  final String subtext;
  final String ctaLabel;
  final Color arcColor;
  final WakeZone zone;

  /// True if the guidance is using an adaptively-adjusted wake window.
  final bool isAdaptive;

  /// The effective target in minutes.
  final int targetMinutes;

  /// The age-bracket wake window range.
  final (int, int) windowRange;
}
