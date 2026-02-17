import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/tantrum_profile.dart';
import '../providers/profile_provider.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/screen_header.dart';

/// Learn Screen — Q&A format. Questions parents actually ask.
/// Written in first-person parent voice.
/// Answers are nuanced, not dogmatic. Every answer cites a specific paper.
/// This is the ONLY place evidence is presented didactically.
class LearnScreen extends ConsumerWidget {
  const LearnScreen({super.key});

  static const _sleepQuestions = [
    _QA(
      question: 'Why does how they fall asleep matter?',
      answer:
          'Babies who fall asleep independently are more likely to resettle '
          'during normal overnight arousals without signaling. This doesn\u2019t '
          'mean helping them is a problem — it means that when they can do it, '
          'night wakes often resolve on their own.\n\n'
          'But this isn\u2019t universal. Some babies need more support for longer, '
          'and that\u2019s developmentally normal.',
      citation: 'Sadeh et al., 2010 — Sleep associations and night waking',
    ),
    _QA(
      question: 'Is "drowsy but awake" always right?',
      answer:
          'Not always. "Drowsy but awake" works well for some babies after '
          '4 months, but many younger babies need to be fully asleep before '
          'transfer. For some temperaments, the drowsy state is actually more '
          'alerting.\n\n'
          'If it\u2019s not working after consistent attempts, try putting baby '
          'down more awake or more asleep — the middle ground isn\u2019t magic.',
      citation: 'Mindell et al., 2015 — Bedtime routines meta-analysis',
    ),
    _QA(
      question: 'Can responding to crying cause bad habits?',
      answer:
          'No. Responding to your baby\u2019s cries does not create "bad habits." '
          'Responsive parenting builds secure attachment, and securely attached '
          'babies actually become more independent over time.\n\n'
          'What matters is the overall pattern of responsiveness, not any '
          'single moment. A brief delay in response during settling is not '
          'the same as ignoring your baby.',
      citation: 'Bilgin & Wolke, 2020 — Responsive parenting and infant crying',
    ),
    _QA(
      question: 'Do sleep regressions mean we\'re going backwards?',
      answer:
          'No. "Regressions" are actually developmental progressions. When '
          'babies learn to roll, crawl, or talk, their brains are too busy '
          'to sleep well temporarily.\n\n'
          'The 4-month regression is actually a permanent maturation of sleep '
          'architecture — your baby is developing adult-like sleep cycles. '
          'This is progress, even when it feels very hard.',
      citation: 'Henderson et al., 2010 — Normal sleep development patterns',
    ),
    _QA(
      question: 'Is it okay if our approach isn\'t working perfectly?',
      answer:
          'Yes. There is no approach that works perfectly for every baby. '
          'The research shows that consistent application of any evidence-based '
          'method produces improvement over 2–4 weeks.\n\n'
          'If you\u2019ve been consistent for 2 weeks with no improvement, it\u2019s '
          'reasonable to adjust your approach. This is adjustment, not failure.',
      citation:
          'Mindell et al., 2006 — Meta-analysis of 52 intervention studies',
    ),
    _QA(
      question: 'Will my baby be harmed by crying during settling?',
      answer:
          'The evidence says no. Multiple longitudinal studies have followed '
          'children for up to 5 years after behavioural sleep interventions '
          'and found no differences in cortisol levels, emotional health, '
          'attachment security, or parent-child relationship quality.\n\n'
          'That said, if listening to crying is harmful to you, that matters '
          'too. Choose an approach you can sustain.',
      citation:
          'Price et al., 2012 — Five-year follow-up RCT; '
          'Gradisar et al., 2016 — Graduated extinction outcomes',
    ),
  ];

