import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/settle_design_system.dart';

/// Step 0: Baby name. Single input. Clean.
class StepName extends StatelessWidget {
  const StepName({
    super.key,
    required this.controller,
    required this.onNext,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onNext;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your\nbaby\'s name?',
          style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          autofocus: true,
          style: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: SettleColors.nightText),
          cursorColor: SettleColors.nightAccent,
          decoration: InputDecoration(
            hintText: 'Baby\'s name',
            hintStyle: SettleTypography.heading.copyWith(fontSize: 22, fontWeight: FontWeight.w700, color: SettleColors.nightMuted),
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: SettleColors.nightMuted.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: SettleColors.nightAccent, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          textInputAction: TextInputAction.next,
          onChanged: onChanged,
          onSubmitted: (_) => onNext(),
        ).entryFadeOnly(context, delay: 200.ms, duration: 400.ms),
      ],
    );
  }
}
