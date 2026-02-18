import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tantrum_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/tantrum_providers.dart';
import '../../services/tantrum_engine.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import 'tantrum_unavailable.dart';

class _PvT {
  _PvT._();

  static final type = _PvTypeTokens();
  static const pal = _PvPaletteTokens();
  static const glass = _PvGlassTokens();
}

class _PvTypeTokens {
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
  TextStyle get h3 => SettleTypography.heading;
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption;
}

class _PvPaletteTokens {
  const _PvPaletteTokens();

  Color get textTertiary => SettleColors.nightMuted;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textPrimary => SettleColors.nightText;
  Color get accent => SettleColors.nightAccent;
}

class _PvGlassTokens {
  const _PvGlassTokens();

  Color get fill => SettleGlassDark.backgroundStrong;
  Color get border => SettleGlassDark.borderStrong;
}

// Deprecated in IA cleanup PR6. This legacy tantrum surface is no longer
// reachable from production routes and is retained only for internal reference.
class PatternViewScreen extends ConsumerWidget {
  const PatternViewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTantrumSupport = ref.watch(hasTantrumFeatureProvider);
    if (!hasTantrumSupport) {
      return const TantrumUnavailableView(title: 'Patterns');
    }

    final pattern = ref.watch(patternProvider);
    final profile = ref.watch(profileProvider);
    final events = ref.watch(tantrumEventsProvider);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SettleSpacing.screenPadding,
                ),
                child: const ScreenHeader(title: 'Patterns'),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ).copyWith(bottom: 24),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LAST 7 DAYS',
                            style: _PvT.type.overline.copyWith(
                              color: _PvT.pal.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${pattern?.totalEvents ?? 0} hard moments logged',
                            style: _PvT.type.h3,
                          ),
                          const SizedBox(height: 12),
                          _SevenDayDots(events: events),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCardAccent(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NORMALIZATION', style: _PvT.type.overline),
                          const SizedBox(height: 8),
                          Text(
                            pattern?.normalizationStatus.title ??
                                'Not enough data yet',
                            style: _PvT.type.h3,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pattern == null || profile == null
                                ? 'Track events for at least one week to unlock personalized normalization.'
                                : TantrumEngine.normalizationMessage(
                                    pattern.normalizationStatus,
                                    profile.ageBracket,
                                  ),
                            style: _PvT.type.body.copyWith(
                              color: _PvT.pal.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOP HELPERS',
                            style: _PvT.type.overline.copyWith(
                              color: _PvT.pal.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (pattern == null || pattern.topHelpers.isEmpty)
                            Text(
                              'Log what helped to see trends for this child.',
                              style: _PvT.type.body.copyWith(
                                color: _PvT.pal.textSecondary,
                              ),
                            )
                          else
                            ...pattern.topHelpers.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${entry.key + 1}. ${entry.value}',
                                  style: _PvT.type.body.copyWith(
                                    color: _PvT.pal.textSecondary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MOST COMMON TRIGGER',
                            style: _PvT.type.overline.copyWith(
                              color: _PvT.pal.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_topTrigger(pattern), style: _PvT.type.h3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _topTrigger(WeeklyTantrumPattern? pattern) {
    if (pattern == null) return 'No events yet';
    final ranked = pattern.triggerCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = ranked.firstWhere(
      (e) => e.value > 0,
      orElse: () => const MapEntry(TriggerType.unpredictable, 0),
    );

    if (top.value == 0) return 'No clear trigger yet';
    return '${top.key.label} (${top.value})';
  }
}

class _SevenDayDots extends StatelessWidget {
  const _SevenDayDots({required this.events});

  final List<TantrumEvent> events;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final counts = List<int>.filled(7, 0);

    for (final event in events) {
      final day = DateTime(
        event.timestamp.year,
        event.timestamp.month,
        event.timestamp.day,
      );
      final nowDay = DateTime(today.year, today.month, today.day);
      final diff = nowDay.difference(day).inDays;
      if (diff >= 0 && diff < 7) {
        counts[6 - diff] += 1;
      }
    }

    return Column(
      children: [
        Row(
          children: List.generate(7, (index) {
            final value = counts[index];
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Semantics(
                  label: 'Day ${index + 1}: $value events',
                  child: Container(
                    height: 30,
                    decoration: BoxDecoration(
                      color: value == 0
                          ? _PvT.glass.fill
                          : _PvT.pal.accent.withValues(
                              alpha: (0.2 + (value * 0.12)).clamp(0.2, 0.8),
                            ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _PvT.glass.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$value',
                      style: _PvT.type.caption.copyWith(
                        color: value == 0
                            ? _PvT.pal.textTertiary
                            : _PvT.pal.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '6d',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
            Text(
              '5d',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
            Text(
              '4d',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
            Text(
              '3d',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
            Text(
              '2d',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
            Text(
              '1d',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
            Text(
              'Today',
              style: _PvT.type.caption.copyWith(color: _PvT.pal.textTertiary),
            ),
          ],
        ),
      ],
    );
  }
}
