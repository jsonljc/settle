import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/v2_enums.dart';
import '../../providers/plan_ordering_provider.dart';
import '../../providers/usage_events_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';

class _PslT {
  _PslT._();

  static final type = _PslTypeTokens();
  static const pal = _PslPaletteTokens();
  static const glass = _PslGlassTokens();
  static const radius = _PslRadiusTokens();
}

class _PslTypeTokens {
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

class _PslPaletteTokens {
  const _PslPaletteTokens();

  Color get textPrimary => SettleColors.nightText;
  Color get textSecondary => SettleColors.nightSoft;
  Color get textTertiary => SettleColors.nightMuted;
  Color get accent => SettleColors.nightAccent;
}

class _PslGlassTokens {
  const _PslGlassTokens();

  Color get fillAccent => SettleColors.nightAccent.withValues(alpha: 0.10);
}

class _PslRadiusTokens {
  const _PslRadiusTokens();

  double get md => 18;
}

class PlanScriptLogScreen extends ConsumerStatefulWidget {
  const PlanScriptLogScreen({super.key, required this.cardId});

  final String cardId;

  @override
  ConsumerState<PlanScriptLogScreen> createState() =>
      _PlanScriptLogScreenState();
}

class _PlanScriptLogScreenState extends ConsumerState<PlanScriptLogScreen> {
  final _contextController = TextEditingController();
  UsageOutcome _outcome = UsageOutcome.okay;
  bool _regulationUsed = false;
  bool _saving = false;

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _saveLog() async {
    if (_saving) return;
    setState(() => _saving = true);

    final note = _contextController.text.trim();
    await ref
        .read(usageEventsProvider.notifier)
        .log(
          cardId: widget.cardId,
          outcome: _outcome,
          context: note.isEmpty ? null : note,
          regulationUsed: _regulationUsed,
        );

    if (_outcome != UsageOutcome.didntTry) {
      await ref.read(userCardsProvider.notifier).incrementUsage(widget.cardId);
    }

    await ref.read(patternEngineRefreshProvider.future);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Outcome logged'),
        duration: Duration(milliseconds: 800),
      ),
    );
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/plan');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cardId.trim().isEmpty) {
      return const RouteUnavailableView(
        title: 'Script log unavailable',
        message: 'Open a script from Plan first, then log the outcome.',
      );
    }

    return FutureBuilder<CardContent?>(
      future: CardContentService.instance.getCardById(widget.cardId),
      builder: (context, snapshot) {
        final card = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            body: GradientBackgroundFromRoute(
              child: const Center(
                child: CalmLoading(message: 'Loading session log…'),
              ),
            ),
          );
        }
        if (card == null) {
          return const RouteUnavailableView(
            title: 'Script not found',
            message: 'This script is no longer available.',
          );
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
                    const ScreenHeader(
                      title: 'Log script outcome',
                      subtitle: 'Capture what happened so Plan can adapt.',
                      fallbackRoute: '/plan',
                    ),
                    const SizedBox(height: 12),
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
                                  Text('Scenario', style: _PslT.type.caption),
                                  const SizedBox(height: 4),
                                  Text(
                                    _triggerLabel(card.triggerType),
                                    style: _PslT.type.h3,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    card.say,
                                    style: _PslT.type.body.copyWith(
                                      color: _PslT.pal.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            GlassCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Outcome', style: _PslT.type.h3),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: UsageOutcome.values.map((value) {
                                      final selected = _outcome == value;
                                      return GlassPill(
                                        label: _outcomeLabel(value),
                                        fill: selected
                                            ? _PslT.glass.fillAccent
                                            : null,
                                        textColor: selected
                                            ? _PslT.pal.accent
                                            : _PslT.pal.textPrimary,
                                        onTap: () =>
                                            setState(() => _outcome = value),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _contextController,
                                    maxLines: 2,
                                    style: _PslT.type.body,
                                    decoration: InputDecoration(
                                      hintText: 'What happened? (optional)',
                                      hintStyle: _PslT.type.body.copyWith(
                                        color: _PslT.pal.textTertiary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          _PslT.radius.md,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _regulationUsed,
                                        onChanged: (value) => setState(
                                          () =>
                                              _regulationUsed = value ?? false,
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () => setState(
                                            () => _regulationUsed =
                                                !_regulationUsed,
                                          ),
                                          child: Text(
                                            'I used regulate support first',
                                            style: _PslT.type.body.copyWith(
                                              color: _PslT.pal.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            GlassCta(
                              label: _saving ? 'Saving...' : 'Save outcome',
                              onTap: _saving ? () {} : _saveLog,
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
      },
    );
  }

  String _outcomeLabel(UsageOutcome outcome) {
    return switch (outcome) {
      UsageOutcome.great => 'Worked great',
      UsageOutcome.okay => 'Okay',
      UsageOutcome.didntWork => 'Didn\'t work',
      UsageOutcome.didntTry => 'Didn\'t try',
    };
  }

  String _triggerLabel(String triggerType) {
    return triggerType
        .split('_')
        .map((part) {
          if (part.isEmpty) return part;
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }
}
