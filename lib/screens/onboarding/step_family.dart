import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/reduce_motion.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/option_button.dart';

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
    FamilyStructure.singleParent: Icons.person_outline,
    FamilyStructure.withSupport: Icons.group_outlined,
    FamilyStructure.other: Icons.more_horiz,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your setup', style: T.type.h1)
            .entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 10),
        Text(
          'Who is typically in the daily caregiving loop?',
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
        ).entryFadeOnly(context, delay: 120.ms),
        const SizedBox(height: 22),
        Text(
          'Family structure',
          style: T.type.overline.copyWith(color: T.pal.textTertiary),
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
                )
                .entryScaleIn(context, delay: Duration(milliseconds: 220 + 60 * i), duration: 260.ms);
          }).toList(),
        ),
      ],
    );
  }
}
