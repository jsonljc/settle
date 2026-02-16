import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../providers/profile_provider.dart';
import '../../providers/user_cards_provider.dart';
import '../../services/card_content_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/output_card.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';
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
        duration: const Duration(milliseconds: 1100),
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
                  title: 'Plan',
                  subtitle: 'Personalized support for $childName',
                  fallbackRoute: '/plan',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (needsRegulate) ...[
                          GlassCardRose(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Regulate first', style: T.type.h3),
                                const SizedBox(height: 6),
                                Text(
                                  'Take a quick reset before the next response.',
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
                          const SizedBox(height: 10),
                        ],
                        DebriefSection(
                          selectedTrigger: _selectedTrigger,
                          onTriggerTap: _selectTrigger,
                        ),
                        const SizedBox(height: 10),
                        if (_loading) ...[
                          const GlassCard(
                            child: SizedBox(
                              height: 120,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (_selectedCard != null) ...[
                          OutputCard(
                            scenarioLabel: _selectedCard!.triggerType,
                            prevent: _selectedCard!.prevent,
                            say: _selectedCard!.say,
                            doStep: _selectedCard!.doStep,
                            ifEscalates: _selectedCard!.ifEscalates,
                            onSave: () => _saveCard(_selectedCard!),
                            onShare: () =>
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Share flow coming in Phase 6',
                                    ),
                                    duration: Duration(milliseconds: 1200),
                                  ),
                                ),
                            onLog: () => context.push('/plan/log'),
                            onWhy: () => _showEvidence(_selectedCard!),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const PrepNudgeSection(),
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
  }
}

class PlanCardScreen extends StatelessWidget {
  const PlanCardScreen({super.key, required this.cardId});

  final String cardId;

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
                    const ScreenHeader(title: 'Script', fallbackRoute: '/plan'),
                    const SizedBox(height: 8),
                    OutputCard(
                      scenarioLabel: card.triggerType,
                      prevent: card.prevent,
                      say: card.say,
                      doStep: card.doStep,
                      ifEscalates: card.ifEscalates,
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
