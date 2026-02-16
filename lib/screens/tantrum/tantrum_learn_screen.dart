import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../tantrum/models/tantrum_lesson.dart';
import '../../tantrum/providers/tantrum_module_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/tantrum_sub_nav.dart';

/// LEARN: micro-lessons that link back to cards (by lessonId / cardIds).
class TantrumLearnScreen extends ConsumerWidget {
  const TantrumLearnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessonsAsync = ref.watch(tantrumLessonsProvider);

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
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
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
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
          Text(lesson.title, style: T.type.h3),
          const SizedBox(height: 10),
          Text(
            lesson.body,
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          if (lesson.cardIds.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Related cards',
              style: T.type.overline.copyWith(color: T.pal.textTertiary),
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
          color: T.glass.fillAccent,
          borderRadius: BorderRadius.circular(T.radius.pill),
          border: Border.all(color: T.pal.accent.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: T.type.caption.copyWith(
                color: T.pal.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_rounded, size: 14, color: T.pal.accent),
          ],
        ),
      ),
    );
  }
}
