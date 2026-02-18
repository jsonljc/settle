import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/tantrum_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import 'tantrum_unavailable.dart';

class _SlT {
  _SlT._();

  static final type = _SlTypeTokens();
  static const pal = _SlPaletteTokens();
}

class _SlTypeTokens {
  TextStyle get body => SettleTypography.body;
  TextStyle get overline => SettleTypography.caption.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
  );
}

class _SlPaletteTokens {
  const _SlPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
}

// Deprecated in IA cleanup PR6. This legacy tantrum surface is no longer
// reachable from production routes and is retained only for internal reference.
class ScriptsLibraryScreen extends ConsumerWidget {
  const ScriptsLibraryScreen({super.key});

  static const _during = [
    '"You\'re really angry right now."',
    '"That was so frustrating."',
    '"You wanted that so much and the answer is no."',
    '"Your body is full of big feelings."',
    '"I can see you\'re upset. I\'m here."',
    '"I won\'t let you hit. I\'ll keep everyone safe."',
  ];

  static const _after = [
    '"That was hard. I love you."',
    '"We both had big feelings. That happens."',
    '"I\'m proud of how you calmed down."',
    '"I\'m sorry I raised my voice."',
    '"What was the hardest part?"',
    '"What could we try next time?"',
  ];

  static const _prevention = [
    '"We\'re leaving in 5 minutes. I\'ll remind you at 2."',
    '"Red cup or blue cup?"',
    '"Do you want help or one more try?"',
    '"When shoes are on, then we go outside."',
    '"You can be angry. You can\'t throw."',
    '"The answer is no. I\'ll sit with you while it feels hard."',
  ];

  static const _parent = [
    '"I am the adult. I am safe."',
    '"This feels intense. I can slow down."',
    '"I can take this one step at a time."',
    '"My child is having a hard time, and I can stay steady."',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTantrumSupport = ref.watch(hasTantrumFeatureProvider);
    if (!hasTantrumSupport) {
      return const TantrumUnavailableView(title: 'Scripts library');
    }

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SettleSpacing.screenPadding,
                ),
                child: const ScreenHeader(title: 'Scripts library'),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ).copyWith(bottom: 24),
                  children: const [
                    _Section(title: 'During big feelings', lines: _during),
                    SizedBox(height: 12),
                    _Section(title: 'After calm returns', lines: _after),
                    SizedBox(height: 12),
                    _Section(title: 'Prevention', lines: _prevention),
                    SizedBox(height: 12),
                    _Section(title: 'Parent self-regulation', lines: _parent),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.lines});

  final String title;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: _SlT.type.overline.copyWith(color: _SlT.pal.textTertiary),
          ),
          const SizedBox(height: 8),
          ...lines.asMap().entries.map(
            (entry) => Padding(
              padding: EdgeInsets.only(
                bottom: entry.key == lines.length - 1 ? 0 : 8,
              ),
              child: Text(
                entry.value,
                style: _SlT.type.body.copyWith(color: _SlT.pal.textSecondary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
