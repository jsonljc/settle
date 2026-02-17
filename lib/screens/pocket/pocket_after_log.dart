import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/v2_enums.dart';
import '../../providers/usage_events_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';

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
      padding: EdgeInsets.symmetric(horizontal: T.space.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Quick log', style: T.type.h3),
          const SizedBox(height: 6),
          Text(
            _outcomeLabel(widget.outcome),
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _contextController,
            decoration: InputDecoration(
              hintText: 'What happened? (optional)',
              hintStyle: T.type.body.copyWith(color: T.pal.textTertiary),
              filled: true,
              fillColor: T.glass.fill,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(T.radius.md),
                borderSide: BorderSide(color: T.glass.border),
              ),
            ),
            maxLines: 2,
            style: T.type.body,
          ),
          const SizedBox(height: 16),
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
                    (_) => T.glass.fill,
                  ),
                  checkColor: T.pal.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _regulationUsed = !_regulationUsed),
                  child: Text(
                    'I used the breathing reset',
                    style: T.type.body.copyWith(color: T.pal.textSecondary),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GlassCta(
            label: _submitting ? 'Saving…' : 'Done',
            onTap: _submitting ? () {} : _submit,
          ),
        ],
      ),
    );
  }
}
