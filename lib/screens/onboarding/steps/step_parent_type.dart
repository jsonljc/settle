import 'package:flutter/material.dart';

import '../../../models/approach.dart';
import '../../../theme/settle_design_system.dart';
import '../../../widgets/option_button.dart';

class _SptT {
  _SptT._();

  static final type = _SptTypeTokens();
  static const pal = _SptPaletteTokens();
}

class _SptTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _SptPaletteTokens {
  const _SptPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
}

class StepParentType extends StatelessWidget {
  const StepParentType({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final FamilyStructure? selected;
  final ValueChanged<FamilyStructure> onSelect;

  static const _options = [
    _ParentTypeOption(
      structure: FamilyStructure.twoParents,
      label: 'Together',
      subtitle: 'Two caregivers in one home',
      icon: Icons.people_outline,
    ),
    _ParentTypeOption(
      structure: FamilyStructure.coParent,
      label: 'Co-parenting',
      subtitle: 'Across homes or schedules',
      icon: Icons.people_alt_outlined,
    ),
    _ParentTypeOption(
      structure: FamilyStructure.singleParent,
      label: 'Single parent',
      subtitle: 'You are the primary caregiver',
      icon: Icons.person_outline,
    ),
    _ParentTypeOption(
      structure: FamilyStructure.blended,
      label: 'Blended family',
      subtitle: 'Step or blended household',
      icon: Icons.family_restroom_outlined,
    ),
    _ParentTypeOption(
      structure: FamilyStructure.withSupport,
      label: 'With support',
      subtitle: 'Grandparents, nanny, or relatives',
      icon: Icons.group_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is parenting day to day?', style: _SptT.type.h1),
        const SizedBox(height: 10),
        Text(
          'This sets family and invite surfaces in the app.',
          style: _SptT.type.caption.copyWith(color: _SptT.pal.textSecondary),
        ),
        const SizedBox(height: 20),
        ..._options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: option.label,
              subtitle: option.subtitle,
              icon: option.icon,
              selected: selected == option.structure,
              onTap: () => onSelect(option.structure),
            ),
          );
        }),
      ],
    );
  }
}

class _ParentTypeOption {
  const _ParentTypeOption({
    required this.structure,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final FamilyStructure structure;
  final String label;
  final String subtitle;
  final IconData icon;
}
