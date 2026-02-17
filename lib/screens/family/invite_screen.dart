import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

/// Invite flow MVP: copy invite link (deep link). No backend delivery yet.
class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});

  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  bool _copied = false;

  /// Generate a deep link that opens the app (e.g. to /family). Actual delivery deferred to backend.
  String get _inviteLink {
    return 'https://settle.app/join?ref=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _inviteLink));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const ScreenHeader(
                  title: 'Invite',
                  subtitle: 'Add caregivers to your plan.',
                  fallbackRoute: '/family',
                ),
                const SizedBox(height: 20),
                Text(
                  'They\'ll be included in your plan and can see the same scripts you use.',
                  style: T.type.body.copyWith(color: T.pal.textSecondary),
                ),
                const SizedBox(height: 24),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Invite link',
                        style: T.type.label.copyWith(color: T.pal.textTertiary),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        _inviteLink,
                        style: T.type.body.copyWith(
                          color: T.pal.textPrimary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GlassCta(
                        label: _copied ? 'Copied!' : 'Copy link',
                        onTap: _copyLink,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Share this link by message or email. When they open it, they can join your plan. (Delivery and sign-up flow coming soon.)',
                  style: T.type.caption.copyWith(color: T.pal.textTertiary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
