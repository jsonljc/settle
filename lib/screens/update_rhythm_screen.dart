import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/approach.dart';
import '../models/rhythm_models.dart';
import '../providers/profile_provider.dart';
import '../providers/rhythm_provider.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/calm_loading.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';

class UpdateRhythmScreen extends ConsumerStatefulWidget {
  const UpdateRhythmScreen({super.key});

  @override
  ConsumerState<UpdateRhythmScreen> createState() => _UpdateRhythmScreenState();
}

class _UpdateRhythmScreenState extends ConsumerState<UpdateRhythmScreen> {
  String? _loadedChildId;
  bool _loadScheduled = false;

  String _wakeRangeKey = '0630_0700';
  bool _daycareMode = false;
  int? _napCountReality;
  RhythmUpdateIssue _issue = RhythmUpdateIssue.nightWakes;
  bool _isSubmitting = false;

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

  (int, int) _wakeRangeMinutes(String key) {
    return switch (key) {
      '0600_0630' => (6 * 60, (6 * 60) + 30),
      '0630_0700' => ((6 * 60) + 30, 7 * 60),
      '0700_0730' => (7 * 60, (7 * 60) + 30),
      _ => ((6 * 60) + 30, 7 * 60),
    };
  }

  Future<void> _loadIfNeeded() async {
    final profile = ref.read(profileProvider);
    if (profile == null) return;
    final childId = profile.createdAt;
    if (_loadedChildId == childId) return;
    _loadedChildId = childId;
    await ref
        .read(rhythmProvider.notifier)
        .load(childId: childId, ageMonths: _ageMonthsFor(profile.ageBracket));
  }

  void _scheduleLoadIfNeeded() {
    if (_loadScheduled) return;
    _loadScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadScheduled = false;
      if (!mounted) return;
      _loadIfNeeded();
    });
  }

  Future<void> _buildUpdatedRhythm({
    required String childId,
    required int ageMonths,
  }) async {
    if (_isSubmitting) return;
    final range = _wakeRangeMinutes(_wakeRangeKey);
    setState(() => _isSubmitting = true);
    await ref
        .read(rhythmProvider.notifier)
        .applyRhythmUpdate(
          childId: childId,
          ageMonths: ageMonths,
          wakeRangeStartMinutes: range.$1,
          wakeRangeEndMinutes: range.$2,
          daycareMode: _daycareMode,
          napCountReality: _napCountReality,
          issue: _issue,
        );
    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleLoadIfNeeded();

    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Update Rhythm');
    }

    final childId = profile.createdAt;
    final ageMonths = _ageMonthsFor(profile.ageBracket);
    final state = ref.watch(rhythmProvider);
    final rhythm = state.rhythm;
    final shift = state.shiftAssessment;
    final updatePlan = state.lastUpdatePlan;

    _napCountReality ??= rhythm?.napCountTarget;

    if (state.isLoading) {
      return const Scaffold(
        body: SettleBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: CalmLoading(message: 'Preparing update flow…'),
            ),
          ),
        ),
      );
    }

    if (rhythm == null) {
      return Scaffold(
        body: SettleBackground(
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: T.space.screen),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ScreenHeader(
                    title: 'Update Rhythm',
                    subtitle: 'Replan only when rhythm has shifted.',
                  ),
                  GlassCard(
                    child: Text(
                      'No rhythm is loaded yet. Return to Current Rhythm and try again.',
                      style: T.type.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Update Rhythm',
                  subtitle: '2–5 taps, then hold for the next 1–2 weeks.',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Why update now', style: T.type.h3),
                              const SizedBox(height: 8),
                              Text(
                                shift.shouldSuggestUpdate
                                    ? shift.explanation
                                    : 'Manual update. No forced trigger detected.',
                                style: T.type.body,
                              ),
                              if (shift.reasons.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                ...shift.reasons
                                    .take(3)
                                    .map(
                                      (reason) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 4,
                                        ),
                                        child: Text(
                                          '• ${reason.title}',
                                          style: T.type.caption.copyWith(
                                            color: T.pal.textSecondary,
                                          ),
                                        ),
                                      ),
                                    ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Wake time range', style: T.type.label),
                              const SizedBox(height: 8),
                              _ChoiceWrap(
                                options: const {
                                  '0600_0630': '06:00–06:30',
                                  '0630_0700': '06:30–07:00',
                                  '0700_0730': '07:00–07:30',
                                },
                                selected: _wakeRangeKey,
                                onChanged: (value) {
                                  setState(() => _wakeRangeKey = value);
                                },
                              ),
                              const SizedBox(height: 12),
                              Text('Daycare', style: T.type.label),
                              const SizedBox(height: 8),
                              _ChoiceWrap(
                                options: const {'no': 'No', 'yes': 'Yes'},
                                selected: _daycareMode ? 'yes' : 'no',
                                onChanged: (value) {
                                  setState(() => _daycareMode = value == 'yes');
                                },
                              ),
                              const SizedBox(height: 12),
                              Text('Nap count reality', style: T.type.label),
                              const SizedBox(height: 8),
                              _ChoiceWrap(
                                options: const {
                                  '1': '1 nap',
                                  '2': '2 naps',
                                  '3': '3 naps',
                                  '4': '4 naps',
                                },
                                selected: (_napCountReality ?? 2).toString(),
                                onChanged: (value) {
                                  setState(
                                    () =>
                                        _napCountReality = int.tryParse(value),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              Text('Biggest issue', style: T.type.label),
                              const SizedBox(height: 8),
                              _ChoiceWrap(
                                options: const {
                                  'early_wakes': 'Early wakes',
                                  'night_wakes': 'Night wakes',
                                  'short_naps': 'Short naps',
                                  'bedtime_battles': 'Bedtime battles',
                                },
                                selected: _issue.wire,
                                onChanged: (value) {
                                  setState(
                                    () => _issue =
                                        RhythmUpdateIssueWire.fromString(value),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionChip(
                          label: _isSubmitting
                              ? 'Building…'
                              : 'Build next 1–2 week rhythm',
                          onTap: _isSubmitting
                              ? () {}
                              : () => _buildUpdatedRhythm(
                                  childId: childId,
                                  ageMonths: ageMonths,
                                ),
                          selected: true,
                        ),
                        if (updatePlan != null) ...[
                          const SizedBox(height: 12),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('New rhythm ready', style: T.type.h3),
                                const SizedBox(height: 6),
                                Text(
                                  'Confidence: ${updatePlan.confidence.label}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  updatePlan.anchorRecommendation,
                                  style: T.type.body,
                                ),
                                const SizedBox(height: 6),
                                ...updatePlan.changeSummary.map(
                                  (line) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      '• $line',
                                      style: T.type.caption.copyWith(
                                        color: T.pal.textSecondary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _ActionChip(
                                  label: 'Back to Current Rhythm',
                                  onTap: () => context.go('/sleep/rhythm'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
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

class _ChoiceWrap extends StatelessWidget {
  const _ChoiceWrap({
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  final Map<String, String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.entries.map((entry) {
        final isSelected = selected == entry.key;
        return _ActionChip(
          label: entry.value,
          selected: isSelected,
          onTap: () => onChanged(entry.key),
        );
      }).toList(),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.onTap,
    this.selected = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final color = selected ? T.pal.accent : T.pal.textSecondary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? T.glass.fillAccent : T.glass.fill,
          borderRadius: BorderRadius.circular(T.radius.pill),
          border: Border.all(color: T.glass.border),
        ),
        child: Text(
          label,
          style: T.type.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
