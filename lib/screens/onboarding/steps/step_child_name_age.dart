import 'package:flutter/material.dart';

import '../../../theme/settle_tokens.dart';

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
        Text('Tell us about your child', style: T.type.h1),
        const SizedBox(height: 10),
        Text(
          'Name is optional. We\'ll personalize scripts either way.',
          style: T.type.caption.copyWith(color: T.pal.textSecondary),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: nameController,
          textInputAction: TextInputAction.next,
          style: T.type.h3.copyWith(color: T.pal.textPrimary),
          cursorColor: T.pal.accent,
          decoration: InputDecoration(
            hintText: 'Child name (optional)',
            hintStyle: T.type.h3.copyWith(color: T.pal.textTertiary),
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: T.pal.textTertiary.withValues(alpha: 0.35),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: T.pal.accent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
        const SizedBox(height: 28),
        Text('Age', style: T.type.overline.copyWith(color: T.pal.textTertiary)),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              _ageLabel(ageMonths),
              style: T.type.h3.copyWith(color: T.pal.textPrimary),
            ),
            const Spacer(),
            Text(
              '$ageMonths months',
              style: T.type.caption.copyWith(color: T.pal.textSecondary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: T.pal.accent,
            inactiveTrackColor: T.pal.textTertiary.withValues(alpha: 0.25),
            thumbColor: T.pal.accent,
            overlayColor: T.pal.accent.withValues(alpha: 0.16),
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
