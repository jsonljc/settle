import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/reduce_motion.dart';
import '../../theme/settle_design_system.dart';

class _SaT {
  _SaT._();

  static final type = _SaTypeTokens();
  static const pal = _SaPaletteTokens();
  static const glass = _SaGlassTokens();
  static const radius = _SaRadiusTokens();
  static const anim = _SaAnimTokens();
}

class _SaTypeTokens {
  TextStyle get h1 => SettleTypography.display.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    height: 1.2,
  );
  TextStyle get h3 => SettleTypography.heading.copyWith(fontSize: 17);
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption.copyWith(fontSize: 13);
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class _SaPaletteTokens {
  const _SaPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textPrimary => SettleColors.nightText;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

class _SaGlassTokens {
  const _SaGlassTokens();

  Color get fill => SettleGlassDark.backgroundStrong;
  Color get fillAccent => SettleColors.dusk600.withValues(alpha: 0.16);
  Color get border => SettleGlassDark.borderStrong;
  double get sigma => 12;
}

class _SaRadiusTokens {
  const _SaRadiusTokens();

  double get xl => 26;
}

class _SaAnimTokens {
  const _SaAnimTokens();

  Duration get normal => const Duration(milliseconds: 250);
}

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
          style: _SaT.type.h1,
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 8),
        Text(
          'These are not points on a spectrum.\nEach is a valid, researched method.',
          style: _SaT.type.caption.copyWith(color: _SaT.pal.textSecondary),
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
    final fill = isSelected ? _SaT.glass.fillAccent : _SaT.glass.fill;
    final borderColor = isSelected
        ? _SaT.pal.accent.withValues(alpha: 0.4)
        : _SaT.glass.border;

    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(_SaT.radius.xl),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: _SaT.glass.sigma,
            sigmaY: _SaT.glass.sigma,
          ),
          child: AnimatedContainer(
            duration: _SaT.anim.normal,
            curve: Curves.easeInOut,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(_SaT.radius.xl),
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
                      color: isSelected
                          ? _SaT.pal.accent
                          : _SaT.pal.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        approach.label,
                        style: _SaT.type.h3.copyWith(
                          color: isSelected
                              ? _SaT.pal.textPrimary
                              : _SaT.pal.textSecondary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        size: 20,
                        color: _SaT.pal.accent,
                      ),
                  ],
                ),
                // Short description
                const SizedBox(height: 6),
                Text(
                  approach.description,
                  style: _SaT.type.caption.copyWith(
                    color: _SaT.pal.textTertiary,
                  ),
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
                          style: _SaT.type.overline.copyWith(
                            color: _SaT.pal.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          howItWorks,
                          style: _SaT.type.body.copyWith(
                            color: _SaT.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'RESEARCH',
                          style: _SaT.type.overline.copyWith(
                            color: _SaT.pal.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          research,
                          style: _SaT.type.caption.copyWith(
                            color: _SaT.pal.textTertiary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: _SaT.anim.normal,
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
