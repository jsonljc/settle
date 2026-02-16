import 'package:flutter/material.dart';

import '../theme/glass_components.dart';
import '../theme/settle_tokens.dart';

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

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ScenarioBadge(label: scenarioLabel),
          const SizedBox(height: 12),
          _LineBlock(label: 'Prevent', text: prevent, bold: true),
          const SizedBox(height: 8),
          Text(
            'Say',
            style: T.type.caption.copyWith(color: T.pal.textTertiary),
          ),
          const SizedBox(height: 2),
          Text(say, style: T.type.h3),
          const SizedBox(height: 8),
          _LineBlock(label: 'Do', text: doStep),
          if (ifEscalates != null && ifEscalates!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: EdgeInsets.zero,
              title: Text(
                'If escalates',
                style: T.type.label.copyWith(color: T.pal.textSecondary),
              ),
              iconColor: T.pal.textSecondary,
              collapsedIconColor: T.pal.textSecondary,
              shape: const RoundedRectangleBorder(side: BorderSide.none),
              collapsedShape: const RoundedRectangleBorder(
                side: BorderSide.none,
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      ifEscalates!,
                      style: T.type.body.copyWith(color: T.pal.textSecondary),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Divider(color: T.glass.border),
          const SizedBox(height: 10),
          GlassCta(label: 'Save to Playbook', onTap: onSave ?? () {}),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              GlassPill(label: 'Share with partner', onTap: onShare ?? () {}),
              GlassPill(label: 'Log how it went', onTap: onLog ?? () {}),
              GlassPill(label: 'See why this works', onTap: onWhy ?? () {}),
            ],
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
        borderRadius: BorderRadius.circular(T.radius.pill),
        color: T.glass.fillAccent,
      ),
      child: Text(
        label,
        style: T.type.caption.copyWith(
          color: T.pal.accent,
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
        Text(label, style: T.type.caption.copyWith(color: T.pal.textTertiary)),
        const SizedBox(height: 2),
        Text(
          text,
          style: T.type.body.copyWith(
            color: T.pal.textSecondary,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
