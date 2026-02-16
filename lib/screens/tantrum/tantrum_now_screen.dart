import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/tantrum_providers.dart';
import '../../tantrum/providers/tantrum_entitlement_provider.dart';
import '../../tantrum/services/tantrum_registry_service.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/option_button.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/tantrum_sub_nav.dart';

/// Capture flow: required trigger + optional intensity/location/parent reaction.
/// No typing. One CTA: Log & Get Card.
class TantrumNowScreen extends ConsumerStatefulWidget {
  const TantrumNowScreen({super.key});

  @override
  ConsumerState<TantrumNowScreen> createState() => _TantrumNowScreenState();
}

class _TantrumNowScreenState extends ConsumerState<TantrumNowScreen> {
  String? _trigger;
  String? _intensity;
  String? _location;
  String? _parentReaction;
  bool _submitting = false;

  static const _triggers = [
    _CaptureOption('transition', 'Transition', Icons.swap_horiz_rounded),
    _CaptureOption('no_limit', 'No / limit', Icons.block_rounded),
    _CaptureOption('tired_hungry', 'Tired / hungry', Icons.bedtime_rounded),
    _CaptureOption(
      'attention_conflict',
      'Attention conflict',
      Icons.visibility_rounded,
    ),
    _CaptureOption(
      'sibling_conflict',
      'Sibling conflict',
      Icons.people_alt_rounded,
    ),
    _CaptureOption('unknown', 'Unknown', Icons.help_outline_rounded),
  ];

  static const _intensities = [
    _CaptureOption('mild', 'Mild', Icons.sentiment_satisfied_alt_rounded),
    _CaptureOption('medium', 'Medium', Icons.sentiment_neutral_rounded),
    _CaptureOption('intense', 'Intense', Icons.local_fire_department_rounded),
  ];

  static const _locations = [
    _CaptureOption('home', 'Home', Icons.home_outlined),
    _CaptureOption('public', 'Public', Icons.storefront_outlined),
    _CaptureOption('car', 'Car', Icons.directions_car_outlined),
    _CaptureOption('school', 'School', Icons.school_outlined),
    _CaptureOption('other', 'Other', Icons.place_outlined),
  ];

  static const _reactions = [
    _CaptureOption('stayed_calm', 'Stayed calm', Icons.spa_outlined),
    _CaptureOption('raised_voice', 'Raised voice', Icons.record_voice_over),
    _CaptureOption('gave_in', 'Gave in', Icons.undo_rounded),
    _CaptureOption('walked_away', 'Walked away', Icons.directions_walk_rounded),
    _CaptureOption('not_sure', 'Not sure', Icons.question_mark_rounded),
  ];

  Future<void> _logAndGetCard() async {
    final trigger = _trigger;
    if (trigger == null || _submitting) return;
    final unlockedPacks = ref.read(unlockedPackIdsProvider);

    setState(() => _submitting = true);
    try {
      final card = await TantrumRegistryService.instance.selectBestCard(
        trigger: trigger,
        intensity: _intensity,
        parentReaction: _parentReaction,
        unlockedPackIds: unlockedPacks,
      );
      if (card == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No card found. Please try again.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final notifier = ref.read(tantrumEventsProvider.notifier);
      await notifier.addCapture(
        trigger: trigger,
        intensity: _intensity,
        location: _location,
        parentReaction: _parentReaction,
        selectedCardId: card.id,
      );

      if (!mounted) return;
      context.push('/tantrum/card?cardId=${Uri.encodeComponent(card.id)}');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save log. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Capture',
                  subtitle: 'Log in seconds. Get one calm card.',
                  fallbackRoute: '/tantrum',
                ),
                const SizedBox(height: 12),
                const TantrumSubNav(
                  currentSegment: TantrumSubNav.segmentCapture,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxHeight < 700;
                      final sectionGap = compact ? 8.0 : 10.0;
                      final labelGap = compact ? 4.0 : 6.0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _SectionLabel('1. Trigger (required)'),
                          SizedBox(height: labelGap),
                          _OptionGrid(
                            options: _triggers,
                            selectedKey: _trigger,
                            columns: compact ? 3 : 2,
                            dense: compact,
                            onSelected: (value) =>
                                setState(() => _trigger = value),
                          ),
                          SizedBox(height: sectionGap),
                          const _SectionLabel('2. Intensity (optional)'),
                          SizedBox(height: labelGap),
                          _OptionGrid(
                            options: _intensities,
                            selectedKey: _intensity,
                            columns: 3,
                            dense: compact,
                            onSelected: (value) => setState(() {
                              _intensity = _intensity == value ? null : value;
                            }),
                          ),
                          SizedBox(height: sectionGap),
                          const _SectionLabel('3. Location (optional)'),
                          SizedBox(height: labelGap),
                          _OptionGrid(
                            options: _locations,
                            selectedKey: _location,
                            columns: 3,
                            dense: compact,
                            onSelected: (value) => setState(() {
                              _location = _location == value ? null : value;
                            }),
                          ),
                          SizedBox(height: sectionGap),
                          const _SectionLabel('4. Parent reaction (optional)'),
                          SizedBox(height: labelGap),
                          _OptionGrid(
                            options: _reactions,
                            selectedKey: _parentReaction,
                            columns: compact ? 3 : 2,
                            dense: compact,
                            onSelected: (value) => setState(() {
                              _parentReaction = _parentReaction == value
                                  ? null
                                  : value;
                            }),
                          ),
                          const Spacer(),
                          GlassCta(
                            label: _submitting
                                ? 'Logging...'
                                : 'Log & Get Card',
                            enabled: _trigger != null && !_submitting,
                            onTap: _logAndGetCard,
                          ),
                          SizedBox(height: compact ? 4 : 8),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: T.type.overline.copyWith(color: T.pal.textTertiary),
    );
  }
}

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.options,
    required this.selectedKey,
    required this.columns,
    this.dense = false,
    required this.onSelected,
  });

  final List<_CaptureOption> options;
  final String? selectedKey;
  final int columns;
  final bool dense;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const spacing = 8.0;
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: options.map((option) {
            return SizedBox(
              width: width,
              child: OptionButtonCompact(
                label: option.label,
                icon: option.icon,
                dense: dense,
                selected: selectedKey == option.key,
                onTap: () => onSelected(option.key),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

class _CaptureOption {
  const _CaptureOption(this.key, this.label, this.icon);

  final String key;
  final String label;
  final IconData icon;
}
