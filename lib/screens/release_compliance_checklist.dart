import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/release_rollout_provider.dart';
import '../services/safety_compliance_service.dart';
import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';

class ReleaseComplianceChecklistScreen extends ConsumerStatefulWidget {
  const ReleaseComplianceChecklistScreen({super.key});

  @override
  ConsumerState<ReleaseComplianceChecklistScreen> createState() =>
      _ReleaseComplianceChecklistScreenState();
}

class _ReleaseComplianceChecklistScreenState
    extends ConsumerState<ReleaseComplianceChecklistScreen> {
  final _service = const SafetyComplianceService();
  Future<ComplianceChecklistSnapshot>? _future;

  @override
  void initState() {
    super.initState();
    _future = _service.loadChecklist();
  }

  @override
  Widget build(BuildContext context) {
    final rollout = ref.watch(releaseRolloutProvider);
    if (!rollout.isLoading && !rollout.complianceChecklistEnabled) {
      return const FeaturePausedView(title: 'Safety & Compliance');
    }

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(title: 'Safety & Compliance'),
                const SizedBox(height: 8),
                const BehavioralScopeNotice(),
                const SizedBox(height: 14),
                Expanded(
                  child: FutureBuilder<ComplianceChecklistSnapshot>(
                    future: _future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: CircularProgressIndicator.adaptive(),
                        );
                      }
                      if (snapshot.hasError || !snapshot.hasData) {
                        return Center(
                          child: GlassCard(
                            child: Text(
                              'Unable to load compliance checklist.',
                              style: T.type.body.copyWith(
                                color: T.pal.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }

                      final data = snapshot.data!;
                      final passed = data.items.where((i) => i.passed).length;
                      final total = data.items.length;

                      return ListView(
                        physics: const BouncingScrollPhysics(),
                        children: [
                          GlassCardAccent(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checklist status',
                                  style: T.type.h3.copyWith(
                                    color: T.pal.accent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$passed / $total controls mapped',
                                  style: T.type.body.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Registry updated ${data.updatedAt}',
                                  style: T.type.caption.copyWith(
                                    color: T.pal.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...data.items.map((item) {
                            final color = item.passed
                                ? T.pal.teal
                                : const Color(0xFFC86464);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: GlassCard(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          item.passed
                                              ? Icons.check_circle_rounded
                                              : Icons.error_outline_rounded,
                                          size: 18,
                                          color: color,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            item.title,
                                            style: T.type.label,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.detail,
                                      style: T.type.caption.copyWith(
                                        color: T.pal.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
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
