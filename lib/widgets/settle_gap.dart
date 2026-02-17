import 'package:flutter/widgets.dart';

import '../theme/settle_tokens.dart';

/// Spacing widget that uses [T.space] tokens. Prefer over raw [SizedBox] for
/// consistent spacing and to avoid hardcoded magic numbers.
///
/// Creates a square [SizedBox] (height and width). In a [Column] it acts as
/// vertical spacing; in a [Row] as horizontal spacing.
///
/// Sizes match [T.space] tokens (xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, xxxl=32).
/// Constructors are not const because [T.space] getters are not compile-time constant.
class SettleGap extends StatelessWidget {
  final double size;
  SettleGap.xs({super.key}) : size = T.space.xs;
  SettleGap.sm({super.key}) : size = T.space.sm;
  SettleGap.md({super.key}) : size = T.space.md;
  SettleGap.lg({super.key}) : size = T.space.lg;
  SettleGap.xl({super.key}) : size = T.space.xl;
  SettleGap.xxl({super.key}) : size = T.space.xxl;
  SettleGap.xxxl({super.key}) : size = T.space.xxxl;

  @override
  Widget build(BuildContext context) => SizedBox(height: size, width: size);
}
