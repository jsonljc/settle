import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../theme/settle_design_system.dart';
import 'settle_gap.dart';

/// Standard bottom sheet content: solid surface, handle bar, optional title and
/// actions. Use with [showSettleSheet].
class SettleModalSheet extends StatelessWidget {
  const SettleModalSheet({
    super.key,
    this.title,
    required this.body,
    this.primaryAction,
    this.secondaryAction,
    this.contentPadding,
  });

  final String? title;
  final Widget body;
  final Widget? primaryAction;
  final Widget? secondaryAction;
  final EdgeInsets? contentPadding;

  @override
  Widget build(BuildContext context) {
    final padding =
        contentPadding ??
        const EdgeInsets.symmetric(
          horizontal: SettleSpacing.md,
          vertical: SettleSpacing.lg,
        );

    final sheetBody = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: SettleSpacing.sm),
          child: Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: SettleColors.nightMuted.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: padding,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null) ...[
                  Semantics(
                    header: true,
                    child: Text(title!, style: SettleTypography.heading),
                  ),
                  SettleGap.md(),
                ],
                body,
                if (primaryAction != null || secondaryAction != null) ...[
                  SettleGap.xl(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (secondaryAction != null) ...[
                        secondaryAction!,
                        SettleGap.sm(),
                      ],
                      if (primaryAction != null) primaryAction!,
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget content = Container(
      decoration: BoxDecoration(
        color: isDark ? SettleColors.night800 : Colors.white,
        borderRadius: BorderRadius.circular(SettleRadii.card),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: sheetBody,
    );

    if (title != null && title!.isNotEmpty) {
      content = _AnnounceOnOpen(message: title!, child: content);
    }

    return Semantics(liveRegion: true, child: content);
  }
}

/// Announces [message] to screen readers once when first built.
class _AnnounceOnOpen extends StatefulWidget {
  const _AnnounceOnOpen({required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<_AnnounceOnOpen> createState() => _AnnounceOnOpenState();
}

class _AnnounceOnOpenState extends State<_AnnounceOnOpen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        SemanticsService.announce(widget.message, TextDirection.ltr);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Shows a bottom sheet with standard Settle styling (transparent background,
/// scroll-controlled). Wrap content in [SettleModalSheet] for handle, solid
/// surface, and padding.
Future<TResult?> showSettleSheet<TResult>(
  BuildContext context, {
  required Widget child,
}) {
  return showModalBottomSheet<TResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          SettleSpacing.screenPadding,
          SettleSpacing.md,
          SettleSpacing.screenPadding,
          SettleSpacing.screenPadding + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: child,
      ),
    ),
  );
}
