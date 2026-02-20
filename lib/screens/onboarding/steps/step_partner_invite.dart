import 'package:flutter/material.dart';

import '../../../models/approach.dart';
import '../../../widgets/glass_card.dart';
import '../../../theme/settle_design_system.dart';

class StepPartnerInvite extends StatelessWidget {
  const StepPartnerInvite({super.key, required this.familyStructure});

  final FamilyStructure familyStructure;

  @override
  Widget build(BuildContext context) {
    final heading = switch (familyStructure) {
      FamilyStructure.twoParents => 'Invite your partner',
      FamilyStructure.coParent => 'Invite your co-parent',
      FamilyStructure.withSupport => 'Invite your support person',
      _ => 'Invite caregivers',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(heading, style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'Family tab lets everyone use the same script language. '
          'Invite links come in the Family phase.',
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
        ),
        const SizedBox(height: 18),
        GlassCard(
          child: Row(
            children: [
              _AvatarStub(initials: 'Y'),
              const SizedBox(width: 10),
              _AvatarStub(initials: '+'),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Shared playbook and activity feed preview',
                  style: SettleTypography.body.copyWith(
                    color: SettleColors.nightSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AvatarStub extends StatelessWidget {
  const _AvatarStub({required this.initials});

  final String initials;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: SettleColors.nightAccent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: SettleSurfaces.cardBorderDark),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.nightAccent),
      ),
    );
  }
}
