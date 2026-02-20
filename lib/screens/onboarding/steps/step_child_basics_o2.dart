import 'package:flutter/material.dart';

import '../../../theme/settle_design_system.dart';
import '../../../widgets/settle_chip.dart';
import '../../../widgets/settle_gap.dart';
import '../../../widgets/settle_tappable.dart';

/// O2 — Child basics (only screen with input fields). Wireframe: "Who's this for?",
/// "First name (optional)", age chips Under 1 / 1–2 / 2–3 / 3–5, "Enter exact birthday instead", "Next".
class StepChildBasicsO2 extends StatelessWidget {
  const StepChildBasicsO2({
    super.key,
    required this.nameController,
    required this.ageChipId,
    required this.onAgeChipChanged,
    this.onExactBirthdayTap,
  });

  final TextEditingController nameController;
  final String? ageChipId;
  final ValueChanged<String?> onAgeChipChanged;
  final VoidCallback? onExactBirthdayTap;

  static const chipIds = ['under_1', '1_2', '2_3', '3_5'];
  static const chipLabels = ['Under 1', '1–2', '2–3', '3–5'];

  /// Map chip id to approximate age in months (for profile).
  static int ageMonthsFromChip(String? id) {
    switch (id) {
      case 'under_1':
        return 6;
      case '1_2':
        return 18;
      case '2_3':
        return 30;
      case '3_5':
        return 48;
      default:
        return 18;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Who\'s this for?',
          style: SettleTypography.heading.copyWith(
            color: SettleSemanticColors.headline(context),
          ),
        ),
        const SettleGap.lg(),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.done,
          style: SettleTypography.body.copyWith(
            color: SettleSemanticColors.headline(context),
          ),
          decoration: InputDecoration(
            hintText: 'First name (optional)',
            hintStyle: SettleTypography.body.copyWith(
              color: SettleSemanticColors.muted(context),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(SettleRadii.sm),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SettleSpacing.md,
              vertical: SettleSpacing.lg,
            ),
          ),
        ),
        const SettleGap.xxl(),
        Text(
          'Age',
          style: SettleTypography.overline.copyWith(
            color: SettleSemanticColors.muted(context),
          ),
        ),
        const SettleGap.sm(),
        Wrap(
          spacing: SettleSpacing.sm,
          runSpacing: SettleSpacing.sm,
          children: List.generate(chipIds.length, (i) {
            final id = chipIds[i];
            final label = chipLabels[i];
            return SettleChip(
              variant: SettleChipVariant.action,
              label: label,
              selected: ageChipId == id,
              onTap: () => onAgeChipChanged(id),
            );
          }),
        ),
        if (onExactBirthdayTap != null) ...[
          const SettleGap.lg(),
          SettleTappable(
            semanticLabel: 'Enter exact birthday instead',
            onTap: onExactBirthdayTap,
            child: Text(
              'Enter exact birthday instead',
              style: SettleTypography.caption.copyWith(
                color: SettleSemanticColors.muted(context),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
