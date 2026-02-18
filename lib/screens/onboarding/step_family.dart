import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/reduce_motion.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/option_button.dart';

class _SfaT {
  _SfaT._();

  static final type = _SfaTypeTokens();
  static const pal = _SfaPaletteTokens();
}

class _SfaTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class _SfaPaletteTokens {
  const _SfaPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

class StepFamily extends StatelessWidget {
  const StepFamily({
    super.key,
    required this.family,
    required this.onFamilySelect,
  });

  final FamilyStructure? family;
  final ValueChanged<FamilyStructure> onFamilySelect;

  static const _familyIcons = {
    FamilyStructure.twoParents: Icons.people_outline,
    FamilyStructure.coParent: Icons.people_alt_outlined,
    FamilyStructure.singleParent: Icons.person_outline,
    FamilyStructure.blended: Icons.family_restroom_outlined,
    FamilyStructure.withSupport: Icons.group_outlined,
    FamilyStructure.other: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your setup',
          style: _SfaT.type.h1,
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 10),
        Text(
          'Who is typically in the daily caregiving loop?',
          style: _SfaT.type.caption.copyWith(color: _SfaT.pal.textSecondary),
        ).entryFadeOnly(context, delay: 120.ms),
        const SizedBox(height: 22),
        Text(
          'Family structure',
          style: _SfaT.type.overline.copyWith(color: _SfaT.pal.textTertiary),
        ).entryFadeOnly(context, delay: 180.ms, duration: 250.ms),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.6,
          children: FamilyStructure.values.asMap().entries.map((entry) {
            final i = entry.key;
            final fs = entry.value;
            return OptionButtonCompact(
              label: fs.label,
              icon: _familyIcons[fs],
              selected: family == fs,
              onTap: () => onFamilySelect(fs),
            ).entryScaleIn(
              context,
              delay: Duration(milliseconds: 220 + 60 * i),
              duration: 260.ms,
            );
          }).toList(),
        ),
      ],
    );
  }
}
