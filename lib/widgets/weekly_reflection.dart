import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';

/// Sunday evening banner prompting a gentle weekly reflection.
/// Shown when [DateTime.now()] is Sunday and hour >= [startHour] (default 17).
class WeeklyReflectionBanner extends StatelessWidget {
  const WeeklyReflectionBanner({
    super.key,
    this.startHour = 17,
    this.onDismiss,
  });

  /// Hour of day (0-23) from which to show the banner on Sunday. Default 17 (5pm).
  final int startHour;

  /// Optional callback when user dismisses the banner (e.g. to hide for session).
  final VoidCallback? onDismiss;

  /// True if current date/time is Sunday and hour >= [startHour].
  static bool shouldShow({int startHour = 17, DateTime? now}) {
    final n = now ?? DateTime.now();
    return n.weekday == DateTime.sunday && n.hour >= startHour;
  }

  @override
  Widget build(BuildContext context) {
    return GlassCardTeal(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(Icons.auto_stories_rounded, size: 20, color: T.pal.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Reflect on your week',
                  style: T.type.h3.copyWith(color: T.pal.textPrimary),
                ),
              ),
              if (onDismiss != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: T.pal.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'A quiet moment to notice what helped and what you\'d do again.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 12),
          GlassCta(
            label: 'Open logs',
            onTap: () {
              onDismiss?.call();
              context.push('/library/logs');
            },
            compact: true,
          ),
        ],
      ),
    );
  }
}
