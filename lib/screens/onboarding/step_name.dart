import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../theme/reduce_motion.dart';
import '../../theme/settle_design_system.dart';

class _SnT {
  _SnT._();

  static final type = _SnTypeTokens();
  static const pal = _SnPaletteTokens();
}

class _SnTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get h2 => SettleTypography.heading.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
}

class _SnPaletteTokens {
  const _SnPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textPrimary => SettleColors.nightText;
  Color get textTertiary => SettleColors.nightMuted;
}

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
          style: _SnT.type.h1,
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 32),
        TextField(
          controller: controller,
          autofocus: true,
          style: _SnT.type.h2.copyWith(color: _SnT.pal.textPrimary),
          cursorColor: _SnT.pal.accent,
          decoration: InputDecoration(
            hintText: 'Baby\'s name',
            hintStyle: _SnT.type.h2.copyWith(color: _SnT.pal.textTertiary),
            border: InputBorder.none,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: _SnT.pal.textTertiary.withValues(alpha: 0.3),
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: _SnT.pal.accent, width: 2),
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
