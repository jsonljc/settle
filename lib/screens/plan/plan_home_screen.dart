import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../providers/nudge_settings_provider.dart';
import '../../providers/plan_ordering_provider.dart';
import '../../providers/patterns_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/nudge_scheduler.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/output_card.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/weekly_reflection.dart';
import '../../providers/weekly_reflection_provider.dart';
import 'debrief_section.dart';
import 'prep_nudge_section.dart';

class PlanHomeScreen extends ConsumerStatefulWidget {
  const PlanHomeScreen({super.key});

  @override
  ConsumerState<PlanHomeScreen> createState() => _PlanHomeScreenState();
}

class _PlanHomeScreenState extends ConsumerState<PlanHomeScreen> {
  String? _selectedTrigger;
  CardContent? _selectedCard;
  bool _loading = false;
  bool _nudgeScheduled = false;

  Future<void> _selectTrigger(String trigger) async {
    setState(() {
      _selectedTrigger = trigger;
      _loading = true;
    });
    final card = await CardContentService.instance.selectBestCard(
      triggerType: trigger,
    );
    if (!mounted) return;
    setState(() {
      _selectedCard = card;
      _loading = false;
    });
  }

  Future<void> _saveCard(CardContent card) async {
    await ref.read(userCardsProvider.notifier).save(card.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Saved to playbook'),
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  Future<void> _showEvidence(CardContent card) async {
    final evidence =
        card.evidence ?? 'This script follows co-regulation first.';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              T.space.screen,
              T.space.md,
              T.space.screen,
              T.space.screen,
            ),
            child: GlassCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Why this works', style: T.type.h3),
                  const SizedBox(height: 8),
                  Text(
                    evidence,
                    style: T.type.body.copyWith(color: T.pal.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _copyScript(BuildContext context, CardContent card) {
    final buffer = StringBuffer();
    buffer.writeln('Prevent: ${card.prevent}');
    buffer.writeln('Say: ${card.say}');
    buffer.writeln('Do: ${card.doStep}');
    if (card.ifEscalates != null && card.ifEscalates!.isNotEmpty) {
      buffer.writeln('If it escalates: ${card.ifEscalates}');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Script copied to clipboard'),
          duration: Duration(milliseconds: 800),
        ),
      );
    }
  }

  bool _needsRegulateFirst(RegulationLevel? level) {
    return level == RegulationLevel.stressed ||
        level == RegulationLevel.anxious ||
        level == RegulationLevel.angry;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return const ProfileRequiredView(title: 'Plan');
    }

    if (!_nudgeScheduled) {
      _nudgeScheduled = true;
      Future.microtask(() async {
        await NudgeScheduler.scheduleNudges(
          profile: ref.read(profileProvider),
          patterns: ref.read(patternsProvider),
          settings: ref.read(nudgeSettingsProvider),
        );
      });
    }

    ref.watch(patternEngineRefreshProvider);
    final triggerOrder = ref.watch(triggerOrderByUsageProvider);
    final needsRegulate = _needsRegulateFirst(profile.regulationLevel);
    final childName = profile.name.trim().isEmpty ? 'your child' : profile.name;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  title: 'Home',
                  subtitle: _homeSubtitle(childName),
                  fallbackRoute: '/plan',
                  showBackButton: false,
                ),
                SizedBox(height: T.space.sm),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.push('/plan/moment?context=general'),
                      child: Text(
                        'Just need 10 seconds',
                        style: T.type.caption.copyWith(
                          color: T.pal.textTertiary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    Text(
                      ' · ',
                      style: T.type.caption.copyWith(color: T.pal.textTertiary),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/plan/reset?context=tantrum'),
                      child: Text(
                        'Tantrum just happened',
                        style: T.type.caption.copyWith(
                          color: T.pal.textTertiary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: T.space.lg),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!ref.watch(
                              weeklyReflectionDismissedThisWeekProvider,
                            ) &&
                            WeeklyReflectionBanner.shouldShow()) ...[
                          WeeklyReflectionBanner(
                            onDismiss: () => ref
                                .read(weeklyReflectionProvider.notifier)
                                .dismissThisWeek(),
                          ),
                          SizedBox(height: T.space.xl),
                        ],
                        if (needsRegulate) ...[
                          GlassCardRose(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Regulate first', style: T.type.h3),
                                const SizedBox(height: 6),
                                Text(
                                  'A quick reset before the next response.',
                                  style: T.type.body.copyWith(
                                    color: T.pal.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                GlassCta(
                                  label: 'Open regulate flow',
                                  onTap: () => context.push('/plan/regulate'),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: T.space.xl),
                        ],
                        DebriefSection(
                          selectedTrigger: _selectedTrigger,
                          onTriggerTap: _selectTrigger,
                          triggers: triggerOrder,
                        ),
                        SizedBox(height: T.space.xl),
                        if (_loading) ...[
                          const GlassCard(
                            child: SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                          SizedBox(height: T.space.xl),
                        ],
                        if (_selectedCard != null) ...[
                          OutputCard(
                            scenarioLabel: _selectedCard!.triggerType,
                            prevent: _selectedCard!.prevent,
                            say: _selectedCard!.say,
                            doStep: _selectedCard!.doStep,
                            ifEscalates: _selectedCard!.ifEscalates,
                            onSave: () => _saveCard(_selectedCard!),
                            onShare: () => _copyScript(context, _selectedCard!),
                            onLog: () => context.push(
                              '/plan/log?card_id=${Uri.encodeComponent(_selectedCard!.id)}',
                            ),
                            onWhy: () => _showEvidence(_selectedCard!),
                          ),
                          SizedBox(height: T.space.xl),
                        ],
                        PrepNudgeSection(patterns: ref.watch(patternsProvider)),
                        SizedBox(height: T.space.xxxl),
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
  }

  String _homeSubtitle(String childName) {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning · Support for $childName';
    if (hour < 17) return 'Support for $childName';
    return 'Good evening · Support for $childName';
  }
}

class PlanCardScreen extends StatelessWidget {
  const PlanCardScreen({
    super.key,
    required this.cardId,
    this.fallbackRoute = '/plan',
  });

  final String cardId;
  final String fallbackRoute;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CardContent?>(
      future: CardContentService.instance.getCardById(cardId),
      builder: (context, snapshot) {
        final card = snapshot.data;
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (card == null) {
          return const RouteUnavailableView(
            title: 'Card not found',
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
                    ScreenHeader(title: 'Script', fallbackRoute: fallbackRoute),
                    const SizedBox(height: 8),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: OutputCard(
                          scenarioLabel: card.triggerType,
                          prevent: card.prevent,
                          say: card.say,
                          doStep: card.doStep,
                          ifEscalates: card.ifEscalates,
                          primaryLabel: 'Done',
                          onPrimary: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go(fallbackRoute);
                            }
                          },
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
}
