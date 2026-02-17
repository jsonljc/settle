import 'package:flutter/material.dart';

import 'script_card.dart';

/// Backward-compatible facade that now always renders V3 [ScriptCard].
class OutputCard extends StatelessWidget {
  const OutputCard({
    super.key,
    required this.scenarioLabel,
    required this.prevent,
    required this.say,
    required this.doStep,
    this.ifEscalates,
    this.onSave,
    this.onShare,
    this.onLog,
    this.onWhy,
    this.context = ScriptCardContext.plan,
    this.primaryLabel,
    this.onPrimary,
    this.primaryEnabled = true,
    this.initialStage = ScriptCardStage.summary,
  });

  final String scenarioLabel;
  final String prevent;
  final String say;
  final String doStep;
  final String? ifEscalates;
  final VoidCallback? onSave;
  final VoidCallback? onShare;
  final VoidCallback? onLog;
  final VoidCallback? onWhy;
  final ScriptCardContext context;
  final String? primaryLabel;
  final VoidCallback? onPrimary;
  final bool primaryEnabled;
  final ScriptCardStage initialStage;

  @override
  Widget build(BuildContext context) {
    return ScriptCard(
      scenarioLabel: scenarioLabel,
      prevent: prevent,
      say: say,
      doStep: doStep,
      ifEscalates: ifEscalates,
      context: this.context,
      initialStage: initialStage,
      primaryLabel: primaryLabel,
      onPrimary: onPrimary ?? onSave,
      primaryEnabled: primaryEnabled,
      onSave: onSave,
      onShare: onShare,
      onLog: onLog,
      onWhy: onWhy,
    );
  }
}
