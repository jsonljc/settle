import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/sleep_session.dart';
import '../../models/usage_event.dart';
import '../../models/v2_enums.dart';
import '../../providers/plan_ordering_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/usage_events_provider.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';

final _librarySleepHistoryProvider = FutureProvider<List<SleepSession>>((
  ref,
) async {
  ref.watch(sessionProvider);
  return ref.read(sessionProvider.notifier).history;
});

class LibraryLogsScreen extends ConsumerWidget {
  const LibraryLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usageEvents = ref.watch(usageEventsProvider);
    final triggerByCardIdAsync = ref.watch(cardIdToTriggerTypeProvider);
    final sleepHistoryAsync = ref.watch(_librarySleepHistoryProvider);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Logs',
                  subtitle: 'Chronological timeline of what happened.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: SettleSpacing.lg),
                Expanded(
                  child: triggerByCardIdAsync.when(
                    loading: () => const CalmLoading(message: 'Loading logs…'),
                    error: (_, __) => const _LogsErrorCard(),
                    data: (triggerByCardId) => sleepHistoryAsync.when(
                      loading: () =>
                          const CalmLoading(message: 'Loading sleep history…'),
                      error: (_, __) => const _LogsErrorCard(),
                      data: (sleepHistory) {
                        final entries = _buildTimelineEntries(
                          usageEvents: usageEvents,
                          sleepHistory: sleepHistory,
                          triggerByCardId: triggerByCardId,
                        );
                        if (entries.isEmpty) {
                          return const _LogsEmptyState();
                        }

                        return ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: entries.length,
                          itemBuilder: (context, index) {
                            final entry = entries[index];
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: SettleSpacing.sm,
                              ),
                              child: Semantics(
                                button: entry.route != null,
                                label: entry.semanticLabel,
                                child: GlassCard(
                                  onTap: entry.route == null
                                      ? null
                                      : () => context.push(entry.route!),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        entry.icon,
                                        size: 18,
                                        color: _accentColor(context),
                                      ),
                                      const SizedBox(width: SettleSpacing.sm),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              entry.title,
                                              style: SettleTypography.body
                                                  .copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const SizedBox(
                                              height: SettleSpacing.xs,
                                            ),
                                            Text(
                                              entry.subtitle,
                                              style: SettleTypography.caption
                                                  .copyWith(
                                                    color: _mutedTextColor(
                                                      context,
                                                    ),
                                                  ),
                                            ),
                                            if (entry.detail != null) ...[
                                              const SizedBox(
                                                height: SettleSpacing.xs,
                                              ),
                                              Text(
                                                entry.detail!,
                                                style: SettleTypography.caption
                                                    .copyWith(
                                                      color:
                                                          _supportingTextColor(
                                                            context,
                                                          ),
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: SettleSpacing.sm),
                                      Text(
                                        _formatDayTime(entry.timestamp),
                                        style: SettleTypography.caption
                                            .copyWith(
                                              color: _mutedTextColor(context),
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LogsErrorCard extends StatelessWidget {
  const _LogsErrorCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GlassCard(
        child: Text(
          'Could not load logs. Try again in a moment.',
          style: SettleTypography.body.copyWith(
            color: _supportingTextColor(context),
          ),
        ),
      ),
    );
  }
}

class _LogsEmptyState extends StatelessWidget {
  const _LogsEmptyState();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No logs yet', style: SettleTypography.heading),
            const SizedBox(height: SettleSpacing.sm),
            Text(
              'Once you run a script or log sleep, entries will appear here in timeline order.',
              style: SettleTypography.body.copyWith(
                color: _supportingTextColor(context),
              ),
            ),
            const SizedBox(height: SettleSpacing.md),
            GlassPill(
              label: 'Open Now',
              onTap: () => context.push('/plan'),
              variant: GlassPillVariant.primaryLight,
              expanded: true,
            ),
            const SizedBox(height: SettleSpacing.sm),
            GlassPill(
              label: 'Open Sleep',
              onTap: () => context.push('/sleep'),
              variant: GlassPillVariant.secondaryLight,
              expanded: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry({
    required this.timestamp,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.semanticLabel,
    this.detail,
    this.route,
  });

  final DateTime timestamp;
  final String title;
  final String subtitle;
  final String? detail;
  final IconData icon;
  final String semanticLabel;
  final String? route;
}

List<_TimelineEntry> _buildTimelineEntries({
  required List<UsageEvent> usageEvents,
  required List<SleepSession> sleepHistory,
  required Map<String, String> triggerByCardId,
}) {
  final entries = <_TimelineEntry>[];

  for (final event in usageEvents.take(80)) {
    final trigger = triggerByCardId[event.cardId] ?? event.cardId;
    entries.add(
      _TimelineEntry(
        timestamp: event.timestamp,
        title: _titleCaseFromId(trigger),
        subtitle: _outcomeLabel(event.outcome),
        detail: event.context?.trim().isEmpty ?? true ? null : event.context,
        icon: _outcomeIcon(event.outcome),
        semanticLabel: 'Open ${_titleCaseFromId(trigger)} log',
        route: '/library/cards/${event.cardId}',
      ),
    );
  }

  for (final session in sleepHistory.take(80)) {
    final duration = _formatDuration(session.duration);
    entries.add(
      _TimelineEntry(
        timestamp: session.startedAt,
        title: session.isNight ? 'Night sleep logged' : 'Nap logged',
        subtitle: duration,
        detail: session.endedAt == null
            ? null
            : '${_formatClock(session.startedAt)} to ${_formatClock(session.endedAt!)}',
        icon: session.isNight ? Icons.nightlight_round : Icons.bedtime_outlined,
        semanticLabel: 'Open sleep timeline',
        route: '/sleep',
      ),
    );
  }

  entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return entries;
}

String _outcomeLabel(UsageOutcome? outcome) {
  if (outcome == null) return 'Used';
  return switch (outcome) {
    UsageOutcome.great => 'Worked',
    UsageOutcome.okay => 'Partly worked',
    UsageOutcome.didntWork => 'Not quite',
    UsageOutcome.didntTry => 'Didn\'t try',
  };
}

IconData _outcomeIcon(UsageOutcome? outcome) {
  return switch (outcome) {
    UsageOutcome.great => Icons.thumb_up_alt_rounded,
    UsageOutcome.okay => Icons.check_circle_outline_rounded,
    UsageOutcome.didntWork => Icons.refresh_rounded,
    UsageOutcome.didntTry => Icons.remove_circle_outline_rounded,
    null => Icons.menu_book_rounded,
  };
}

String _titleCaseFromId(String value) {
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDayTime(DateTime timestamp) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(timestamp.year, timestamp.month, timestamp.day);
  final daysAgo = today.difference(day).inDays;
  if (daysAgo == 0) return _formatClock(timestamp);
  if (daysAgo == 1) return 'Yesterday';
  if (daysAgo < 7) {
    return switch (timestamp.weekday) {
      DateTime.monday => 'Mon',
      DateTime.tuesday => 'Tue',
      DateTime.wednesday => 'Wed',
      DateTime.thursday => 'Thu',
      DateTime.friday => 'Fri',
      DateTime.saturday => 'Sat',
      DateTime.sunday => 'Sun',
      _ => '${timestamp.month}/${timestamp.day}',
    };
  }
  return '${timestamp.month}/${timestamp.day}';
}

String _formatClock(DateTime time) {
  final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = time.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $period';
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours == 0) {
    return '${duration.inMinutes}m';
  }
  if (minutes == 0) {
    return '${hours}h';
  }
  return '${hours}h ${minutes}m';
}

Color _supportingTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightSoft : SettleColors.ink500;
}

Color _mutedTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightMuted : SettleColors.ink400;
}

Color _accentColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightAccent : SettleColors.sage600;
}
