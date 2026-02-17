import 'package:flutter/material.dart';

import '../../../models/approach.dart';
import '../../../theme/glass_components.dart';
import '../../../theme/settle_tokens.dart';

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
        Text(heading, style: T.type.h1),
        const SizedBox(height: 10),
        Text(
          'Family tab lets everyone use the same script language. '
          'Invite links come in the Family phase.',
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
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
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
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
        color: T.glass.fillAccent,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: T.glass.border),
      ),
      alignment: Alignment.center,
      child: Text(initials, style: T.type.label.copyWith(color: T.pal.accent)),
    );
  }
}
