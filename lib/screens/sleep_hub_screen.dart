import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../models/rhythm_models.dart';
import '../providers/profile_provider.dart';
import '../providers/rhythm_provider.dart';
import '../providers/sleep_tonight_provider.dart';
import '../services/spec_policy.dart';
import '../theme/glass_components.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';

class _ShT {
  _ShT._();

  static final type = _ShTypeTokens();
  static const pal = _ShPaletteTokens();
}

class _ShTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _ShPaletteTokens {
  const _ShPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

class SleepHubScreen extends ConsumerStatefulWidget {
  const SleepHubScreen({super.key});

  @override
  ConsumerState<SleepHubScreen> createState() => _SleepHubScreenState();
}

class _SleepHubScreenState extends ConsumerState<SleepHubScreen> {
  String? _loadedChildId;
  bool _loadScheduled = false;

  int _ageMonthsFor(AgeBracket age) {
    return switch (age) {
      AgeBracket.newborn => 1,
      AgeBracket.twoToThreeMonths => 2,
      AgeBracket.fourToFiveMonths => 5,
      AgeBracket.sixToEightMonths => 7,
      AgeBracket.nineToTwelveMonths => 10,
      AgeBracket.twelveToEighteenMonths => 15,
      AgeBracket.nineteenToTwentyFourMonths => 21,
      AgeBracket.twoToThreeYears => 30,
      AgeBracket.threeToFourYears => 35,
      AgeBracket.fourToFiveYears => 35,
      AgeBracket.fiveToSixYears => 35,
    };
  }

  String _formatClock(BuildContext context, int minutes) {
    final normalized = ((minutes % 1440) + 1440) % 1440;
    final tod = TimeOfDay(hour: normalized ~/ 60, minute: normalized % 60);
    return MaterialLocalizations.of(context).formatTimeOfDay(
      tod,
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
  }

  Future<void> _loadRhythmIfNeeded() async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    final childId = profile.createdAt;
    if (_loadedChildId == childId) return;
    _loadedChildId = childId;
    await ref
        .read(rhythmProvider.notifier)
        .load(childId: childId, ageMonths: _ageMonthsFor(profile.ageBracket));
    await ref
        .read(sleepTonightProvider.notifier)
        .syncMethodSelection(
          childId: childId,
          selectedApproachId: profile.approach.id,
        );
    await ref.read(sleepTonightProvider.notifier).loadTonightPlan(childId);
  }

  void _scheduleLoadIfNeeded() {
    if (_loadScheduled) return;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      _loadRhythmIfNeeded();
    });
  }

  String _rhythmSummary(BuildContext context, DaySchedule? schedule) {
    if (schedule == null || schedule.blocks.isEmpty) {
      return 'Wake, nap, and bedtime will appear here.';
    }
    final wake = schedule.blocks.firstWhere(
      (b) => b.id == 'wake',
      orElse: () => schedule.blocks.first,
    );
    RhythmScheduleBlock? nap;
    for (final block in schedule.blocks) {
      if (block.id.startsWith('nap')) {
        nap = block;
        break;
      }
    }
    final bed = schedule.blocks.firstWhere(
      (b) => b.id == 'bedtime',
      orElse: () => schedule.blocks.last,
    );
    final napText = nap == null
        ? 'Nap ~--'
        : 'Nap ~${_formatClock(context, nap.centerlineMinutes)}';
    return 'Wake ~${_formatClock(context, wake.centerlineMinutes)}'
        ' • $napText'
        ' • Bed ~${_formatClock(context, bed.centerlineMinutes)}';
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoadIfNeeded();

    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Sleep');
    }

    final rhythmState = ref.watch(rhythmProvider);
    final tonightState = ref.watch(sleepTonightProvider);
    final isNight = SpecPolicy.isNight(DateTime.now());
    final activeApproach = tonightState.selectedApproachId.isNotEmpty
        ? Approach.fromId(tonightState.selectedApproachId)
        : profile.approach;
    final commitmentNight = tonightState.commitmentNight;
    final commitmentTotal = tonightState.commitmentNightsDefault;

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Sleep',
                  subtitle: 'Predictable days. Recoverable nights.',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HubCard(
                          title: 'Current Rhythm',
                          subtitle: _rhythmSummary(
                            context,
                            rhythmState.todaySchedule,
                          ),
                          ctaLabel: 'View today',
                          onTap: () => context.push('/sleep/rhythm'),
                        ),
                        const SizedBox(height: 10),
                        _HubCard(
                          title: 'Tonight',
                          subtitle: isNight
                              ? 'Night mode'
                              : 'Prepare for bedtime',
                          ctaLabel: 'Start help now',
                          onTap: () => context.push('/sleep/tonight'),
                          footer:
                              '${activeApproach.label} • Night $commitmentNight/$commitmentTotal',
                        ),
                        const SizedBox(height: 10),
                        _HubCard(
                          title: 'Update Rhythm',
                          subtitle: 'Adjust wake/nap/bed in under a minute',
                          ctaLabel: 'Update',
                          onTap: () => context.push('/sleep/update'),
                        ),
                        const SizedBox(height: 14),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GlassPill(
                            label: 'History & logs',
                            onTap: () => context.push('/progress/logs'),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GlassPill(
                            label: 'Sleep setup',
                            onTap: () =>
                                context.push('/sleep/tonight?open_setup=1'),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HubCard extends StatelessWidget {
  const _HubCard({
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.onTap,
    this.footer,
  });

  final String title;
  final String subtitle;
  final String ctaLabel;
  final VoidCallback onTap;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: _ShT.type.h3),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: _ShT.type.body.copyWith(color: _ShT.pal.textSecondary),
          ),
          if (footer != null) ...[
            const SizedBox(height: 8),
            Text(
              footer!,
              style: _ShT.type.caption.copyWith(color: _ShT.pal.textTertiary),
            ),
          ],
          const SizedBox(height: 12),
          GlassCta(label: ctaLabel, onTap: onTap, compact: true),
        ],
      ),
    );
  }
}
