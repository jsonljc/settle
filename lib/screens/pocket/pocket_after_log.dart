import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../widgets/settle_cta.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

/// Quick log after Pocket use: outcome, optional context, regulationUsed → [UsageEvent].
class PocketAfterLog extends ConsumerStatefulWidget {
  const PocketAfterLog({
    super.key,
    required this.cardId,
    required this.outcome,
    required this.onSubmitted,
  });

  final String cardId;
  final UsageOutcome outcome;
  final VoidCallback onSubmitted;

  @override
  ConsumerState<PocketAfterLog> createState() => _PocketAfterLogState();
}

class _PocketAfterLogState extends ConsumerState<PocketAfterLog> {
  final _contextController = TextEditingController();
  bool _regulationUsed = false;
  bool _submitting = false;

  @override
  void dispose() {
    _contextController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    await ref
        .read(usageEventsProvider.notifier)
        .log(
          cardId: widget.cardId,
          outcome: widget.outcome,
          context: _contextController.text.trim().isEmpty
              ? null
              : _contextController.text.trim(),
          regulationUsed: _regulationUsed,
        );
    if (!mounted) return;
    widget.onSubmitted();
  }

  static String _outcomeLabel(UsageOutcome o) {
    return switch (o) {
      UsageOutcome.great => 'Worked great',
      UsageOutcome.okay => 'Okay',
      UsageOutcome.didntWork => 'Didn\'t work this time',
      UsageOutcome.didntTry => 'Didn\'t try',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SettleSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quick log', style: SettleTypography.heading.copyWith(fontSize: 17, fontWeight: FontWeight.w700)),
          const SettleGap.xs(),
          Text(
            _outcomeLabel(widget.outcome),
            style: SettleTypography.body.copyWith(color: SettleColors.nightSoft),
          ),
          const SettleGap.lg(),
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              hintText: 'What happened? (optional)',
              hintStyle: SettleTypography.body.copyWith(
                color: SettleColors.nightMuted,
              ),
              filled: true,
              fillColor: SettleSurfaces.cardDark,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: SettleSurfaces.cardBorderDark),
              ),
            ),
            maxLines: 2,
            style: SettleTypography.body,
          ),
          const SettleGap.lg(),
          Row(
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: _regulationUsed,
                  onChanged: (v) =>
                      setState(() => _regulationUsed = v ?? false),
                  fillColor: WidgetStateProperty.resolveWith(
                    (_) => SettleSurfaces.cardDark,
                  ),
                  checkColor: SettleColors.nightAccent,
                ),
              ),
              const SizedBox(width: SettleSpacing.sm),
              Expanded(
                child: SettleTappable(
                  onTap: () =>
                      setState(() => _regulationUsed = !_regulationUsed),
                  semanticLabel: 'Toggle breathing reset used',
                  child: Text(
                    'I used the breathing reset',
                    style: SettleTypography.body.copyWith(
                      color: SettleColors.nightSoft,
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: SettleSpacing.lg + SettleSpacing.sm),
          SettleCta(
            label: _submitting ? 'Saving…' : 'Done',
            onTap: _submitting ? () {} : _submit,
          ),
        ],
      ),
    );
  }
}
