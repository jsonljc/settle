import 'package:flutter/widgets.dart';

import '../theme/settle_design_system.dart';

/// Spacing widget that uses [SettleSpacing] tokens. Prefer over raw [SizedBox]
/// for consistent spacing and to avoid hardcoded magic numbers.
///
/// Creates a square [SizedBox] (height and width). In a [Column] it acts as
/// vertical spacing; in a [Row] as horizontal spacing.
///
/// Sizes: xs=4, sm=8, md=12, lg=16, xl=20, xxl=28 (System B).
class SettleGap extends StatelessWidget {
  final double size;
  const SettleGap.xs({super.key}) : size = SettleSpacing.xs;
  const SettleGap.sm({super.key}) : size = SettleSpacing.sm;
  const SettleGap.md({super.key}) : size = SettleSpacing.md;
  const SettleGap.lg({super.key}) : size = SettleSpacing.lg;
  const SettleGap.xl({super.key}) : size = SettleSpacing.xl;
  const SettleGap.xxl({super.key}) : size = SettleSpacing.xxl;

  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}
