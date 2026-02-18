import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/moment_script_repository.dart';
import '../../models/moment_script.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/settle_tappable.dart';

class _MfT {
  _MfT._();

  static final type = _MfTypeTokens();
  static const glass = _MfGlassTokens();
}

class _MfTypeTokens {
  TextStyle get h1 => SettleTypography.heading.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
  );
  TextStyle get h2 => SettleTypography.heading.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
  );
  TextStyle get caption => SettleTypography.caption.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
  );
}

class _MfGlassTokens {
  const _MfGlassTokens();

  Color get fillDay => const Color(0x2AFFFFFF);
}

/// Moment — the fastest screen in the app.
///
/// Reskin: SettleGradients.moment + white blob; breath ring (glass sphere);
/// calm → choice (Boundary/Connection) → script. Completable in <10s.
class MomentFlowScreen extends ConsumerStatefulWidget {
  const MomentFlowScreen({super.key, this.contextQuery = 'general'});

  final String contextQuery;

  @override
  ConsumerState<MomentFlowScreen> createState() => _MomentFlowScreenState();
}

enum _MomentPhase { calm, choice, script }

class _MomentFlowScreenState extends ConsumerState<MomentFlowScreen> {
  _MomentPhase _phase = _MomentPhase.calm;
  List<MomentScript> _scripts = const [];
  MomentScript? _selectedScript;
  bool _scriptsLoading = true;
  bool _resetLinkVisible = false;
  Timer? _calmTimer;
  Timer? _hapticTimer;
  Timer? _resetLinkTimer;

  static const _calmDurationSeconds = 10;

  @override
  void initState() {
    super.initState();
    _loadScripts();
    _startCalmPhase();
  }

  Future<void> _loadScripts() async {
    final scripts = await MomentScriptRepository.instance.loadAll();
    if (mounted) {
      setState(() {
        _scripts = scripts;
        _scriptsLoading = false;
      });
    }
  }

