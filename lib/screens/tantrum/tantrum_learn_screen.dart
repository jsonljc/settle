import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/models/tantrum_lesson.dart';
import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../widgets/glass_card.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/tantrum_sub_nav.dart';

/// LEARN: micro-lessons that link back to cards (by lessonId / cardIds).
class TantrumLearnScreen extends ConsumerWidget {
  const TantrumLearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(tantrumLessonsProvider);

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
                  title: 'LEARN',
                  subtitle: 'Micro-lessons linked to your cards',
                  fallbackRoute: '/tantrum',
                ),
                const SizedBox(height: 12),
                const TantrumSubNav(currentSegment: TantrumSubNav.segmentLearn),
                const SizedBox(height: 16),
                Expanded(
                  child: lessonsAsync.when(
                    data: (lessons) => ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: lessons.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
                        return _LessonCard(
                          lesson: lesson,
                          onCardTap: (cardId) => context.push(
                            '/tantrum/deck/${Uri.encodeComponent(cardId)}',
                          ),
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(
                      child: Text(
                        'Could not load lessons.',
                        style: SettleTypography.body.copyWith(
                          color: SettleColors.nightSoft,
                        ),
                      ),
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

class _LessonCard extends StatelessWidget {
  const _LessonCard({required this.lesson, required this.onCardTap});

  final TantrumLesson lesson;
  final ValueChanged<String> onCardTap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(lesson.title, style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(
            lesson.body,
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
          if (lesson.cardIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Related cards',
              style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8).copyWith(color: SettleColors.nightMuted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: lesson.cardIds.map((cardId) {
                return _CardChip(
                  cardId: cardId,
                  onTap: () => onCardTap(cardId),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _CardChip extends ConsumerWidget {
  const _CardChip({required this.cardId, required this.onTap});

  final String cardId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cardAsync = ref.watch(tantrumCardByIdProvider(cardId));
    final title = cardAsync.when(
      data: (c) => c?.title ?? cardId,
      loading: () => '…',
      error: (_, __) => cardId,
    );
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: SettleColors.nightAccent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(SettleRadii.pill),
          border: Border.all(color: SettleColors.nightAccent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400).copyWith(
                color: SettleColors.nightAccent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 14, color: SettleColors.nightAccent),
          ],
        ),
      ),
    );
  }
}
