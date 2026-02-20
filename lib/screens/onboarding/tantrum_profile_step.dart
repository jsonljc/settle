import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/tantrum_profile.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/option_button.dart';

class TantrumProfileStep extends StatelessWidget {
  const TantrumProfileStep({
    super.key,
    required this.tantrumType,
    required this.onTantrumTypeSelect,
    required this.triggers,
    required this.onTriggersChanged,
    required this.parentPattern,
    required this.onParentPatternSelect,
  });

  final TantrumType? tantrumType;
  final ValueChanged<TantrumType> onTantrumTypeSelect;
  final Set<TriggerType> triggers;
  final ValueChanged<Set<TriggerType>> onTriggersChanged;
  final ParentPattern? parentPattern;
  final ValueChanged<ParentPattern> onParentPatternSelect;

  static const _tantrumTypeCopy = {
    TantrumType.explosive:
        'Sudden, high-intensity reactions such as yelling, hitting, or throwing.',
    TantrumType.shutdown: 'Crying, withdrawing, freezing, hiding, going limp.',
    TantrumType.escalating:
        'Starts with whining or negotiation, then builds into big overwhelm.',
    TantrumType.mixed: 'No consistent pattern or a mix of reactions.',
  };

  static const _triggerIcons = {
    TriggerType.transitions: Icons.sync_alt,
    TriggerType.frustration: Icons.sentiment_dissatisfied_outlined,
    TriggerType.sensory: Icons.graphic_eq,
    TriggerType.boundaries: Icons.block,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tantrum pattern',
          style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 8),
        Text(
          'Pick the pattern that feels most true right now.',
          style: SettleTypography.caption.copyWith(fontSize: 13, fontWeight: FontWeight.w400, color: SettleColors.nightSoft),
        ).entryFadeOnly(context, delay: 120.ms),
        const SizedBox(height: 22),
        Text(
          'What usually happens?',
          style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: SettleColors.nightMuted),
        ).entryFadeOnly(context, delay: 160.ms, duration: 250.ms),
        const SizedBox(height: 10),
        ...TantrumType.values.asMap().entries.map((entry) {
          final i = entry.key;
          final type = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: type.label,
              subtitle: _tantrumTypeCopy[type],
              selected: tantrumType == type,
              onTap: () => onTantrumTypeSelect(type),
            ),
          ).entrySlideIn(
            context,
            delay: Duration(milliseconds: 180 + 70 * i),
            duration: 280.ms,
            moveX: 14,
          );
        }),
        const SizedBox(height: 16),
        Text(
          'Common triggers (optional)',
          style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: SettleColors.nightMuted),
        ).entryFadeOnly(context, delay: 320.ms, duration: 250.ms),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children:
              [
                TriggerType.transitions,
                TriggerType.frustration,
                TriggerType.sensory,
                TriggerType.boundaries,
              ].asMap().entries.map((entry) {
                final i = entry.key;
                final trigger = entry.value;
                return OptionButtonCompact(
                  label: trigger.label,
                  icon: _triggerIcons[trigger],
                  selected: triggers.contains(trigger),
                  onTap: () {
                    final next = {...triggers};
                    if (next.contains(trigger)) {
                      next.remove(trigger);
                    } else {
                      next.add(trigger);
                    }
                    onTriggersChanged(next);
                  },
                ).entryScaleIn(
                  context,
                  delay: Duration(milliseconds: 340 + 60 * i),
                  duration: 250.ms,
                  scaleBegin: 0.96,
                );
              }).toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'When it happens, I usually... (optional)',
          style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: SettleColors.nightMuted),
        ).entryFadeOnly(context, delay: 460.ms, duration: 250.ms),
        const SizedBox(height: 10),
        ...ParentPattern.values.asMap().entries.map((entry) {
          final i = entry.key;
          final pattern = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: pattern.label,
              selected: parentPattern == pattern,
              onTap: () => onParentPatternSelect(pattern),
            ),
          ).entrySlideIn(
            context,
            delay: Duration(milliseconds: 480 + 65 * i),
            duration: 250.ms,
            moveX: 14,
          );
        }),
      ],
    );
  }
}
