import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/settle_tokens.dart';

/// Glass-style FAB for Pocket — bottom-right, above bottom nav.
/// Used inside [PocketFABAndOverlay] which handles tap and modal.
class PocketFAB extends StatelessWidget {
  const PocketFAB({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  static const double _size = 56;
  static const double _blurSigma = 12;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    const navBarHeight = 64.0;
    const fabMargin = 16.0;
    final top = MediaQuery.of(context).size.height -
        bottomPadding -
        navBarHeight -
        _size -
        fabMargin;

    return Positioned(
      top: top,
      right: fabMargin,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_size / 2),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: T.glass.fill.withValues(alpha: 0.9),
                border: Border.all(color: T.glass.border, width: 1),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: T.pal.accent,
                size: 28,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
