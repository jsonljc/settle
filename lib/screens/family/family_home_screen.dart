import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../models/family_member.dart';
import '../../providers/family_members_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/glass_components.dart';
import '../../theme/settle_tokens.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';
import 'activity_feed.dart';

class FamilyHomeScreen extends ConsumerStatefulWidget {
  const FamilyHomeScreen({super.key});

  @override
  ConsumerState<FamilyHomeScreen> createState() => _FamilyHomeScreenState();
}

class _FamilyHomeScreenState extends ConsumerState<FamilyHomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = ref.read(profileProvider);
      ref
          .read(familyMembersProvider.notifier)
          .ensureBackfillFromProfile(profile);
    });
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    final members = ref.watch(familyMembersProvider);

    if (profile == null) {
      return const ProfileRequiredView(title: 'Family');
    }

    final structure = profile.familyStructure;
    final isPartnerLayout =
        structure == FamilyStructure.twoParents ||
        structure == FamilyStructure.coParent ||
        structure == FamilyStructure.blended;

    return Scaffold(
      body: SettleBackground(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: T.space.screen),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ScreenHeader(
                    title: 'Family',
                    subtitle: 'Keep everyone aligned with the same scripts.',
                    fallbackRoute: '/family',
                  ),
                  const SizedBox(height: 12),
                  if (isPartnerLayout) ...[
                    _MembersSection(members: members),
                    const SizedBox(height: 12),
                  ] else ...[
                    GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your support network', style: T.type.h3),
                          const SizedBox(height: 6),
                          Text(
                            'Invite grandparents, babysitters, or other caregivers to stay on the same page.',
                            style: T.type.body.copyWith(
                              color: T.pal.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Shared playbook', style: T.type.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Open caregiver scripts and agreement notes.',
                          style: T.type.body.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCta(
                          label: 'Open shared scripts',
                          onTap: () => context.push('/family/shared'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite', style: T.type.h3),
                        const SizedBox(height: 8),
                        Text(
                          'Send an invite link so others can join your plan.',
                          style: T.type.body.copyWith(
                            color: T.pal.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassCta(
                          label: 'Get invite link',
                          onTap: () => context.push('/family/invite'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const ActivityFeedPreview(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  const _MembersSection({required this.members});

  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Family members', style: T.type.h3),
              GestureDetector(
                onTap: () => context.push('/family/invite'),
                child: Text(
                  'Invite',
                  style: T.type.label.copyWith(color: T.pal.accent),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            Text(
              'You\'ll appear here. Invite others to add them.',
              style: T.type.body.copyWith(color: T.pal.textSecondary),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...members.map((m) => _MemberChip(name: m.name, role: m.role)),
              ],
            ),
        ],
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.name, required this.role});

  final String name;
  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: T.glass.fillAccent,
        borderRadius: BorderRadius.circular(T.radius.pill),
        border: Border.all(color: T.glass.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: T.pal.accent.withValues(alpha: 0.3),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: T.type.label.copyWith(color: T.pal.accent),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: T.type.label),
              Text(
                role,
                style: T.type.caption.copyWith(color: T.pal.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
