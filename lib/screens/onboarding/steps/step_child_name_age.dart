import 'package:flutter/material.dart';

import '../../../theme/settle_design_system.dart';

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
        Text('Tell us about your child', style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        Text(
          'Name is optional. We\'ll personalize scripts either way.',
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: SettleColors.nightText),
          cursorColor: SettleColors.nightAccent,
          decoration: InputDecoration(
            hintText: 'Child name (optional)',
            hintStyle: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: SettleColors.nightMuted),
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: SettleColors.nightMuted.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SettleColors.nightAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Age',
          style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: SettleColors.nightMuted),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _ageLabel(ageMonths),
              style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700, color: SettleColors.nightText),
            ),
            const Spacer(),
            Text(
              '$ageMonths months',
              style: SettleTypography.caption.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: SettleColors.nightSoft,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: SettleColors.nightAccent,
            inactiveTrackColor: SettleColors.nightMuted.withValues(alpha: 0.25),
            thumbColor: SettleColors.nightAccent,
            overlayColor: SettleColors.nightAccent.withValues(alpha: 0.16),
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
