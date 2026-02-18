import 'package:flutter/material.dart';

import '../../../theme/settle_design_system.dart';

class _ScnT {
  _ScnT._();

  static final type = _ScnTypeTokens();
  static const pal = _ScnPaletteTokens();
}

class _ScnTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class _ScnPaletteTokens {
  const _ScnPaletteTokens();

  Color get textPrimary => SettleColors.nightText;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
  Color get accent => SettleColors.nightAccent;
}

class StepChildNameAge extends StatelessWidget {
  const StepChildNameAge({
    super.key,
    required this.nameController,
    required this.ageMonths,
    required this.onAgeMonthsChanged,
  });

  final TextEditingController nameController;
  final int ageMonths;
  final ValueChanged<int> onAgeMonthsChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tell us about your child', style: _ScnT.type.h1),
        const SizedBox(height: 10),
        Text(
          'Name is optional. We\'ll personalize scripts either way.',
          style: _ScnT.type.caption.copyWith(color: _ScnT.pal.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          style: _ScnT.type.h3.copyWith(color: _ScnT.pal.textPrimary),
          cursorColor: _ScnT.pal.accent,
          decoration: InputDecoration(
            hintText: 'Child name (optional)',
            hintStyle: _ScnT.type.h3.copyWith(color: _ScnT.pal.textTertiary),
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _ScnT.pal.textTertiary.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _ScnT.pal.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Age',
          style: _ScnT.type.overline.copyWith(color: _ScnT.pal.textTertiary),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _ageLabel(ageMonths),
              style: _ScnT.type.h3.copyWith(color: _ScnT.pal.textPrimary),
            ),
            const Spacer(),
            Text(
              '$ageMonths months',
              style: _ScnT.type.caption.copyWith(
                color: _ScnT.pal.textSecondary,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: _ScnT.pal.accent,
            inactiveTrackColor: _ScnT.pal.textTertiary.withValues(alpha: 0.25),
            thumbColor: _ScnT.pal.accent,
            overlayColor: _ScnT.pal.accent.withValues(alpha: 0.16),
            trackHeight: 4,
          ),
          child: Slider(
            min: 12,
            max: 60,
            divisions: 48,
            value: ageMonths.toDouble(),
            label: _ageLabel(ageMonths),
            onChanged: (value) => onAgeMonthsChanged(value.round()),
          ),
        ),
      ],
    );
  }

  String _ageLabel(int months) {
    final years = months ~/ 12;
    final remMonths = months % 12;
    if (remMonths == 0) {
      return years == 1 ? '1 year' : '$years years';
    }
    final yearLabel = years == 1 ? '1 year' : '$years years';
    final monthLabel = remMonths == 1 ? '1 month' : '$remMonths months';
    return '$yearLabel $monthLabel';
  }
}
