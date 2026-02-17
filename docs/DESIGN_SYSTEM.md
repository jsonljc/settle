# Design System (Rollback Baseline)

Last updated: 2026-02-16
Source of truth: `lib/theme/settle_tokens.dart`

This document defines the only spacing, typography, and component patterns allowed in parent-facing UI.

## 1) Spacing scale

Base grid: 4px

Token scale:
- `T.space.xs` = 4
- `T.space.sm` = 8
- `T.space.md` = 12
- `T.space.lg` = 16
- `T.space.xl` = 20
- `T.space.xxl` = 24
- `T.space.xxxl` = 32
- `T.space.screen` = 20 (horizontal page padding)
- `T.space.cardMin` = 16
- `T.space.cardMax` = 26

Rules:
- Prefer `SettleGap` for vertical/horizontal rhythm.
- Prefer tokenized `EdgeInsets` values (or exact token equivalents).
- Avoid raw spacing constants unless a component explicitly documents them.

## 2) Type scale

Token scale:
- `T.type.splash` = 32/700
- `T.type.h1` = 26/700
- `T.type.h2` = 22/700
- `T.type.h3` = 17/700
- `T.type.body` = 15/400
- `T.type.label` = 15/600
- `T.type.caption` = 13/400
- `T.type.overline` = 11/600
- `T.type.stat` = 34/700
- `T.type.timer` = 48/300

Rules:
- Use these text tokens directly; avoid ad-hoc font sizes.
- If a size override is needed, document why in code comments.
- Keep helper copy in `textSecondary` or `textTertiary`.

## 3) Allowed components

Primary surfaces and actions:
- `SettleBackground`
- `GlassCard`, `GlassCardAccent`, `GlassCardTeal`, `GlassCardRose`, `GlassCardDark`
- `GlassCta` (primary action)
- `GlassPill` (secondary action)

Navigation and layout:
- `ScreenHeader`
- `SettleBottomNav`
- `SettleModalSheet`
- `SettleDisclosure`
- `SettleGap`

Input and selection:
- `SettleChip`
- `SettleSegmentedChoice`
- `SettleTappable`

State components:
- `CalmLoading`
- `EmptyState`

Rules:
- Reuse allowed components first.
- New components require design review and documented rationale.
- Do not recreate card/button/chip primitives inside screens.

## 4) Visual hierarchy rules

- Accent color is reserved for primary action or key state signal.
- Rose/red is reserved for urgent safety and critical alerts.
- One primary CTA per section; secondary actions are lower emphasis.
- Keep cards focused on one decision or one informational chunk.

## 5) Motion and interaction

- Respect reduced motion (`T.reduceMotion(context)`).
- Use tokenized durations from `T.anim`.
- Avoid decorative motion in crisis-critical screens.

## 6) Accessibility baseline

- Tap targets should be at least 44x44 logical pixels.
- Content must remain readable and operable at large text settings.
- Avoid fixed-height containers where text can wrap or grow.

## 7) Current drift to clean up

Observed drift hotspots:
- Frequent hardcoded spacing and sizing in `lib/screens/today.dart`.
- Frequent hardcoded spacing and fixed offsets in `lib/screens/sos.dart`.
- Mixed tokenized and raw spacing in `lib/screens/help_now.dart`.
- Header truncation risk with `TextOverflow.ellipsis` in `lib/widgets/screen_header.dart`.

Cleanup rule:
- In touched files, convert ad-hoc spacing/type to tokens incrementally.
- New code must be token-compliant by default.

## 8) Enforcement

For every PR touching UI:
- [ ] Uses token spacing/type (or documented exception).
- [ ] Uses allowed components for cards/buttons/states.
- [ ] Keeps one primary CTA hierarchy.
- [ ] Supports large text without clipping or hidden actions.
