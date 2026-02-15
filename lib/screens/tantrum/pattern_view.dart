import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/tantrum_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/tantrum_providers.dart';
import '../../services/tantrum_engine.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import 'tantrum_unavailable.dart';

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
      body: SettleBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: T.space.screen),
                child: const ScreenHeader(title: 'Patterns'),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: T.space.screen,
                  ).copyWith(bottom: 24),
                  children: [
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LAST 7 DAYS',
                            style: T.type.overline.copyWith(
                              color: T.pal.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${pattern?.totalEvents ?? 0} hard moments logged',
                            style: T.type.h3,
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
                          Text('NORMALIZATION', style: T.type.overline),
                          const SizedBox(height: 8),
                          Text(
                            pattern?.normalizationStatus.title ??
                                'Not enough data yet',
                            style: T.type.h3,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            pattern == null || profile == null
                                ? 'Track events for at least one week to unlock personalized normalization.'
                                : TantrumEngine.normalizationMessage(
                                    pattern.normalizationStatus,
                                    profile.ageBracket,
                                  ),
                            style: T.type.body.copyWith(
                              color: T.pal.textSecondary,
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
                            style: T.type.overline.copyWith(
                              color: T.pal.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (pattern == null || pattern.topHelpers.isEmpty)
                            Text(
                              'Log what helped to see trends for this child.',
                              style: T.type.body.copyWith(
                                color: T.pal.textSecondary,
                              ),
                            )
                          else
                            ...pattern.topHelpers.asMap().entries.map(
                              (entry) => Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text(
                                  '${entry.key + 1}. ${entry.value}',
                                  style: T.type.body.copyWith(
                                    color: T.pal.textSecondary,
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
                            style: T.type.overline.copyWith(
                              color: T.pal.textTertiary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_topTrigger(pattern), style: T.type.h3),
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
                          ? T.glass.fill
                          : T.pal.accent.withValues(
                              alpha: (0.2 + (value * 0.12)).clamp(0.2, 0.8),
                            ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: T.glass.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$value',
                      style: T.type.caption.copyWith(
                        color: value == 0
                            ? T.pal.textTertiary
                            : T.pal.textPrimary,
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
          children: const [
            Text('6d', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Text('5d', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Text('4d', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Text('3d', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Text('2d', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Text('1d', style: TextStyle(fontSize: 11, color: Colors.white54)),
            Text(
              'Today',
              style: TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      ],
    );
  }
}
