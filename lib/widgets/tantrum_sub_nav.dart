import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/settle_tokens.dart';

/// Sub-navigation for Tantrum tab: NOW | CARDS | LEARN.
/// Use on TantrumNowScreen, CardsLibraryScreen, TantrumLearnScreen.
class TantrumSubNav extends StatelessWidget {
  const TantrumSubNav({
    super.key,
    required this.currentSegment,
  });

  static const segmentNow = 'now';
  static const segmentCards = 'cards';
  static const segmentLearn = 'learn';

  final String currentSegment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _Segment(
            label: 'NOW',
            active: currentSegment == segmentNow,
            onTap: () => context.go('/tantrum/now'),
          ),
          const SizedBox(width: 8),
          _Segment(
            label: 'CARDS',
            active: currentSegment == segmentCards,
            onTap: () => context.go('/tantrum/cards'),
          ),
          const SizedBox(width: 8),
          _Segment(
            label: 'LEARN',
            active: currentSegment == segmentLearn,
            onTap: () => context.go('/tantrum/learn'),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? T.glass.fillAccent : T.glass.fill,
          borderRadius: BorderRadius.circular(T.radius.pill),
          border: Border.all(
            color: active ? T.pal.accent : T.glass.border,
          ),
        ),
        child: Text(
          label,
          style: T.type.caption.copyWith(
            color: active ? T.pal.accent : T.pal.textSecondary,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
