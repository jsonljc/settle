import 'package:flutter/material.dart';

import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';

class PrepNudgeSection extends StatelessWidget {
  const PrepNudgeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Prep', style: T.type.h3),
          const SizedBox(height: 6),
          Text(
            'You tend to hit friction near bedtime. Preview a script now to make the moment easier.',
            style: T.type.body.copyWith(color: T.pal.textSecondary),
          ),
        ],
      ),
    );
  }
}
