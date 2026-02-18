import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tantrum_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/screen_header.dart';
import 'tantrum_unavailable.dart';

class _ThT {
  _ThT._();

  static final type = _ThTypeTokens();
  static const pal = _ThPaletteTokens();
}

class _ThTypeTokens {
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
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

class _ThPaletteTokens {
  const _ThPaletteTokens();

  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
  Color get accent => SettleColors.nightAccent;
}

// Deprecated in IA cleanup PR6. This legacy tantrum surface is no longer
// reachable from production routes and is retained only for internal reference.
class TantrumHubScreen extends ConsumerWidget {
  const TantrumHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasTantrumSupport = ref.watch(hasTantrumFeatureProvider);
    if (!hasTantrumSupport) {
      return const TantrumUnavailableView(title: 'Now: Incident');
    }

    final prevention = ref.watch(preventionProvider);
    final pattern = ref.watch(patternProvider);

    return Scaffold(
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: SettleSpacing.screenPadding,
                ),
                child: const ScreenHeader(title: 'Now: Incident'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.symmetric(
                    horizontal: SettleSpacing.screenPadding,
                  ).copyWith(bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _HubNavCard(
                      icon: Icons.play_circle_outline,
                      title: 'Practice mode',
                      subtitle: 'Rehearse before the next hard moment',
                      onTap: () => context.push('/home/tantrum/practice'),
                    ),
                    const SizedBox(height: 10),
                    _HubNavCard(
                      icon: Icons.auto_graph_outlined,
                      title: 'Patterns',
                      subtitle: pattern == null
                          ? 'No events yet'
                          : '${pattern.totalEvents} events in the last 7 days',
                      onTap: () => context.push('/home/tantrum/patterns'),
                    ),
                    const SizedBox(height: 10),
                    _HubNavCard(
                      icon: Icons.menu_book_outlined,
                      title: 'Scripts library',
                      subtitle: 'Exact words for during and after',
                      onTap: () => context.push('/home/tantrum/scripts'),
                    ),
                    const SizedBox(height: 10),
                    _HubNavCard(
                      icon: Icons.history_edu_outlined,
                      title: 'Log a debrief',
                      subtitle: 'Capture trigger, intensity, and what helped',
                      onTap: () => context.push('/home/tantrum/debrief'),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Current prevention playbook',
                      style: _ThT.type.overline.copyWith(
                        color: _ThT.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (prevention.isEmpty)
                      GlassCard(
                        child: Text(
                          'Log a few events to unlock trigger-aware prevention tips.',
                          style: _ThT.type.caption.copyWith(
                            color: _ThT.pal.textSecondary,
                          ),
                        ),
                      )
                    else
                      ...prevention.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Text(
                              item,
                              style: _ThT.type.body.copyWith(
                                color: _ThT.pal.textSecondary,
                              ),
                            ),
                          ),
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
}

class _HubNavCard extends StatelessWidget {
  const _HubNavCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: _ThT.pal.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: _ThT.type.label),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: _ThT.type.caption.copyWith(
                      color: _ThT.pal.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: _ThT.pal.textTertiary),
          ],
        ),
      ),
    );
  }
}
