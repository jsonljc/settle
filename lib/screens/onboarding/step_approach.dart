import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/reduce_motion.dart';
import '../../theme/settle_tokens.dart';

/// Step 4: Approach selection. NOT a slider. Four discrete cards.
/// Tapping one expands it to show how it works + cited research.
/// This respects that approaches are qualitatively different.
class StepApproach extends StatefulWidget {
  const StepApproach({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final Approach? selected;
  final ValueChanged<Approach> onSelect;

  @override
  State<StepApproach> createState() => _StepApproachState();
}

class _StepApproachState extends State<StepApproach> {
  Approach? _expanded;

  static const _icons = {
    Approach.stayAndSupport: Icons.favorite_outline,
    Approach.checkAndReassure: Icons.timer_outlined,
    Approach.cueBased: Icons.hearing_outlined,
    Approach.rhythmFirst: Icons.music_note_outlined,
  };

  static const _howItWorks = {
    Approach.stayAndSupport:
        'You stay in the room while baby learns to settle. Gradually reduce '
        'your intervention over time — from patting to shushing to just '
        'being present.',
    Approach.checkAndReassure:
        'Place baby down, leave the room, and return at increasing intervals '
        '(e.g. 3, 5, 10 minutes) to briefly reassure. Consistency is key.',
    Approach.cueBased:
        'Distinguish between fussing (mild protest) and crying (distress). '
        'Respond to distress quickly, give fussing a moment to self-resolve.',
    Approach.rhythmFirst:
        'Optimize sleep environment, timing, and routine first. Darkness, '
        'white noise, consistent schedule. Many issues resolve with '
        'hygiene alone.',
  };

  static const _research = {
    Approach.stayAndSupport:
        'Mindell et al., 2006: Parental presence methods are effective with '
        'no evidence of harm in meta-analysis of 52 studies.',
    Approach.checkAndReassure:
        'Price et al., 2012: 5-year follow-up RCT found no difference in '
        'cortisol, attachment, or behavior with graduated methods.',
    Approach.cueBased:
        'Bilgin & Wolke, 2020: Responsive parenting supports secure '
        'attachment; brief crying during settling does not undermine this.',
    Approach.rhythmFirst:
        'Sadeh et al., 2009: Environmental and scheduling interventions '
        'without behavioral methods showed clinically significant '
        'improvement in 58% of cases.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose your\napproach',
          style: T.type.h1,
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 8),
        Text(
          'These are not points on a spectrum.\nEach is a valid, researched method.',
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
        ).entryFadeOnly(context, delay: 150.ms, duration: 400.ms),
        const SizedBox(height: 24),
        ...Approach.values.asMap().entries.map((entry) {
          final i = entry.key;
          final a = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ApproachCard(
              approach: a,
              icon: _icons[a]!,
              howItWorks: _howItWorks[a]!,
              research: _research[a]!,
              isSelected: widget.selected == a,
              isExpanded: _expanded == a,
              onTap: () {
                setState(() {
                  if (_expanded == a) {
                    // Second tap on expanded card → select it
                    widget.onSelect(a);
                  } else {
                    _expanded = a;
                    widget.onSelect(a);
                  }
                });
              },
            ),
          ).entrySlideIn(
            context,
            delay: Duration(milliseconds: 100 + 80 * i),
            moveX: 20,
          );
        }),
      ],
    );
  }
}

class _ApproachCard extends StatelessWidget {
  const _ApproachCard({
    required this.approach,
    required this.icon,
    required this.howItWorks,
    required this.research,
    required this.isSelected,
    required this.isExpanded,
    required this.onTap,
  });

  final Approach approach;
  final IconData icon;
  final String howItWorks;
  final String research;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fill = isSelected ? T.glass.fillAccent : T.glass.fill;
    final borderColor = isSelected
        ? T.pal.accent.withValues(alpha: 0.4)
        : T.glass.border;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(T.radius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: T.glass.sigma,
            sigmaY: T.glass.sigma,
          ),
          child: AnimatedContainer(
            duration: T.anim.normal,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(T.radius.xl),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Icon(
                      icon,
                      size: 22,
                      color: isSelected ? T.pal.accent : T.pal.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        approach.label,
                        style: T.type.h3.copyWith(
                          color: isSelected
                              ? T.pal.textPrimary
                              : T.pal.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, size: 20, color: T.pal.accent),
                  ],
                ),
                // Short description
                const SizedBox(height: 6),
                Text(
                  approach.description,
                  style: T.type.caption.copyWith(color: T.pal.textTertiary),
                ),
                // Expanded detail
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOW IT WORKS',
                          style: T.type.overline.copyWith(
                            color: T.pal.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          howItWorks,
                          style: T.type.body.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'RESEARCH',
                          style: T.type.overline.copyWith(
                            color: T.pal.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          research,
                          style: T.type.caption.copyWith(
                            color: T.pal.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: T.anim.normal,
                  sizeCurve: Curves.easeInOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
