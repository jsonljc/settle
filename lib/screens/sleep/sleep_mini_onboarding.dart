import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../providers/profile_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/option_button.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';
import '../sleep_tonight.dart';

class _SmoT {
  _SmoT._();

  static final type = _SmoTypeTokens();
  static const anim = _SmoAnimTokens();
}

class _SmoTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
}

class _SmoAnimTokens {
  const _SmoAnimTokens();

  Duration get fast => const Duration(milliseconds: 150);
}

/// Gate: profile required, sleep setup required. When complete, lands on
/// Sleep Tonight (situation picker) as the Sleep tab default.
class SleepMiniOnboardingGate extends ConsumerWidget {
  const SleepMiniOnboardingGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Sleep');
    }

    if (profile.sleepProfileComplete == false) {
      return const SleepMiniOnboardingScreen();
    }

    return const SleepTonightScreen();
  }
}

class SleepMiniOnboardingScreen extends ConsumerStatefulWidget {
  const SleepMiniOnboardingScreen({super.key});

  @override
  ConsumerState<SleepMiniOnboardingScreen> createState() =>
      _SleepMiniOnboardingScreenState();
}

class _SleepMiniOnboardingScreenState
    extends ConsumerState<SleepMiniOnboardingScreen> {
  Approach? _approach;
  FeedingType? _feeding;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    _approach = profile?.approach;
    _feeding = profile?.feedingType;
  }

  Future<void> _save() async {
    if (_saving) return;
    final approach = _approach;
    final feeding = _feeding;
    final profile = ref.read(profileProvider);

    if (profile == null || approach == null || feeding == null) return;

    setState(() => _saving = true);

    await ref
        .read(profileProvider.notifier)
        .save(
          profile.copyWith(
            approach: approach,
            feedingType: feeding,
            sleepProfileComplete: true,
          ),
        );

    if (!mounted) return;
    context.go('/sleep');
  }

  @override
  Widget build(BuildContext context) {
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
                  title: 'Sleep setup',
                  subtitle: 'One-time setup before Sleep tools unlock.',
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Which approach fits your family?',
                          style: _SmoT.type.h3,
                        ),
                        const SizedBox(height: 10),
                        ...Approach.values.map((approach) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: OptionButton(
                              label: approach.label,
                              subtitle: approach.description,
                              selected: _approach == approach,
                              onTap: () => setState(() => _approach = approach),
                            ),
                          );
                        }),
                        const SizedBox(height: 10),
                        Text('Feeding mode', style: _SmoT.type.h3),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: FeedingType.values.map((feeding) {
                            return OptionButtonCompact(
                              label: feeding.label,
                              selected: _feeding == feeding,
                              onTap: () => setState(() => _feeding = feeding),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AnimatedOpacity(
                    duration: _SmoT.anim.fast,
                    opacity: _approach != null && _feeding != null && !_saving
                        ? 1
                        : 0.45,
                    child: IgnorePointer(
                      ignoring:
                          _approach == null || _feeding == null || _saving,
                      child: GlassCta(
                        label: _saving ? 'Saving...' : 'Continue to Sleep',
                        onTap: _save,
                      ),
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
