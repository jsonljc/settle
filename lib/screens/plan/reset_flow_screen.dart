import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/repair_card.dart';
import '../../providers/reset_flow_provider.dart';
import '../../utils/share_text.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/calm_loading.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/settle_tappable.dart';

// Local tokens removed — using SettleTypography directly.

/// Reset flow: choose state (self/child) → repair card → Keep / Another (max 3) / Close.
/// Dark-mode reskin: 2 AM screen. Override to dark theme when night (9pm–5am).
class ResetFlowScreen extends ConsumerStatefulWidget {
  const ResetFlowScreen({super.key, this.contextQuery = 'general'});

  final String contextQuery;

  static RepairCardContext contextFromQuery(String? q) {
    switch ((q ?? 'general').trim().toLowerCase()) {
      case 'sleep':
        return RepairCardContext.sleep;
      case 'tantrum':
        return RepairCardContext.tantrum;
      default:
        return RepairCardContext.general;
    }
  }

  @override
  ConsumerState<ResetFlowScreen> createState() => _ResetFlowScreenState();
}

class _ResetFlowScreenState extends ConsumerState<ResetFlowScreen> {
  bool _showRegulationOffer = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final flowContext = ResetFlowScreen.contextFromQuery(widget.contextQuery);
      ref.read(resetFlowProvider.notifier).startSession(flowContext);
    });
  }

  /// 9pm–5am = night; force dark theme for this screen.
  static bool _isNightTime() {
    final hour = DateTime.now().hour;
    return hour >= 21 || hour < 5;
  }

  bool get _isTantrumContext =>
      ResetFlowScreen.contextFromQuery(widget.contextQuery) ==
      RepairCardContext.tantrum;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resetFlowProvider);
    final notifier = ref.read(resetFlowProvider.notifier);
    final useDark = _isNightTime();

    Widget body = Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: _showRegulationOffer
            ? _buildRegulationOffer(context)
            : state.phase == ResetFlowPhase.chooseState
                ? _buildStatePicker(context, notifier)
                : _buildCardView(context, state, notifier),
      ),
    );

    if (useDark) {
      body = Theme(data: SettleTheme.dark, child: body);
    }
    return body;
  }

  Widget _buildStatePicker(BuildContext context, ResetFlowNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.screenPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: 32),
          _ResetCharacterBlob(tantrumContext: _isTantrumContext),
          const SizedBox(height: 20),
          Text(
            'Who needs help right now?',
            textAlign: TextAlign.center,
            style: SettleTypography.body.copyWith(
              fontWeight: FontWeight.w600,
              color: SettleColors.nightText,
            ),
          ),
          const SizedBox(height: 20),
          SettleTappable(
            semanticLabel: 'Me',
            onTap: () => notifier.selectState(RepairCardState.self),
            child: GlassCard(
              variant: GlassCardVariant.darkStrong,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Me',
                    style: SettleTypography.display.copyWith(
                      fontWeight: FontWeight.w400,
                      color: SettleColors.nightText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: SettleSpacing.sm),
          SettleTappable(
            semanticLabel: 'My kid',
            onTap: () => notifier.selectState(RepairCardState.child),
            child: GlassCard(
              variant: GlassCardVariant.darkStrong,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'My kid',
                    style: SettleTypography.display.copyWith(
                      fontWeight: FontWeight.w400,
                      color: SettleColors.nightText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardView(
    BuildContext context,
    ResetFlowState state,
    ResetFlowNotifier notifier,
  ) {
    if (state.loading) {
      return const Center(child: CalmLoading(message: 'Preparing your reset…'));
    }

    final card = state.currentCard;
    final chosenState = state.chosenState;

    if (card == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SettleSpacing.screenPadding,
        ),
        child: Column(
          children: [
            const SizedBox(height: 32),
            _ResetCharacterBlob(tantrumContext: _isTantrumContext),
            const SizedBox(height: 24),
            Expanded(
              child: Center(
                child: GlassCard(
                  variant: GlassCardVariant.darkStrong,
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    'No card for this combination right now.',
                    style: SettleTypography.body.copyWith(
                      color: SettleColors.nightSoft,
                      height: 1.7,
                    ),
                  ),
                ),
              ),
            ),
            _buildCloseLink(notifier, null),
          ],
        ),
      );
    }

    // V2: Card = Acknowledgment (muted) + Words to say (large) + optional One thing to do
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.screenPadding,
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _ResetCharacterBlob(tantrumContext: _isTantrumContext),
          const SizedBox(height: 20),
          GlassCard(
            variant: GlassCardVariant.darkStrong,
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.title,
                  style: SettleTypography.caption.copyWith(
                    color: SettleColors.nightMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _maxSentences(card.body),
                  style: SettleTypography.display.copyWith(
                    color: SettleColors.nightText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          GlassPill(
            label: 'Keep',
            onTap: () => _keep(notifier, card.id),
            variant: GlassPillVariant.primaryDark,
            expanded: true,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _textLink('Copy', () => _copyCard(card)),
              Text(' · ', style: _linkStyle()),
              _textLink('Send', () => _share(card)),
              Text(' · ', style: _linkStyle()),
              if (state.canShowAnother)
                _textLink('Another', () => notifier.drawAnother())
              else
                Text('That\'s the set for now.', style: _linkStyle()),
              Text(' · ', style: _linkStyle()),
              _textLink('Done', () => _done(notifier, null)),
            ],
          ),
        ],
      ),
    );
  }

  TextStyle _linkStyle() =>
      SettleTypography.caption.copyWith(
        color: SettleColors.nightMuted.withValues(alpha: 0.8),
      );

  Widget _textLink(String label, VoidCallback onTap) {
    return SettleTappable(
      semanticLabel: label,
      onTap: onTap,
      child: Text(label, style: _linkStyle()),
    );
  }

  void _copyCard(RepairCard card) {
    Clipboard.setData(ClipboardData(text: '${card.title}\n\n${card.body}'));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  Future<void> _done(ResetFlowNotifier notifier, String? cardIdKept) async {
    await notifier.close(cardIdKept: cardIdKept);
    if (!mounted) return;
    setState(() => _showRegulationOffer = true);
  }

  Widget _buildRegulationOffer(BuildContext context) {
    final isSleepContext =
        ResetFlowScreen.contextFromQuery(widget.contextQuery) ==
            RepairCardContext.sleep;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: SettleSpacing.screenPadding,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Need a minute for yourself?',
            textAlign: TextAlign.center,
            style: SettleTypography.display.copyWith(
              fontWeight: FontWeight.w400,
              color: SettleColors.nightText,
            ),
          ),
          const SizedBox(height: 28),
          GlassPill(
            label: 'Breathe · 10s',
            onTap: () {
              context.push('/plan/moment');
              _exitFlow();
            },
            variant: GlassPillVariant.primaryDark,
            expanded: true,
          ),
          const SizedBox(height: 14),
          SettleTappable(
            semanticLabel: isSleepContext ? 'Back to sleep stuff' : 'I\'m good',
            onTap: _exitFlow,
            child: Text(
              isSleepContext ? 'Back to sleep stuff' : 'I\'m good',
              style: SettleTypography.body.copyWith(
                color: SettleColors.nightMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseLink(ResetFlowNotifier notifier, String? cardIdKept) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 16),
      child: Center(
        child: _textLink('Done', () => _done(notifier, cardIdKept)),
      ),
    );
  }

  Future<void> _keep(ResetFlowNotifier notifier, String cardIdKept) async {
    await notifier.keep();
    await notifier.close(cardIdKept: cardIdKept);
    if (!mounted) return;
    setState(() => _showRegulationOffer = true);
  }

  void _exitFlow() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/plan');
  }

  void _share(RepairCard card) {
    final text = buildCardShareText(card.title, card.body);
    Share.share(text);
  }

  String _maxSentences(String text, {int max = 3}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    final matches = RegExp(r'[^.!?]+(?:[.!?]|$)')
        .allMatches(trimmed)
        .map((m) => m.group(0)!.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (matches.length <= max) return trimmed;
    return matches.take(max).join(' ');
  }
}

/// 88px solid circle with simple face: nightAccent (or warmth for tantrum).
class _ResetCharacterBlob extends StatelessWidget {
  const _ResetCharacterBlob({this.tantrumContext = false});

  final bool tantrumContext;

  static const double _size = 88;

  Color get _tint =>
      tantrumContext ? SettleColors.warmth400 : SettleColors.nightAccent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _tint.withValues(alpha: 0.12),
          border: Border.all(
            color: _tint.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Center(
          child: CustomPaint(
            size: const Size(48, 48),
            painter: _ResetFacePainter(tint: _tint),
          ),
        ),
      ),
    );
  }
}

/// Simple face: two closed eyes (arcs), gentle smile (arc). stroke 1.8, tint (nightAccent or warmth).
class _ResetFacePainter extends CustomPainter {
  _ResetFacePainter({Color? tint}) : tint = tint ?? SettleColors.nightAccent;

  final Color tint;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = tint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Left eye: closed arc (horizontal), center ~(cx - 10, cy - 4)
    final leftEye = Path();
    leftEye.moveTo(cx - 14, cy - 4);
    leftEye.quadraticBezierTo(cx - 10, cy - 8, cx - 6, cy - 4);
    canvas.drawPath(leftEye, paint);

    // Right eye
    final rightEye = Path();
    rightEye.moveTo(cx + 6, cy - 4);
    rightEye.quadraticBezierTo(cx + 10, cy - 8, cx + 14, cy - 4);
    canvas.drawPath(rightEye, paint);

    // Smile: gentle arc below
    final smile = Path();
    smile.moveTo(cx - 10, cy + 6);
    smile.quadraticBezierTo(cx, cy + 14, cx + 10, cy + 6);
    canvas.drawPath(smile, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
