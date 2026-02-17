# Settle — Accessibility Requirements

> Settle's users are cognitively impaired by design context: sleep deprivation, emotional flooding, darkness, one-handed use while holding a child. Accessibility isn't a checkbox — it's the primary design constraint.

**See also:** [UX_RULES.md](UX_RULES.md) (interaction laws), [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) (tokens, contrast).

---

## Guiding Principle

A parent at 3am, one hand on a child, eyes half-open, room pitch-black, emotionally wrecked — that is Settle's target user state. Every a11y decision flows from this.

---

## Tap Targets

| Rule | Spec | Rationale |
|------|------|-----------|
| Minimum tap target | 44×44pt (iOS standard) | Imprecise tapping from fatigue and one-handed use |
| Recommended tap target for primary actions | 52×52pt minimum | Primary CTAs deserve extra tolerance |
| Minimum spacing between targets | 8pt | Prevents mis-taps on adjacent elements |
| Reset hold area | Full screen | A shaking hand should not need to aim |
| Moment dismiss | Full tile area (not just text) | Speed matters — the whole tile is the target |
| Close/dismiss actions | Minimum 44×44pt even for × icons | "Close" must never be hard to hit |

**Fail condition:** Any interactive element smaller than 44×44pt. No exceptions.

---

## Semantic Labels (VoiceOver / TalkBack)

Every interactive element must have a semantic label that describes its action, not its appearance.

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

**Rules:**
- Every emoji used as a label (R2 state pick) must have a text equivalent. Emoji are decorative, never semantic.
- Screen titles must be announced when the screen appears (Flutter: `Semantics(header: true)`).
- Card Repair text must be readable by VoiceOver as continuous prose, not as separate text blocks.
- "Why this works" expandable sections must announce their expanded/collapsed state.

**Fail condition:** Any interactive element without a semantic label. Any emoji as the sole label.

---

## Reduce Motion

When the system `prefers-reduced-motion` / `AccessibilityFeatures.reduceMotion` is enabled:

| Normal behavior | Reduced motion behavior |
|----------------|------------------------|
| Card slide-up + fade (200ms) | Instant appear (0ms) |
| Sheet slide-up (250ms) | Instant appear (0ms) |
| Moment pulse animation | Static circle (no animation) |
| Timer ring fill animation | Static progress indicator (filled arc, no animation) |
| Toast fade in/out | Instant appear / disappear |
| Haptic pulse (1/sec) | **Kept** — haptics are not motion |
| Haptic completion tap | **Kept** |

**Rules:**
- Every `AnimationController`, `Tween`, and `AnimatedWidget` must check `MediaQuery.of(context).reduceMotion` (Flutter 3.19+) or equivalent.
- Haptics are independent of motion preferences. Haptic feedback continues under reduce-motion because it serves a regulation function, not a visual function.
- The Moment breathing circle becomes a static circle with a countdown number inside when reduce-motion is on.

**Fail condition:** Any animation that plays when reduce-motion is enabled.

---

## Contrast

Settle must meet WCAG 2.1 AA minimum contrast ratios.

| Element type | Minimum ratio | Settle targets |
|-------------|---------------|----------------|
| Normal text (≥17px) | 4.5:1 | 7:1+ (we exceed the minimum) |
| Large text (≥24px bold, ≥18.5px regular) | 3:1 | 5:1+ |
| Interactive element boundaries | 3:1 against background | 3:1 (accent on card bg) |
| Disabled elements | No minimum (but must be perceivable) | 2:1 minimum |

**Specific checks:**

