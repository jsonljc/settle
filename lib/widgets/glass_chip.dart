import 'package:flutter/material.dart';

import '../theme/settle_design_system.dart';

/// Domain for chip tint (general/child → sage, self → blush, sleep → dusk, tantrum → warmth).
enum GlassChipDomain {
  general,
  self,
  sleep,
  tantrum,
  child,
}

/// Small pill chip with domain tint: 10% fill, 15% border, domain 600 text.
class GlassChip extends StatelessWidget {
  const GlassChip({
    super.key,
    required this.label,
    required this.domain,
  });

  final String label;
  final GlassChipDomain domain;

  static const EdgeInsets _padding =
      EdgeInsets.symmetric(vertical: 4, horizontal: 12);

  (Color fill, Color border, Color text) _resolveColors() {
    final (Color base, Color text600) = _domainColors();
    return (
      base.withValues(alpha: 0.10),
      base.withValues(alpha: 0.15),
      text600,
    );
  }

  (Color, Color) _domainColors() {
    switch (domain) {
      case GlassChipDomain.general:
      case GlassChipDomain.child:
        return (SettleColors.sage600, SettleColors.sage600);
      case GlassChipDomain.self:
        return (SettleColors.blush600, SettleColors.blush600);
      case GlassChipDomain.sleep:
        return (SettleColors.dusk600, SettleColors.dusk600);
      case GlassChipDomain.tantrum:
        return (SettleColors.warmth600, SettleColors.warmth600);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (fill, border, textColor) = _resolveColors();

    return Container(
      padding: _padding,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(SettleRadii.pill),
        border: Border.all(color: border, width: 0.5),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: SettleTypography.overline.copyWith(
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }
}
