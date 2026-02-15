import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../models/tantrum_profile.dart';
import '../../providers/profile_provider.dart';
import '../../providers/tantrum_providers.dart';
import '../../services/tantrum_engine.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/option_button.dart';
import 'tantrum_unavailable.dart';

// Deprecated in IA cleanup PR6. This legacy tantrum surface is no longer
// reachable from production routes and is retained only for internal reference.
class DebriefModeScreen extends ConsumerStatefulWidget {
  const DebriefModeScreen({super.key, this.flashcardUsed = false});

  final bool flashcardUsed;

  @override
  ConsumerState<DebriefModeScreen> createState() => _DebriefModeScreenState();
}

class _DebriefModeScreenState extends ConsumerState<DebriefModeScreen> {
  int _step = 0;
  bool _saved = false;

  TriggerType? _trigger;
  bool _otherTrigger = false;
  final _otherTriggerController = TextEditingController();

  TantrumIntensity? _intensity;
  final Set<String> _helpers = <String>{};
  final _noteController = TextEditingController();

  static const _helperOptions = [
    'Giving space',
    'Getting close',
    'Naming the feeling',
    'Distraction',
    'Setting a boundary',
    'Waiting it out',
    'Picking them up',
    'Offering a choice',
    'Nothing, it passed',
  ];

  @override
  void dispose() {
    _otherTriggerController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _canProceed {
    return switch (_step) {
      0 =>
        _trigger != null ||
            (_otherTrigger && _otherTriggerController.text.trim().isNotEmpty),
      1 => _intensity != null,
      2 => _helpers.isNotEmpty,
      3 => true,
      _ => false,
    };
  }

  Future<void> _next() async {
    if (!_canProceed) return;

    if (_step < 3) {
      setState(() => _step++);
      return;
    }

    final extraTrigger = _otherTriggerController.text.trim();
    final note = _noteController.text.trim();
    final mergedNote = [
      if (_otherTrigger && extraTrigger.isNotEmpty)
        'Other trigger: $extraTrigger',
      if (note.isNotEmpty) note,
    ].join(' · ');

    await ref
        .read(tantrumEventsProvider.notifier)
        .addDebrief(
          trigger: _trigger,
          intensity: _intensity ?? TantrumIntensity.moderate,
          whatHelped: _helpers.toList(),
          notes: mergedNote.isEmpty ? null : mergedNote,
          flashcardUsed: widget.flashcardUsed,
        );

    if (!mounted) return;
    setState(() => _saved = true);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final hasTantrumSupport = ref.watch(hasTantrumFeatureProvider);
    if (!hasTantrumSupport) {
      return const TantrumUnavailableView(title: 'Debrief');
    }

    final profile = ref.watch(profileProvider);
    final triggerOptions =
        (profile?.tantrumProfile?.commonTriggers ??
                [
                  TriggerType.transitions,
                  TriggerType.frustration,
                  TriggerType.sensory,
                  TriggerType.boundaries,
                ])
            .toSet()
            .toList();

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: T.space.screen),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _saved
                          ? context.go('/now')
                          : (context.canPop()
                                ? context.pop()
                                : context.go('/now')),
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        size: 20,
                        color: T.pal.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Debrief', style: T.type.h2),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: T.space.screen,
                  ).copyWith(bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  child: _saved
                      ? _SavedView(
                          repairScript: TantrumEngine.repairScriptForAge(
                            profile?.ageBracket ??
                                AgeBracket.nineteenToTwentyFourMonths,
                          ),
                        )
                      : _buildStep(triggerOptions),
                ),
              ),
              if (!_saved)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    T.space.screen,
                    0,
                    T.space.screen,
                    16,
                  ),
                  child: Column(
                    children: [
                      if (_step > 0)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: _back,
                            child: Text(
                              'Back',
                              style: T.type.caption.copyWith(
                                color: T.pal.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      if (_step > 0) const SizedBox(height: 8),
                      AnimatedOpacity(
                        opacity: _canProceed ? 1.0 : 0.4,
                        duration: T.anim.fast,
                        child: GlassCta(
                          label: _step == 3 ? 'Save debrief' : 'Continue',
                          enabled: _canProceed,
                          onTap: _next,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(List<TriggerType> triggerOptions) {
    switch (_step) {
      case 0:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('1. What triggered it?', style: T.type.h3),
            const SizedBox(height: 12),
            ...triggerOptions.map(
              (trigger) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionButton(
                  label: trigger.label,
                  selected: _trigger == trigger && !_otherTrigger,
                  onTap: () => setState(() {
                    _otherTrigger = false;
                    _trigger = trigger;
                  }),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: OptionButton(
                label: 'Other',
                selected: _otherTrigger,
                onTap: () => setState(() {
                  _otherTrigger = true;
                  _trigger = null;
                }),
              ),
            ),
            if (_otherTrigger) ...[
              const SizedBox(height: 10),
              GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: TextField(
                  controller: _otherTriggerController,
                  onChanged: (_) => setState(() {}),
                  style: T.type.body,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Type a quick trigger note',
                  ),
                ),
              ),
            ],
          ],
        );
      case 1:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('2. How intense was it?', style: T.type.h3),
            const SizedBox(height: 12),
            ...TantrumIntensity.values.map(
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionButton(
                  label: i.label,
                  subtitle: switch (i) {
                    TantrumIntensity.mild => 'Fussing, resolvable',
                    TantrumIntensity.moderate => 'Full tantrum, took time',
                    TantrumIntensity.intense => 'Overwhelming, very hard',
                  },
                  selected: _intensity == i,
                  onTap: () => setState(() => _intensity = i),
                ),
              ),
            ),
          ],
        );
      case 2:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('3. What helped?', style: T.type.h3),
            const SizedBox(height: 6),
            Text(
              'Select all that applied',
              style: T.type.caption.copyWith(color: T.pal.textSecondary),
            ),
            const SizedBox(height: 12),
            ..._helperOptions.map(
              (h) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OptionButton(
                  label: h,
                  selected: _helpers.contains(h),
                  onTap: () => setState(() {
                    if (_helpers.contains(h)) {
                      _helpers.remove(h);
                    } else {
                      _helpers.add(h);
                    }
                  }),
                ),
              ),
            ),
          ],
        );
      case 3:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('4. Add a note (optional)', style: T.type.h3),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                style: T.type.body,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Anything you want to remember?',
                ),
              ),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SavedView extends StatelessWidget {
  const _SavedView({required this.repairScript});

  final String repairScript;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassCardAccent(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Debrief saved', style: T.type.h3),
              const SizedBox(height: 8),
              Text(
                'Nice work. Consistent reflection is how patterns get clearer over time.',
                style: T.type.body.copyWith(color: T.pal.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Repair script',
                style: T.type.overline.copyWith(color: T.pal.textTertiary),
              ),
              const SizedBox(height: 8),
              Text(repairScript, style: T.type.h3),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GlassCta(label: 'Back to home', onTap: () => context.go('/now')),
      ],
    );
  }
}
