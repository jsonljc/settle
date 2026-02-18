import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/tantrum_profile.dart';
import '../../theme/reduce_motion.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/option_button.dart';

class _RasT {
  _RasT._();

  static final type = _RasTypeTokens();
  static const pal = _RasPaletteTokens();
}

class _RasTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _RasPaletteTokens {
  const _RasPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
}

class ResponseApproachStep extends StatelessWidget {
  const ResponseApproachStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final ResponsePriority? selected;
  final ValueChanged<ResponsePriority> onSelect;

  static const _copy = {
    ResponsePriority.coRegulation:
        'I want to stay calm and present, even when it is hard.',
    ResponsePriority.structure:
        'I want clear boundaries without losing my temper.',
    ResponsePriority.insight: 'I want to understand why this happens.',
    ResponsePriority.scripts:
        'I just want direct scripts to survive the moment.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Response focus',
          style: _RasT.type.h1,
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 8),
        Text(
          'Pick your priority for guidance weighting.',
          style: _RasT.type.caption.copyWith(color: _RasT.pal.textSecondary),
        ).entryFadeOnly(context, delay: 120.ms),
        const SizedBox(height: 24),
        ...ResponsePriority.values.asMap().entries.map((entry) {
          final i = entry.key;
          final option = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: option.label,
              subtitle: _copy[option],
              selected: selected == option,
              onTap: () => onSelect(option),
            ),
          ).entrySlideIn(context, delay: Duration(milliseconds: 160 + 80 * i));
        }),
      ],
    );
  }
}
