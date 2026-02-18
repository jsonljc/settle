import 'package:flutter/material.dart';

import '../../../models/approach.dart';
import '../../../theme/glass_components.dart';
import '../../../theme/settle_design_system.dart';

class _SpiT {
  _SpiT._();

  static final type = _SpiTypeTokens();
  static const pal = _SpiPaletteTokens();
  static const glass = _SpiGlassTokens();
}

class _SpiTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _SpiPaletteTokens {
  const _SpiPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textSecondary => SettleColors.nightSoft;
}

class _SpiGlassTokens {
  const _SpiGlassTokens();

  Color get fillAccent => SettleColors.nightAccent.withValues(alpha: 0.10);
  Color get border => SettleGlassDark.borderStrong;
}

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
        Text(heading, style: _SpiT.type.h1),
        const SizedBox(height: 10),
        Text(
          'Family tab lets everyone use the same script language. '
          'Invite links come in the Family phase.',
          style: _SpiT.type.caption.copyWith(color: _SpiT.pal.textSecondary),
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
                  style: _SpiT.type.body.copyWith(
                    color: _SpiT.pal.textSecondary,
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
        color: _SpiT.glass.fillAccent,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _SpiT.glass.border),
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: _SpiT.type.label.copyWith(color: _SpiT.pal.accent),
      ),
    );
  }
}
