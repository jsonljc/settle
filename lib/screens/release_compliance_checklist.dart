import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/release_rollout_provider.dart';
import '../services/safety_compliance_service.dart';
import '../theme/glass_components.dart';
import '../theme/settle_design_system.dart';
import '../widgets/gradient_background.dart';
import '../widgets/release_surfaces.dart';
import '../widgets/screen_header.dart';

class _RccT {
  _RccT._();

  static final type = _RccTypeTokens();
  static const pal = _RccPaletteTokens();
}

class _RccTypeTokens {
  TextStyle get h3 => SettleTypography.heading.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w700,
  );
  TextStyle get body => SettleTypography.body;
  TextStyle get label =>
      SettleTypography.body.copyWith(fontWeight: FontWeight.w600);
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _RccPaletteTokens {
  const _RccPaletteTokens();

  Color get accent => SettleColors.nightAccent;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
  Color get teal => SettleColors.sage400;
}

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
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
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
                              style: _RccT.type.body.copyWith(
                                color: _RccT.pal.textSecondary,
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
                                  style: _RccT.type.h3.copyWith(
                                    color: _RccT.pal.accent,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$passed / $total controls mapped',
                                  style: _RccT.type.body.copyWith(
                                    color: _RccT.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Registry updated ${data.updatedAt}',
                                  style: _RccT.type.caption.copyWith(
                                    color: _RccT.pal.textTertiary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          ...data.items.map((item) {
                            final color = item.passed
                                ? _RccT.pal.teal
                                : SettleColors.blush400;
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
                                            style: _RccT.type.label,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      item.detail,
                                      style: _RccT.type.caption.copyWith(
                                        color: _RccT.pal.textSecondary,
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