  void _startCalmPhase() {
    _hapticTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) HapticFeedback.selectionClick();
    });
    _calmTimer = Timer(const Duration(seconds: _calmDurationSeconds), () {
      if (mounted) _advanceToChoice();
    });
  }

  void _skipCalm() {
    _calmTimer?.cancel();
    _hapticTimer?.cancel();
    _advanceToChoice();
  }

  void _advanceToChoice() {
    _calmTimer?.cancel();
    _hapticTimer?.cancel();
    setState(() => _phase = _MomentPhase.choice);
  }

  void _onScriptSelected(MomentScript script) {
    setState(() {
      _selectedScript = script;
      _phase = _MomentPhase.script;
    });
    _resetLinkTimer = Timer(const Duration(seconds: 1), () {
      if (mounted) setState(() => _resetLinkVisible = true);
    });
  }

  void _close() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/plan');
    }
  }

  void _openReset() {
    final ctx = (widget.contextQuery.trim().toLowerCase()).isEmpty
        ? 'general'
        : widget.contextQuery;
    if (context.canPop()) {
      context.pop();
    }
    context.push('/plan/reset?context=$ctx');
  }

  @override
  void dispose() {
    _calmTimer?.cancel();
    _hapticTimer?.cancel();
    _resetLinkTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _MomentPhase.calm:
        return _buildCalmStep();
      case _MomentPhase.choice:
        return _buildChoiceStep();
      case _MomentPhase.script:
        return _buildScriptStep();
    }
  }

  Widget _buildCalmStep() {
    return SettleTappable(
      semanticLabel: 'Calm. Double tap to skip to choices.',
      onTap: _skipCalm,
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildRingAndText(),
          const Spacer(),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildChoiceStep() {
    return Column(
      children: [
        const SizedBox(height: 24),
        _buildRingAndText(),
        const SizedBox(height: 28),
        Expanded(child: _buildChoiceContent()),
        _buildFooter(),
      ],
    );
  }

  Widget _buildRingAndText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _MomentBreathRing(),
        const SizedBox(height: 24),
        Text(
          'Place one hand on your chest',
          textAlign: TextAlign.center,
          style: _MfT.type.h1.copyWith(
            fontWeight: FontWeight.w400,
            color: SettleColors.ink900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "You're here now. That's enough.",
          textAlign: TextAlign.center,
          style: _MfT.type.caption.copyWith(
            color: SettleColors.ink500.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceContent() {
    if (_scriptsLoading || _scripts.isEmpty) {
      return Center(
        child: Text(
          'Loading…',
          style: SettleTypography.body.copyWith(color: SettleColors.ink500),
        ),
      );
    }

    MomentScript? boundary;
    MomentScript? connection;
    for (final s in _scripts) {
      if (s.variant == MomentScriptVariant.boundary) boundary ??= s;
      if (s.variant == MomentScriptVariant.connection) connection ??= s;
    }

    final boundaryScript = boundary;
    final connectionScript = connection;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.screenPadding,
      ),
      child: Row(
        children: [
          if (boundaryScript != null)
            Expanded(
              child: _MomentChoiceCard(
                icon: Icons.square_rounded,
                iconColor: SettleColors.sage600,
                title: 'Boundary',
                subtitle: 'Hold the line',
                onTap: () => _onScriptSelected(boundaryScript),
              ),
            ),
          if (boundaryScript != null && connectionScript != null)
            const SizedBox(width: 10),
          if (connectionScript != null)
            Expanded(
              child: _MomentChoiceCard(
                icon: Icons.favorite_rounded,
                iconColor: SettleColors.blush600,
                title: 'Connection',
                subtitle: 'Come closer',
                onTap: () => _onScriptSelected(connectionScript),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        SettleSpacing.screenPadding,
        12,
        SettleSpacing.screenPadding,
        16,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SettleTappable(
            semanticLabel: 'Close',
            onTap: _close,
            child: Text(
              'Close',
              style: SettleTypography.caption.copyWith(
                color: SettleColors.ink400.withValues(alpha: 0.6),
              ),
            ),
          ),
          Text(
            ' · ',
            style: SettleTypography.caption.copyWith(
              color: SettleColors.ink400.withValues(alpha: 0.6),
            ),
          ),
          SettleTappable(
            semanticLabel: 'Need more? Open Reset',
            onTap: _openReset,
            child: Text(
              'Need more? Reset →',
              style: SettleTypography.caption.copyWith(
                color: SettleColors.ink400.withValues(alpha: 0.6),
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScriptStep() {
    final script = _selectedScript;
    if (script == null) return const SizedBox.shrink();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.screenPadding,
          ),
          child: Text(
            script.lines.join(' '),
            textAlign: TextAlign.center,
            style: _MfT.type.h2.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: SettleColors.ink900,
            ),
          ),
        ),
        const SizedBox(height: 28),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: SettleSpacing.screenPadding,
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _close,
              style: FilledButton.styleFrom(
                backgroundColor: SettleColors.sage600,
                foregroundColor: SettleColors.cream,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Close'),
            ),
          ),
        ),
        if (_resetLinkVisible) ...[
          const SizedBox(height: 16),
          SettleTappable(
            semanticLabel: 'Need more? Open Reset flow',
            onTap: _openReset,
            child: Text(
              'Need more? → Reset (15s)',
              style: _MfT.type.caption.copyWith(
                color: SettleColors.ink500,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Breath ring: 120px glass sphere, specular arc, inner shadows, 32px circle icon, pulse animation.
class _MomentBreathRing extends StatefulWidget {
  @override
  State<_MomentBreathRing> createState() => _MomentBreathRingState();
}

class _MomentBreathRingState extends State<_MomentBreathRing>
    with SingleTickerProviderStateMixin {
  static const double _size = 120;
  static const double _blurSigma = 32;
  static const Duration _pulseDuration = Duration(milliseconds: 4500);

  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _pulseDuration, vsync: this)
      ..repeat(reverse: true);
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final ring = _buildRingContent();

    if (reduceMotion) {
      return ring;
    }
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(scale: _scale.value, child: child);
      },
      child: ring,
    );
  }

  Widget _buildRingContent() {
    return SizedBox(
      width: _size,
      height: _size,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Base: glass fill, border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _MfT.glass.fillDay,
                  border: Border.all(
                    color: SettleGlassLight.border,
                    width: 0.5,
                  ),
                ),
              ),
              // Inner shadow overlay: top highlight, bottom depth
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      SettleGlassLight.border,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.03),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
              // Specular arc: top 45% of circle
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  height: _size * 0.45,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SettleGlassLight.backgroundSubtle,
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Circle icon inside: 32px stroke ink700
              Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                    border: Border.all(color: SettleColors.ink700, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Choice card: icon 26px, title 14 w600, subtitle 10.5 ink400. GlassCard lightStrong, padding 20 top 16 bottom.
class _MomentChoiceCard extends StatelessWidget {
  const _MomentChoiceCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SettleTappable(
      onTap: onTap,
      semanticLabel: '$title. $subtitle',
      child: GlassCard(
        variant: GlassCardVariant.lightStrong,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 26, color: iconColor),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: SettleTypography.body.copyWith(
                fontWeight: FontWeight.w600,
                color: SettleColors.ink900,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: SettleTypography.caption.copyWith(
                color: SettleColors.ink400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
