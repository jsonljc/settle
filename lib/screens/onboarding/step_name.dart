import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/reduce_motion.dart';
import '../../theme/settle_tokens.dart';

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
        Text('What\'s your\nbaby\'s name?', style: T.type.h1)
            .entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          autofocus: true,
          style: T.type.h2.copyWith(color: T.pal.textPrimary),
          cursorColor: T.pal.accent,
          decoration: InputDecoration(
            hintText: 'Baby\'s name',
            hintStyle: T.type.h2.copyWith(color: T.pal.textTertiary),
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: T.pal.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: T.pal.accent, width: 2),
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
