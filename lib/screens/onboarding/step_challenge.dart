import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../models/approach.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/settle_disclosure.dart';
import '../../widgets/option_button.dart';

/// Step 3: What is hardest + feeding type.
/// Primary required decision: biggest challenge.
/// Feeding context is optional.
class StepChallenge extends StatelessWidget {
  const StepChallenge({
    super.key,
    required this.challenge,
    required this.onChallengeSelect,
    required this.feeding,
    required this.onFeedingSelect,
  });

  final PrimaryChallenge? challenge;
  final ValueChanged<PrimaryChallenge> onChallengeSelect;
  final FeedingType? feeding;
  final ValueChanged<FeedingType> onFeedingSelect;

  static const _challengeIcons = {
    PrimaryChallenge.fallingAsleep: Icons.bedtime_outlined,
    PrimaryChallenge.nightWaking: Icons.nights_stay_outlined,
    PrimaryChallenge.shortNaps: Icons.timelapse_outlined,
    PrimaryChallenge.schedule: Icons.schedule_outlined,
  };

  static const _feedingIcons = {
    FeedingType.breast: Icons.child_care_outlined,
    FeedingType.formula: Icons.local_drink_outlined,
    FeedingType.combo: Icons.sync_alt_outlined,
    FeedingType.solids: Icons.restaurant_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is\nhardest?',
          style: SettleTypography.heading.copyWith(fontSize: 26, fontWeight: FontWeight.w700),
        ).entryFadeIn(context, duration: 400.ms, moveY: 10),
        const SizedBox(height: 24),

        // — Primary challenge —
        Text(
          'Biggest challenge',
          style: SettleTypography.caption.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8, color: SettleColors.nightMuted),
        ).entryFadeOnly(context, delay: 100.ms),
        const SizedBox(height: 12),
        ...PrimaryChallenge.values.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OptionButton(
              label: c.label,
              icon: _challengeIcons[c],
              selected: challenge == c,
              onTap: () => onChallengeSelect(c),
            ),
          ).entrySlideIn(context, delay: Duration(milliseconds: 120 + 60 * i));
        }),
        const SizedBox(height: 20),
        SettleDisclosure(
          title: 'Feeding context (optional)',
          titleStyle: SettleTypography.body.copyWith(fontWeight: FontWeight.w600, color: SettleColors.nightSoft),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Add this only if it helps personalize your plan.',
                style: SettleTypography.caption.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: SettleColors.nightSoft,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildFeedingGrid(context),
            const SizedBox(height: 6),
          ],
        ),
      ],
    );
  }

  Widget _buildFeedingGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: 2.6,
      children: FeedingType.values.asMap().entries.map((entry) {
        final i = entry.key;
        final ft = entry.value;
        return OptionButtonCompact(
          label: ft.label,
          icon: _feedingIcons[ft],
          selected: feeding == ft,
          onTap: () => onFeedingSelect(ft),
        ).entryScaleIn(context, delay: Duration(milliseconds: 400 + 60 * i));
      }).toList(),
    );
  }
}
