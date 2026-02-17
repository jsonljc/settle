import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/moment_script_repository.dart';
import '../../models/moment_script.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/settle_gap.dart';
import '../../widgets/settle_tappable.dart';

/// Moment — the fastest screen in the app.
///
/// Flow: 10-second calm (tap to skip) → Boundary/Connection choice → Script + Close.
/// Below Close: "Need more? → Reset (15s)" link.
/// Usable start-to-finish in ≤ 10 seconds.
class MomentFlowScreen extends ConsumerStatefulWidget {
  const MomentFlowScreen({
    super.key,
    this.contextQuery = 'general',
  });

  /// Route query: general, sleep, tantrum. Used for Reset link.
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
      backgroundColor: T.pal.focusBackground,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: T.space.screen),
          child: _buildBody(),
        ),
      ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SettleTappable(
            semanticLabel: 'Back',
            onTap: _close,
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: T.pal.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: SettleTappable(
            semanticLabel: '10 second calm. Double tap to skip to script choices.',
            onTap: _skipCalm,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '10 seconds',
                  style: T.type.caption.copyWith(color: T.pal.textTertiary),
                ),
                SettleGap.xxxl(),
                _CalmPulse(),
                SettleGap.xxxl(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: SettleTappable(
            semanticLabel: 'Back',
            onTap: _close,
            child: Icon(
              Icons.arrow_back_ios_rounded,
              size: 20,
              color: T.pal.textTertiary,
            ),
          ),
        ),
        Expanded(
          child: _buildChoiceContent(),
        ),
      ],
    );
  }

  Widget _buildChoiceContent() {
    if (_scriptsLoading || _scripts.isEmpty) {
      return Center(
        child: Text(
          'Loading…',
          style: T.type.body.copyWith(color: T.pal.textSecondary),
        ),
      );
    }

    MomentScript? boundary;
    MomentScript? connection;
    for (final s in _scripts) {
      if (s.variant == MomentScriptVariant.boundary) boundary ??= s;
      if (s.variant == MomentScriptVariant.connection) connection ??= s;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettleGap.xxl(),
        if (boundary != null)
          _ScriptTile(
            label: 'Boundary',
            script: boundary!,
            onTap: () => _onScriptSelected(boundary!),
          ),
        if (boundary != null && connection != null) SettleGap.md(),
        if (connection != null)
          _ScriptTile(
            label: 'Connection',
            script: connection!,
            onTap: () => _onScriptSelected(connection!),
          ),
        const Spacer(),
      ],
    );
  }

  Widget _buildScriptStep() {
    final script = _selectedScript;
    if (script == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          script.lines.join(' '),
          style: T.type.h2.copyWith(
            color: T.pal.textPrimary,
            height: 1.35,
          ),
        ),
        SettleGap.xxl(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _close,
            style: FilledButton.styleFrom(
              backgroundColor: T.pal.accent,
              foregroundColor: T.pal.focusBackground,
              padding: EdgeInsets.symmetric(
                vertical: T.space.lg,
                horizontal: T.space.xl,
              ),
            ),
            child: const Text('Close'),
          ),
        ),
        if (_resetLinkVisible) ...[
          SettleGap.xl(),
          GestureDetector(
            onTap: _openReset,
            child: Text(
              'Need more? → Reset (15s)',
              style: T.type.caption.copyWith(
                color: T.pal.textTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CalmPulse extends StatefulWidget {
  @override
  State<_CalmPulse> createState() => _CalmPulseState();
}

class _CalmPulseState extends State<_CalmPulse>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (T.reduceMotion(context)) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: T.pal.textTertiary.withValues(alpha: 0.15),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        return Transform.scale(
          scale: _scale.value,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: T.pal.textTertiary.withValues(alpha: 0.15),
            ),
          ),
        );
      },
    );
  }
}

class _ScriptTile extends StatelessWidget {
  const _ScriptTile({
    required this.label,
    required this.script,
    required this.onTap,
  });

  final String label;
  final MomentScript script;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final firstLine = script.lines.isNotEmpty ? script.lines.first : '';
    return SettleTappable(
      semanticLabel: '$label: $firstLine',
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          vertical: T.space.xl,
          horizontal: T.space.lg,
        ),
        decoration: BoxDecoration(
          color: T.glass.fill.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(T.radius.md),
          border: Border.all(color: T.glass.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: T.type.h3.copyWith(color: T.pal.textPrimary),
            ),
            SettleGap.sm(),
            Text(
              firstLine,
              style: T.type.body.copyWith(color: T.pal.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