  static const _tantrumQuestions = [
    _QA(
      question: 'Why can\'t my child just stop once they start?',
      answer:
          'During a meltdown, the emotional system is online before executive '
          'control can catch up. Young children do not yet have mature '
          'inhibitory control, especially under stress.\n\n'
          'This is why coaching and co-regulation come before reasoning.',
      citation: 'Blair & Raver, 2015 — Executive function development',
    ),
    _QA(
      question: 'Am I making it worse by comforting them?',
      answer:
          'Comforting does not cause tantrums. Co-regulation is how children '
          'learn to self-regulate over time. The goal is calm containment, not '
          'immediate silence.\n\n'
          'You are teaching the nervous system what safety feels like.',
      citation: 'Tronick, 1989; Schore, 2001 — Co-regulation foundations',
    ),
    _QA(
      question: 'Should I ignore tantrums?',
      answer:
          'Sometimes selective ignoring helps attention-seeking behaviors. '
          'It is less appropriate during genuine overwhelm, fear, or sensory '
          'distress.\n\n'
          'Use this rule: ignore performance behavior, support distress.',
      citation: 'Brestan & Eyberg, 1998 — Behavioral parent training evidence',
    ),
    _QA(
      question: 'Does giving in once teach more tantrums?',
      answer:
          'Occasionally giving in does not define your child\'s long-term '
          'pattern. Intermittent reinforcement can strengthen behavior if it '
          'becomes frequent, but one event is not destiny.\n\n'
          'Consistency over weeks matters more than any single hard moment.',
      citation: 'Behavioral reinforcement literature (applied parent training)',
    ),
    _QA(
      question: 'When should I worry and call the pediatrician?',
      answer:
          'Consider a clinical check-in when tantrums are very frequent for '
          'age, exceed 25 minutes repeatedly, involve self-injury, or show a '
          'sudden sharp change from baseline.\n\n'
          'Bring your logs: frequency, duration, triggers, and cross-setting patterns.',
      citation:
          'Wakschlag et al., 2012 — Clinical thresholds for dysregulation',
    ),
    _QA(
      question: 'Why are they fine at school but meltdown at home?',
      answer:
          'This is common. Many children hold it together in structured settings '
          'and release emotion in the safest relationship later.\n\n'
          'It is not proof of bad parenting. It often reflects safety and fatigue.',
      citation: 'Emotion regulation and safe-base literature',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    final useTantrum =
        profile != null &&
        profile.focusMode != FocusMode.sleepOnly &&
        profile.ageBracket.supportsTantrumFeatures;
    final questions = useTantrum ? _tantrumQuestions : _sleepQuestions;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: T.space.screen),
                child: ScreenHeader(
                  title: 'Learn',
                  subtitle: useTantrum
                      ? 'Tantrum questions parents actually ask'
                      : 'Sleep questions parents actually ask',
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: T.space.screen,
                  ).copyWith(bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: questions.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    if (i < questions.length) {
                      return _QuestionCard(qa: questions[i]);
                    }
                    return const _LearnNextActionsCard();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnNextActionsCard extends StatelessWidget {
  const _LearnNextActionsCard();

  @override
  Widget build(BuildContext context) {
    const planRoute = '/plan';
    const logsRoute = '/library/logs';
    return GlassCardAccent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next step', style: T.type.h3.copyWith(color: T.pal.accent)),
          const SizedBox(height: 8),
          Text(
            'Apply one change now, then check logs for proof.',
            style: T.type.caption.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassPill(
                label: 'Open Plan Focus',
                onTap: () => context.push(planRoute),
              ),
              GlassPill(
                label: 'Open Logs',
                onTap: () => context.push(logsRoute),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QA {
  const _QA({
    required this.question,
    required this.answer,
    required this.citation,
  });
  final String question;
  final String answer;
  final String citation;
}

class _QuestionCard extends StatefulWidget {
  const _QuestionCard({required this.qa});
  final _QA qa;

  @override
  State<_QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<_QuestionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    widget.qa.question,
                    style: T.type.label.copyWith(height: 1.35),
                  ),
                ),
                const SizedBox(width: 12),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: T.anim.fast,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 22,
                    color: T.pal.textTertiary,
                  ),
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.qa.answer,
                      style: T.type.body.copyWith(color: T.pal.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: T.glass.fillAccent,
                        borderRadius: BorderRadius.circular(T.radius.sm),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.menu_book_rounded,
                            size: 14,
                            color: T.pal.accent,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.qa.citation,
                              style: T.type.caption.copyWith(
                                color: T.pal.accent,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: T.anim.normal,
              sizeCurve: Curves.easeInOut,
            ),
          ],
        ),
      ),
    );
  }
}
