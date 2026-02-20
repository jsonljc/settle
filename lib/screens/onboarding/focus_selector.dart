import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/tantrum_profile.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/option_button.dart';

class FocusSelectorStep extends StatelessWidget {
  const FocusSelectorStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final FocusMode? selected;
  final ValueChanged<FocusMode> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What do you want\nhelp with?',
          style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 8),
        Text(
          'Pick a starting point. You can change this anytime.',
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
        ).entryFadeOnly(context, delay: 120.ms),
        const SizedBox(height: 24),
        ...FocusMode.values.asMap().entries.map((entry) {
          final i = entry.key;
          final mode = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: mode.label,
              subtitle: _subtitle(mode),
              selected: selected == mode,
              onTap: () => onSelect(mode),
            ),
          ).entrySlideIn(context, delay: Duration(milliseconds: 160 + 80 * i));
        }),
      ],
    );
  }

  String _subtitle(FocusMode mode) => switch (mode) {
    FocusMode.sleepOnly => 'Use sleep guidance only',
    FocusMode.tantrumOnly => 'Use tantrum support only',
    FocusMode.both => 'Use sleep + tantrum support together',
  };
}
