import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';

class _DbsT {
  _DbsT._();

  static final type = _DbsTypeTokens();
  static const pal = _DbsPaletteTokens();
  static const glass = _DbsGlassTokens();
}

class _DbsTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _DbsPaletteTokens {
  const _DbsPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textPrimary => SettleColors.nightText;
  Color get textSecondary => SettleColors.nightSoft;
}

class _DbsGlassTokens {
  const _DbsGlassTokens();

  Color get fillAccent => SettleColors.nightAccent.withValues(alpha: 0.10);
}

class DebriefSection extends StatelessWidget {
  const DebriefSection({
    super.key,
    required this.selectedTrigger,
    required this.onTriggerTap,
    this.triggers = const [
      'transitions',
      'bedtime_battles',
      'public_meltdowns',
      'no_to_everything',
      'sibling_conflict',
      'overwhelmed',
    ],
  });

  final String? selectedTrigger;
  final List<String> triggers;
  final ValueChanged<String> onTriggerTap;

  static const _labels = {
    'transitions': 'Transitions',
    'bedtime_battles': 'Bedtime battles',
    'public_meltdowns': 'Public meltdowns',
    'no_to_everything': '"No" to everything',
    'sibling_conflict': 'Sibling conflict',
    'overwhelmed': "I'm overwhelmed",
  };

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What\'s been hardest?', style: _DbsT.type.h3),
          const SizedBox(height: 6),
          Text(
            'Tap one for a script.',
            style: _DbsT.type.caption.copyWith(color: _DbsT.pal.textSecondary),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: triggers.map((trigger) {
              final selected = selectedTrigger == trigger;
              return GlassPill(
                label: _labels[trigger] ?? trigger,
                fill: selected ? _DbsT.glass.fillAccent : null,
                textColor: selected ? _DbsT.pal.accent : _DbsT.pal.textPrimary,
                onTap: () => onTriggerTap(trigger),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
