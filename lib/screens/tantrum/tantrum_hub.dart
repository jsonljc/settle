import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tantrum_providers.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';
import 'tantrum_unavailable.dart';

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
                padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
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
                      style: T.type.overline.copyWith(
                        color: T.pal.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (prevention.isEmpty)
                      GlassCard(
                        child: Text(
                          'Log a few events to unlock trigger-aware prevention tips.',
                          style: T.type.caption.copyWith(
                            color: T.pal.textSecondary,
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
                              style: T.type.body.copyWith(
                                color: T.pal.textSecondary,
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
            Icon(icon, size: 20, color: T.pal.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: T.type.label),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: T.type.caption.copyWith(color: T.pal.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: T.pal.textTertiary),
          ],
        ),
      ),
    );
  }
}
