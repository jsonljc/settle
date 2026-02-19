import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/settle_design_system.dart';
import 'glass_card.dart';

/// Short celebratory moment after "worked great" — dismiss by tap or after [duration].
class MicroCelebration extends StatefulWidget {
  const MicroCelebration({
    super.key,
    this.message = 'That worked. Small win.',
    this.duration = const Duration(seconds: 2),
    required this.onDismiss,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<MicroCelebration> createState() => _MicroCelebrationState();
}

class _MicroCelebrationState extends State<MicroCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entryController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    HapticFeedback.mediumImpact();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOutBack),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryController, curve: Curves.easeOut),
    );
    _entryController.forward();

    Future.delayed(widget.duration, () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (SettleAnimations.reduceMotion(context)) {
      _entryController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor = SettleSemanticColors.accent(context);

    return GestureDetector(
      onTap: widget.onDismiss,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SettleSpacing.screenPadding,
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(SettleRadii.glass),
                  boxShadow: [
                    BoxShadow(
                      color: SettleColors.sage400.withValues(alpha: 0.12),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: GlassCard(
                  variant: isDark
                      ? GlassCardVariant.darkStrong
                      : GlassCardVariant.lightStrong,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.celebration_rounded,
                        size: 40,
                        color: accentColor,
                      ),
                      const SizedBox(height: SettleSpacing.md),
                      Text(
                        widget.message,
                        style: SettleTypography.subheading.copyWith(
                          color: SettleSemanticColors.headline(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: SettleSpacing.xs),
                      Text(
                        'Tap to close',
                        style: SettleTypography.caption.copyWith(
                          color: SettleSemanticColors.muted(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
