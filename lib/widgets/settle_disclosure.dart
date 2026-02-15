import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Drop-in replacement for the `Theme(dividerColor: transparent) +
/// ExpansionTile(tilePadding: zero, childrenPadding: zero, …)` pattern
/// used throughout the app.
///
/// Renders a subtle chevron, consistent padding, and no divider hack.
class SettleDisclosure extends StatefulWidget {
  const SettleDisclosure({
    super.key,
    required this.title,
    this.titleStyle,
    this.subtitle,
    this.initiallyExpanded = false,
    required this.children,
  });

  final String title;

  /// Override the default title style (`T.type.label`).
  final TextStyle? titleStyle;
  final String? subtitle;
  final bool initiallyExpanded;
  final List<Widget> children;

  @override
  State<SettleDisclosure> createState() => _SettleDisclosureState();
}

class _SettleDisclosureState extends State<SettleDisclosure>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;
  late final AnimationController _controller = AnimationController(
    duration: T.anim.normal,
    vsync: this,
    value: _expanded ? 1.0 : 0.0,
  );
  late final Animation<double> _iconTurn = Tween<double>(
    begin: 0.0,
    end: 0.5,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  late final Animation<double> _heightFactor = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeInOut,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.of(context).disableAnimations;
    _controller.duration = reduced ? Duration.zero : T.anim.normal;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggle,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title, style: widget.titleStyle ?? T.type.label),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: T.type.caption.copyWith(
                          color: T.pal.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              RotationTransition(
                turns: _iconTurn,
                child: Icon(
                  Icons.expand_more_rounded,
                  size: 20,
                  color: T.pal.textSecondary,
                ),
              ),
            ],
          ),
        ),
        AnimatedBuilder(
          animation: _heightFactor,
          builder: (context, child) {
            if (_heightFactor.value == 0.0) return const SizedBox.shrink();
            return ClipRect(
              child: Align(
                alignment: Alignment.topLeft,
                heightFactor: _heightFactor.value,
                child: child,
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: widget.children,
          ),
        ),
      ],
    );
  }
}
