import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tantrum_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import 'tantrum_unavailable.dart';

class _PmT {
  _PmT._();

  static final type = _PmTypeTokens();
  static const pal = _PmPaletteTokens();
}

class _PmTypeTokens {
  TextStyle get body => SettleTypography.body;
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class _PmPaletteTokens {
  const _PmPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

// Deprecated in IA cleanup PR6. This legacy tantrum surface is no longer
// reachable from production routes and is retained only for internal reference.
class PracticeModeScreen extends ConsumerStatefulWidget {
  const PracticeModeScreen({super.key});

  @override
  ConsumerState<PracticeModeScreen> createState() => _PracticeModeScreenState();
}

class _PracticeModeScreenState extends ConsumerState<PracticeModeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final hasTantrumSupport = ref.watch(hasTantrumFeatureProvider);
    if (!hasTantrumSupport) {
      return const TantrumUnavailableView(title: 'Practice mode');
    }

    final scenario = ref.watch(scenarioProvider);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SettleSpacing.screenPadding,
                ),
                child: const ScreenHeader(title: 'Practice mode'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ),
                  child: scenario == null
                      ? GlassCard(
                          child: Text(
                            'Complete tantrum onboarding first to unlock practice scenarios.',
                            style: _PmT.type.body.copyWith(
                              color: _PmT.pal.textSecondary,
                            ),
                          ),
                        )
                      : _ScenarioDeck(
                          index: _index,
                          onIndexChanged: (v) => setState(() => _index = v),
                          cards: [
                            _CardData(title: 'Setup', body: scenario.setup),
                            _CardData(
                              title: 'Your breath',
                              body: scenario.breath,
                            ),
                            _CardData(title: 'Assess', body: scenario.assess),
                            ...scenario.responseCards.map(
                              (body) =>
                                  _CardData(title: 'Response', body: body),
                            ),
                            _CardData(title: 'Repair', body: scenario.repair),
                            _CardData(title: 'Debrief', body: scenario.debrief),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardData {
  const _CardData({required this.title, required this.body});

  final String title;
  final String body;
}

class _ScenarioDeck extends StatelessWidget {
  const _ScenarioDeck({
    required this.index,
    required this.onIndexChanged,
    required this.cards,
  });

  final int index;
  final ValueChanged<int> onIndexChanged;
  final List<_CardData> cards;

  @override
  Widget build(BuildContext context) {
    final current = cards[index];
    final isFirst = index == 0;
    final isLast = index == cards.length - 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${index + 1} / ${cards.length}',
          style: _PmT.type.caption.copyWith(color: _PmT.pal.textSecondary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  current.title.toUpperCase(),
                  style: _PmT.type.overline.copyWith(
                    color: _PmT.pal.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  current.body,
                  style: _PmT.type.body.copyWith(color: _PmT.pal.textSecondary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: GlassPill(
                label: 'Back',
                enabled: !isFirst,
                onTap: () => onIndexChanged(index - 1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GlassCta(
                label: isLast ? 'Done' : 'Next',
                onTap: isLast
                    ? () => context.pop()
                    : () => onIndexChanged(index + 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
