import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/v2_enums.dart';
import '../../providers/plan_ordering_provider.dart';
import '../../providers/usage_events_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';

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
        duration: Duration(milliseconds: 900),
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
          return const Scaffold(
            body: SettleBackground(
              child: Center(child: CircularProgressIndicator.adaptive()),
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
          body: SettleBackground(
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: T.space.screen),
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
                                  Text('Scenario', style: T.type.caption),
                                  const SizedBox(height: 4),
                                  Text(
                                    _triggerLabel(card.triggerType),
                                    style: T.type.h3,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    card.say,
                                    style: T.type.body.copyWith(
                                      color: T.pal.textSecondary,
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
                                  Text('Outcome', style: T.type.h3),
                                  const SizedBox(height: 10),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: UsageOutcome.values.map((value) {
                                      final selected = _outcome == value;
                                      return GlassPill(
                                        label: _outcomeLabel(value),
                                        fill: selected
                                            ? T.glass.fillAccent
                                            : null,
                                        textColor: selected
                                            ? T.pal.accent
                                            : T.pal.textPrimary,
                                        onTap: () =>
                                            setState(() => _outcome = value),
                                      );
                                    }).toList(),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _contextController,
                                    maxLines: 2,
                                    style: T.type.body,
                                    decoration: InputDecoration(
                                      hintText: 'What happened? (optional)',
                                      hintStyle: T.type.body.copyWith(
                                        color: T.pal.textTertiary,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          T.radius.md,
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
                                            style: T.type.body.copyWith(
                                              color: T.pal.textSecondary,
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
