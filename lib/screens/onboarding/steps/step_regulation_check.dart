import 'package:flutter/material.dart';

import '../../../models/approach.dart';
import '../../../theme/glass_components.dart';
import '../../../theme/settle_design_system.dart';
import '../../../widgets/option_button.dart';

class _SrcT {
  _SrcT._();

  static final type = _SrcTypeTokens();
  static const pal = _SrcPaletteTokens();
}

class _SrcTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _SrcPaletteTokens {
  const _SrcPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
}

class StepRegulationCheck extends StatelessWidget {
  const StepRegulationCheck({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final RegulationLevel? selected;
  final ValueChanged<RegulationLevel> onSelect;

  static const _options = [
    _RegulationOption(
      level: RegulationLevel.calm,
      label: 'Calm',
      subtitle: 'You feel steady and grounded',
      icon: Icons.wb_sunny_outlined,
    ),
    _RegulationOption(
      level: RegulationLevel.stressed,
      label: 'Stressed',
      subtitle: 'Tension is building',
      icon: Icons.speed_outlined,
    ),
    _RegulationOption(
      level: RegulationLevel.anxious,
      label: 'Anxious',
      subtitle: 'Worry is high in your body',
      icon: Icons.air_outlined,
    ),
    _RegulationOption(
      level: RegulationLevel.angry,
      label: 'Angry',
      subtitle: 'You are close to losing it',
      icon: Icons.local_fire_department_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final showRegulatePreview =
        selected != null && selected != RegulationLevel.calm;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How are you feeling right now?', style: _SrcT.type.h1),
        const SizedBox(height: 10),
        Text(
          'We use this to prioritize regulate support in Plan.',
          style: _SrcT.type.caption.copyWith(color: _SrcT.pal.textSecondary),
        ),
        const SizedBox(height: 20),
        ..._options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: option.label,
              subtitle: option.subtitle,
              icon: option.icon,
              selected: selected == option.level,
              onTap: () => onSelect(option.level),
            ),
          );
        }),
        if (showRegulatePreview) ...[
          const SizedBox(height: 8),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Regulate preview ready', style: _SrcT.type.h3),
                const SizedBox(height: 6),
                Text(
                  _previewForLevel(selected!),
                  style: _SrcT.type.body.copyWith(
                    color: _SrcT.pal.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _previewForLevel(RegulationLevel level) {
    return switch (level) {
      RegulationLevel.calm => 'Plan will prioritize scripts first.',
      RegulationLevel.stressed =>
        'Plan will prioritize a fast 30-second breathing reset first.',
      RegulationLevel.anxious =>
        'Plan will prioritize grounding and calm-body prompts first.',
      RegulationLevel.angry =>
        'Plan will prioritize repair-forward scripts and de-escalation first.',
    };
  }
}

class _RegulationOption {
  const _RegulationOption({
    required this.level,
    required this.label,
    required this.subtitle,
    required this.icon,
  });

  final RegulationLevel level;
  final String label;
  final String subtitle;
  final IconData icon;
}