| Combination | Ratio | Pass? |
|------------|-------|-------|
| `color-text-primary` (#1A1A1E) on `color-bg-primary` (#FAFAF8) | 16.4:1 | Yes |
| `color-text-secondary` (#6B6966) on `color-bg-primary` (#FAFAF8) | 5.0:1 | Yes |
| `color-text-on-dark` (#F5F5F3) on `color-bg-dark` (#1A1A1E) | 15.3:1 | Yes |
| `color-text-muted-on-dark` (#9E9B97) on `color-bg-dark` (#1A1A1E) | 5.5:1 | Yes |
| `color-accent` (#5B7F6E) on `color-bg-card` (#FFFFFF) | 4.2:1 | Yes (large text) |
| White text on `color-accent` (#5B7F6E) | 4.2:1 | Yes (large text, buttons) |
| `color-accent` dark mode (#7FA893) on `color-bg-primary` dark (#1A1A1E) | 6.8:1 | Yes |

**Rules:**
- All contrast ratios must be verified when design tokens change. Update this table.
- Toast text must meet contrast requirements against the toast background AND be readable against any screen background it may overlay.
- Reset/Moment screens use high-contrast text on dark backgrounds (15:1+). These are used in dark rooms — exceed the minimum generously.

**Fail condition:** Any text/background combination below AA minimum. Any primary-action button text below 4.5:1.

---

## Dynamic Type / Text Scaling

Settle must support system text scaling up to 200% without layout breakage.

| Rule | Implementation |
|------|---------------|
| All text uses system text scaling | Flutter: use `MediaQuery.textScaleFactor` or `Text.textScaler` |
| No fixed-height text containers | Use `Flexible` / `Expanded`, never fixed `height` for text areas |
| Card content scrolls if scaled text overflows | Wrap card content in `SingleChildScrollView` |
| CTA buttons grow vertically with text | `minHeight: 52px` not `height: 52px` |
| Chip labels wrap or truncate gracefully | Use `Flexible` with `TextOverflow.ellipsis` as last resort |

**Rules:**
- Test every screen at 100%, 150%, and 200% text scale.
- At 200%, screens may scroll — that's acceptable. Screens must never clip or overlap.
- The Reset hold instruction ("Hold to let it out.") must remain fully visible at 200% scale.

**Fail condition:** Any text that clips, overlaps, or becomes unreadable at 200% text scale.

---

## Color Independence

No information may be conveyed by color alone.

| Element | Color signal | Non-color signal |
|---------|-------------|------------------|
| Selected chip | Accent background | Also: bold text weight change |
| Primary vs secondary button | Accent fill vs transparent | Also: fill vs ghost style |
| Active tab | Solid icon | Also: label visible (inactive tabs have no label) |
| Toast | Dark background | Also: position + auto-dismiss behavior |
| Error state | No red used | Copy only: "Something went wrong." |
| Saved card indicator | (no color change) | "Saved ✓" text replaces "Save" |

**Fail condition:** Any state change communicated only through color.

---

## Screen Reader Flow Order

VoiceOver / TalkBack should encounter elements in this order on every screen:

1. Screen title (announced as header)
2. Instructional text / content
3. Primary action
4. Secondary actions (left to right)
5. Navigation elements (tab bar)

**Rules:**
- The tab bar is always last in the accessibility tree.
- Modal sheets trap focus — VoiceOver must not escape to content behind the sheet.
- Toasts are announced but do not steal focus.
- Card content reads in order: Wisdom → Repair → Next step → Actions.

---

## One-Handed Reachability

Settle is designed for one-handed use (parent holding child with the other arm).

| Rule | Spec |
|------|------|
| Primary CTA position | Bottom third of screen (thumb zone) |
| Tab bar | Bottom (standard iOS/Android) |
| Close/dismiss | Top right OR bottom (never top left — unreachable for right-handed one-hand use) |
| Reset hold | Full screen (no aiming required) |
| Moment tiles | Full width, stacked vertically (thumb reaches both) |
| Swipe gestures | Not used as primary interactions (unreliable one-handed) |

**Fail condition:** Any primary action positioned in the top third of the screen. Any required swipe gesture.

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

---

## Testing Checklist

Before any screen ships, verify:

- [ ] All tap targets ≥ 44×44pt
- [ ] All text has semantic labels
- [ ] VoiceOver reads the screen in logical order
- [ ] Reduce-motion disables all animation
- [ ] Haptics continue under reduce-motion
- [ ] All contrast ratios meet AA
- [ ] Screen is usable at 200% text scale
- [ ] No information conveyed by color alone
- [ ] Primary action is in the bottom third
- [ ] Screen is usable one-handed (right and left)
- [ ] Screen is usable in dark mode at minimum brightness
- [ ] Screen has max 2–3 choices (or is an exception listed above)
- [ ] No visible countdown numbers (or is Moment)
- [ ] Close/exit is always reachable
