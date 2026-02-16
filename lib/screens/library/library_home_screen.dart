import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/screen_header.dart';

class LibraryHomeScreen extends StatelessWidget {
  const LibraryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ScreenHeader(
                  title: 'Library',
                  subtitle: 'Saved scripts, learning, and patterns.',
                  fallbackRoute: '/library',
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved playbook', style: T.type.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Your saved scripts will appear here as you build your playbook.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Learn', style: T.type.h3),
                      const SizedBox(height: 8),
                      Text(
                        'Review evidence-backed guidance.',
                        style: T.type.body.copyWith(color: T.pal.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      GlassCta(
                        label: 'Open learn',
                        onTap: () => context.push('/library/learn'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
