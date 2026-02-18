import 'package:flutter/material.dart';

import '../theme/glass_components.dart';
import '../theme/settle_design_system.dart';
import 'settle_disclosure.dart';
import 'settle_gap.dart';
import 'settle_modal_sheet.dart';

enum ScriptCardContext { plan, pocket, onboarding, detail, crisis }

enum ScriptCardStage { summary, action }

class ScriptCard extends StatefulWidget {
  const ScriptCard({
    super.key,
    required this.scenarioLabel,
    required this.prevent,
    required this.say,
    required this.doStep,
    this.ifEscalates,
    this.context = ScriptCardContext.plan,
    this.initialStage = ScriptCardStage.summary,
    this.onStageChanged,
    this.primaryLabel,
    this.primaryEnabled = true,
    this.onPrimary,
    this.onSave,
    this.onShare,
    this.onLog,
    this.onWhy,
    this.showScenarioBadge = true,
  });

  final String scenarioLabel;
  final String prevent;
  final String say;
  final String doStep;
  final String? ifEscalates;

  final ScriptCardContext context;
  final ScriptCardStage initialStage;
  final ValueChanged<ScriptCardStage>? onStageChanged;

  final String? primaryLabel;
  final bool primaryEnabled;
  final VoidCallback? onPrimary;

  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onLog;
  final VoidCallback? onWhy;
  final bool showScenarioBadge;

  @override
  State<ScriptCard> createState() => _ScriptCardState();
}

class _ScriptCardState extends State<ScriptCard> {
  late ScriptCardStage _stage = widget.initialStage;

  bool get _isCrisisLike =>
      widget.context == ScriptCardContext.pocket ||
      widget.context == ScriptCardContext.crisis;

  bool get _hasOverflowActions =>
      widget.onSave != null ||
      widget.onShare != null ||
      widget.onLog != null ||
      widget.onWhy != null;

  @override
  void didUpdateWidget(covariant ScriptCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStage != widget.initialStage) {
      _stage = widget.initialStage;
    }
  }

  void _setStage(ScriptCardStage stage) {
    if (_stage == stage) return;
    setState(() => _stage = stage);
    widget.onStageChanged?.call(stage);
  }

  String _resolvedPrimaryLabel() {
    if (widget.primaryLabel != null && widget.primaryLabel!.trim().isNotEmpty) {
      return widget.primaryLabel!;
    }
    if (_isCrisisLike) {
      return _stage == ScriptCardStage.summary ? 'I said it →' : 'Done';
    }
    return switch (widget.context) {
      ScriptCardContext.plan => 'Save to Playbook',
      ScriptCardContext.onboarding => 'Save to My Playbook',
      ScriptCardContext.detail => 'Done',
      ScriptCardContext.pocket =>
        _stage == ScriptCardStage.summary ? 'I said it →' : 'Done',
      ScriptCardContext.crisis =>
        _stage == ScriptCardStage.summary ? 'I said it →' : 'Done',
    };
  }

  void _onPrimaryPressed() {
    if (_isCrisisLike && _stage == ScriptCardStage.summary) {
      _setStage(ScriptCardStage.action);
      return;
    }
    widget.onPrimary?.call();
  }

  Future<void> _openActionsSheet() async {
    if (!_hasOverflowActions) return;
    await showSettleSheet<void>(
      context,
      child: SettleModalSheet(
        title: 'More actions',
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.onSave != null) ...[
              GlassPill(
                label: 'Save to Playbook',
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onSave?.call();
                },
              ),
              SettleGap.sm(),
            ],
            if (widget.onShare != null) ...[
              GlassPill(
                label: 'Send to partner',
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onShare?.call();
                },
              ),
              SettleGap.sm(),
            ],
            if (widget.onLog != null) ...[
              GlassPill(
                label: 'Log how it went',
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onLog?.call();
                },
              ),
              SettleGap.sm(),
            ],
            if (widget.onWhy != null)
              GlassPill(
                label: 'See why this works',
                onTap: () {
                  Navigator.of(context).pop();
                  widget.onWhy?.call();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final escalates = widget.ifEscalates?.trim() ?? '';
    final hasEscalates = escalates.isNotEmpty;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.showScenarioBadge)
                _ScenarioBadge(label: widget.scenarioLabel),
              const Spacer(),
              if (_hasOverflowActions)
                IconButton(
                  onPressed: _openActionsSheet,
                  icon: Icon(
                    Icons.more_horiz_rounded,
                    color: SettleColors.nightSoft,
                  ),
                  tooltip: 'More actions',
                ),
            ],
          ),
          if (_stage == ScriptCardStage.summary && !_isCrisisLike) ...[
            _LineBlock(label: 'Prevent', text: widget.prevent, bold: true),
            SettleGap.sm(),
            GestureDetector(
              onTap: () => _setStage(ScriptCardStage.action),
              child: Text(
                'Show script details',
                style: SettleTypography.caption.copyWith(
                  color: SettleColors.nightSoft,
                  decoration: TextDecoration.underline,
                  decorationColor: SettleColors.nightSoft,
                ),
              ),
            ),
          ],
          if (_stage == ScriptCardStage.summary && _isCrisisLike) ...[
            Text(
              'Say',
              style: SettleTypography.caption.copyWith(
                color: SettleColors.nightMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(widget.say, style: SettleTypography.heading),
          ],
          if (_stage == ScriptCardStage.action) ...[
            Text(
              'Say',
              style: SettleTypography.caption.copyWith(
                color: SettleColors.nightMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(widget.say, style: SettleTypography.heading),
            const SizedBox(height: 10),
            _LineBlock(label: 'Do', text: widget.doStep),
            if (_isCrisisLike) ...[
              const SizedBox(height: 10),
              SettleDisclosure(
                title: 'Plan for next time',
                subtitle: 'Optional prevention cue',
                children: [
                  SettleGap.sm(),
                  Text(
                    widget.prevent,
                    style: SettleTypography.body.copyWith(
                      color: SettleColors.nightSoft,
                    ),
                  ),
                ],
              ),
            ],
            if (hasEscalates) ...[
              const SizedBox(height: 10),
              SettleDisclosure(
                title: 'If escalates',
                children: [
                  SettleGap.sm(),
                  Text(
                    escalates,
                    style: SettleTypography.body.copyWith(
                      color: SettleColors.nightSoft,
                    ),
                  ),
                ],
              ),
            ],
          ],
          SettleGap.md(),
          GlassCta(
            label: _resolvedPrimaryLabel(),
            onTap: _onPrimaryPressed,
            enabled:
                _isCrisisLike ||
                (widget.primaryEnabled && widget.onPrimary != null),
          ),
        ],
      ),
    );
  }
}

class _ScenarioBadge extends StatelessWidget {
  const _ScenarioBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SettleRadii.pill),
        color: SettleColors.dusk600.withValues(alpha: 0.16),
      ),
      child: Text(
        label,
        style: SettleTypography.caption.copyWith(
          color: SettleColors.nightText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LineBlock extends StatelessWidget {
  const _LineBlock({
    required this.label,
    required this.text,
    this.bold = false,
  });

  final String label;
  final String text;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: SettleTypography.caption.copyWith(
            color: SettleColors.nightMuted,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          text,
          style: SettleTypography.body.copyWith(
            color: SettleColors.nightSoft,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
