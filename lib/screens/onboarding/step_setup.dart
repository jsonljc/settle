import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/reduce_motion.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/option_button.dart';

/// Step 2: Your setup. Two mini-sections on one screen:
///   - Family structure (2×2 compact grid)
///   - Sleep philosophy (4 vertical options with honest sublabels)
class StepSetup extends StatelessWidget {
  const StepSetup({
    super.key,
    required this.family,
    required this.onFamilySelect,
    required this.approach,
    required this.onApproachSelect,
    this.showFamily = true,
  });

  final FamilyStructure? family;
  final ValueChanged<FamilyStructure> onFamilySelect;
  final Approach? approach;
  final ValueChanged<Approach> onApproachSelect;
  final bool showFamily;

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
        const SizedBox(height: 24),

        if (showFamily) ...[
          // — Family structure section —
          Text(
            'Family',
            style: T.type.overline.copyWith(color: T.pal.textTertiary),
          ).entryFadeOnly(context, delay: 100.ms),
          const SizedBox(height: 12),
          _buildFamilyGrid(context),
          const SizedBox(height: 28),
        ],

        // — Sleep philosophy section —
        Text(
          'Sleep philosophy',
          style: T.type.overline.copyWith(color: T.pal.textTertiary),
        ).entryFadeOnly(context, delay: 200.ms),
        const SizedBox(height: 12),
        ..._buildPhilosophyList(context),
      ],
    );
  }

  Widget _buildFamilyGrid(BuildContext context) {
    final items = FamilyStructure.values;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final fs = entry.value;
        return OptionButtonCompact(
              label: fs.label,
              icon: _familyIcons[fs],
              selected: family == fs,
              onTap: () => onFamilySelect(fs),
            )
            .entryScaleIn(context, delay: Duration(milliseconds: 120 + 60 * i));
      }).toList(),
    );
  }

  List<Widget> _buildPhilosophyList(BuildContext context) {
    return Approach.values.asMap().entries.map((entry) {
      final i = entry.key;
      final a = entry.value;
      return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: a.label,
              subtitle: a.description,
              selected: approach == a,
              onTap: () => onApproachSelect(a),
            ),
          )
          .entrySlideIn(context, delay: Duration(milliseconds: 250 + 80 * i));
    }).toList();
  }
}
