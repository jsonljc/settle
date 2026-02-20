# Settle — Accessibility Requirements

> Settle's users are cognitively impaired by design context: sleep deprivation, emotional flooding, darkness, one-handed use while holding a child. Accessibility isn't a checkbox — it's the primary design constraint.
>
> **Design-specific constraints** (tap target sizes, contrast ratios, CTA placement, reduce motion, text scaling, color independence) have been removed. Follow platform and team guidance as needed.

**See also:** [UX_RULES.md](UX_RULES.md) (interaction laws).

---

## Guiding Principle

A parent at 3am, one hand on a child, eyes half-open, room pitch-black, emotionally wrecked — that is Settle's target user state. Every a11y decision flows from this.

---

## Semantic Labels (VoiceOver / TalkBack)

Every interactive element should have a semantic label that describes its action, not its appearance.

| Element | Bad label | Good label |
|---------|-----------|------------|
| Reset hold area | "Circle" | "Hold to begin reset. Press and hold anywhere on screen." |
| State pick: How I feel | "Sad face button" | "Focus on how I feel" |
| State pick: How they feel | "Angry face button" | "Focus on how they feel" |
| Card Keep button | "Keep" | "Save this card to your playbook" |
| Card Another button | "Another" | "Show a different card" |
| Card Send button | "Send" | "Send this card to someone" |
| Close button | "X" | "Close and return" |
| Moment tile: Boundary | "Boundary" | "Boundary: [reads the script text]" |
| Moment tile: Connection | "Connection" | "Connection: [reads the script text]" |
| Timer ring | "Circle animation" | "Reset timer: [X] seconds remaining" |
| Sleep tile: Bedtime | "Bedtime" | "Start bedtime guidance" |
| Toast | (none) | Announced via `accessibilityLiveRegion` / `UIAccessibility.post(.announcement)` |

**Guidance:**
- Emoji used as labels (e.g. R2 state pick) should have a text equivalent. Emoji are decorative, never semantic.
- Screen titles are announced when the screen appears (Flutter: `Semantics(header: true)`).
- Card Repair text should be readable by VoiceOver as continuous prose.
- "Why this works" expandable sections should announce expanded/collapsed state.

---

## Screen Reader Flow Order

VoiceOver / TalkBack should encounter elements in a logical order on every screen:

1. Screen title (announced as header)
2. Instructional text / content
3. Primary action
4. Secondary actions (left to right)
5. Navigation elements (tab bar)

**Guidance:**
- Tab bar is typically last in the accessibility tree.
- Modal sheets trap focus — VoiceOver should not escape to content behind the sheet.
- Toasts are announced but do not steal focus.
- Card content reads in order: Wisdom → Repair → Next step → Actions.

---

## Cognitive Load Rules

These aren't traditional a11y requirements, but they're critical for Settle's user context.

| Rule | Rationale |
|------|-----------|
| Max 2 choices per screen (exceptions: onboarding chips, debrief categories) | Decision fatigue is real at 3am |
| No countdown timers with visible numbers (exception: Moment "10 seconds" label) | Countdowns create pressure; progress rings without numbers are calmer |
| No multi-step confirmation dialogs | Every extra tap is a failure point for an exhausted user |
| No undo — use "Keep" as the only save mechanic | Undo implies the user made a mistake; "Keep" implies the user made a choice |
| Optional elements are truly optional | "Skip" never penalizes. Skipping debrief doesn't reduce card quality. |
| Error recovery is silent | If something fails, retry automatically once. Only show error UI on second failure. |
