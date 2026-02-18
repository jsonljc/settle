import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/approach.dart';
import '../../models/family_member.dart';
import '../../providers/family_members_provider.dart';
import '../../providers/profile_provider.dart';
import '../../theme/settle_design_system.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/glass_pill.dart';
import '../../widgets/release_surfaces.dart';
import '../../widgets/screen_header.dart';
import '../../widgets/settle_tappable.dart';
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
      body: GradientBackgroundFromRoute(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SettleSpacing.screenPadding,
            ),
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
                          Text(
                            'Your support network',
                            style: SettleTypography.heading,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Invite grandparents, babysitters, or other caregivers to stay on the same page.',
                            style: SettleTypography.body.copyWith(
                              color: _supportingTextColor(context),
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
                        Text(
                          'Shared playbook',
                          style: SettleTypography.heading,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Open caregiver scripts and agreement notes.',
                          style: SettleTypography.body.copyWith(
                            color: _supportingTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassPill(
                          label: 'Open shared scripts',
                          onTap: () => context.push('/family/shared'),
                          variant: GlassPillVariant.primaryLight,
                          expanded: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invite', style: SettleTypography.heading),
                        const SizedBox(height: 8),
                        Text(
                          'Send an invite link so others can join your plan.',
                          style: SettleTypography.body.copyWith(
                            color: _supportingTextColor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GlassPill(
                          label: 'Get invite link',
                          onTap: () => context.push('/family/invite'),
                          variant: GlassPillVariant.primaryLight,
                          expanded: true,
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
              Text('Family members', style: SettleTypography.heading),
              SettleTappable(
                onTap: () => context.push('/family/invite'),
                semanticLabel: 'Invite family member',
                child: Text(
                  'Invite',
                  style: SettleTypography.body.copyWith(
                    color: SettleColors.ink700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            Text(
              'You\'ll appear here. Invite others to add them.',
              style: SettleTypography.body.copyWith(
                color: _supportingTextColor(context),
              ),
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
    return GlassCard(
      variant: GlassCardVariant.lightStrong,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: SettleRadii.pill,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: SettleColors.ink500.withValues(alpha: 0.18),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: SettleTypography.body.copyWith(
                color: SettleColors.ink800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: SettleTypography.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                role,
                style: SettleTypography.caption.copyWith(
                  color: _mutedTextColor(context),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _supportingTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightSoft : SettleColors.ink500;
}

Color _mutedTextColor(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return isDark ? SettleColors.nightMuted : SettleColors.ink400;
}
