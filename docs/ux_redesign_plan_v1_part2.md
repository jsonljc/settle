# Settle UX Redesign Plan v1 — Part 2 (Phases 4-7)

> Note (2026-02-15): standalone Night Mode has been retired. Remaining mentions are legacy context unless noted.

---

# 4. PROPOSED IA + BOTTOM NAV + HOME LAYOUT

## New IA (3 tabs + settings gear)

```
Tab 1: HELP NOW (/now)
  Job: "My child is struggling. Tell me what to do."
  Root: HelpNowScreen (refactored to Guided Beats)
  Sub: SOS/Breathe accessible via "I need a pause" link

Tab 2: SLEEP (/sleep)
  Job: "Get through tonight."
  Root: SleepTonightScreen (becomes tab root)
  Sub: Legacy `/night` aliases route here; bedtime protest routes here

Tab 3: PROGRESS (/progress)
  Job: "See how we're doing and learn why."
  Root: PlanProgressScreen (simplified)
  Sub: Logs, Learn, Shared Scripts as secondary links

Settings: Gear icon in top-right of any tab header
  Contains: Profile, approach, toggles, Shared Scripts, internal tools
```

## Handoff Rules

| Condition | Behavior |
|---|---|
| Night (19:00-06:00) + app opens | Default to Sleep tab; subtle banner: "Need crisis help instead?" |
| Active sleep plan exists | Sleep tab shows plan runner immediately |
| "Bedtime protest" tapped in Help Now | Route to Sleep tab with bedtime scenario |
| "I need a pause" tapped anywhere | Push SOS overlay (not tab switch) |
| Sleep escalation | Link: "Switch to crisis help →" routes to Help Now |
| Morning (06:00-19:00) + no active plan | Default to Help Now tab |

## Home Screen → Eliminated

Bottom nav IS the home. Splash routes to appropriate tab based on time + plan state.

## What gets hidden under Settings / "More"

- Family Rules (renamed "Shared Scripts")
- Profile editing
- Approach switcher
- All toggles (wake nudges, auto nighttime support, wellbeing, simplified mode, one-handed, grief-aware, nap transition, partner sync)
- Internal tools
- Version badge removed

## Renamed Destinations

| Old | New | Job |
|---|---|---|
| Home | *(eliminated)* | — |
| Relief Hub | *(eliminated)* | — |
| Help Now | **Help Now** | Get one thing to say and do right now |
| Sleep Tonight | **Sleep** | Get through tonight step by step |
| Night Mode | **Nighttime sleep support** (within Sleep) | Guided support for overnight wakes |
| SOS / Reset | **Take a Breath** (overlay) | Pause and steady yourself |
| Plan & Progress | **Progress** | See this week's focus and how it's going |
| Logs | **Logs** (sub of Progress) | Review what happened this week |
| Learn | **Learn** (sub of Progress) | Understand why this approach works |
| Family Rules | **Shared Scripts** (in Settings) | Keep caregivers on the same page |
| Settings | **Settings** (gear icon) | Update profile and preferences |

## Bottom Nav Tab Spec

### 3-Tab Default

| Tab | Label | Icon Concept | Job |
|---|---|---|---|
| **Help Now** | `Help Now` | Hand-heart or life-preserver | "My child is struggling. Tell me what to do." |
| **Sleep** | `Sleep` | Moon crescent | "Get through tonight." |
| **Progress** | `Progress` | Gentle upward trend | "See how we're doing." |

### Optional 4th Tab (if data shows demand)

| Tab | Label | Icon | Job |
|---|---|---|---|
| **Breathe** | `Breathe` | Concentric circles | "I need to steady myself." |

Recommendation: Start with 3. Surface "Take a Breath" as persistent top-bar icon or floating action, not a 4th tab.

### First Screen Wireframes

#### Tab 1: Help Now
```
+------------------------------+
| Help Now            [gear]   |  header
|                              |
| +---------------------------+|
| | What's happening?         ||  primary area
| |                           ||
| | [Crying/upset] [Hitting]  ||  2 primary tiles
| |                           ||
| | [Something else v]        ||  expands to more
| +---------------------------+|
|                              |
|  "I need a pause" link       |  routes to Breathe
|                              |
| +---------------------------+|
| | Stay low, stay calm.      ||  contextual tip
| | You've got this.          ||
| +---------------------------+|
|                              |
| [Help Now] [Sleep] [Progress]|  bottom nav
+------------------------------+
```
- **Primary CTA**: 2 large incident tiles
- **Secondary**: "Something else" disclosure (max 3 more)
- **Hidden**: Transition overwhelm merged into Crying; Bedtime protest routes to Sleep; Refusal under "Something else"

#### Tab 2: Sleep
```
+------------------------------+
| Sleep               [gear]   |
|                              |
| +---------------------------+|  IF active plan:
| | Tonight's plan            ||
| | Step 2 of 5              ||
| | "Place in crib drowsy"   ||
| | [Continue plan ->]        ||  primary CTA
| +---------------------------+|
|                              |
|  OR (no plan):               |
| +---------------------------+|
| | What's happening tonight? ||
| | [Bedtime] [Wake] [Early]  ||
| | [Start tonight's plan]    ||  primary CTA
| +---------------------------+|
|                              |
|  "Night support" link        |
|  "I need a pause" link       |
| [Help Now] [Sleep] [Progress]|
+------------------------------+
```

#### Tab 3: Progress
```
+------------------------------+
| Progress            [gear]   |
|                              |
| +---------------------------+|
| | This week's focus         ||
| | "Earlier bedtime by 15m"  ||
| | [Review progress ->]      ||  primary CTA
| +---------------------------+|
|                              |
|  Logs - Learn - Shared Scripts|  3 secondary links
|                              |
| [Help Now] [Sleep] [Progress]|
+------------------------------+
```

### Tab Root Route Mapping

| Tab | New route | Current screen | Refactor |
|---|---|---|---|
| Help Now | `/now` (mode=incident default) | `HelpNowScreen` | Guided Beats |
| Sleep | `/sleep` (new canonical) | `SleepTonightScreen` | Tab root |
| Progress | `/progress` (new canonical) | `PlanProgressScreen` | Simplified |

---

## LIQUID GLASS SPEC (calm version)

### Bottom Bar Blur/Translucency

- **Background**: `BackdropFilter` with `sigmaX: 18, sigmaY: 18` (heavier than card blur of 12 to ensure readability over scrolling content)
- **Fill**: `Color(0xCC0F1724)` — 80% of `T.pal.bgDeep`. Opaque enough for contrast, translucent enough for depth.
- **Border**: Top edge only, `Color(0x0AFFFFFF)` (matches `T.glass.border`), 0.5px
- **Height**: 64pt (iOS standard) + safe area bottom inset
- **No specular highlight** on bottom bar (highlights go on top edges; bottom bar is grounding, not floating)

### Selection Animation

- **Active tab**: Icon + label transition to `T.pal.accent` with `T.anim.fast` (150ms) ease-out
- **Inactive tabs**: `T.pal.textTertiary` (white 40%)
- **Selection indicator**: Subtle pill behind active icon+label, `T.glass.fillAccent` (accent 10%), border-radius `T.radius.pill`, animated width morph between tabs using `T.anim.normal` (250ms)
- **No bounce, no scale, no overshoot.** Calm = linear or ease-out only.
- **Tab switch**: Content area uses existing `_fade` transition (250ms fade)

### Motion/Animation Limits for Crisis

- **Respect `MediaQuery.disableAnimations`** and `AccessibilityFeatures.reduceMotion`
- When reduce motion is on:
  - Bottom bar selection: instant color change, no pill morph
  - Tab content: instant swap, no fade
  - Guided Beats: instant card swap, no slide
  - SOS breathing circles: static (no pulsing)
  - Sleep wait timer: text-only countdown, no animation
- **Crisis screens (Help Now Guided Beats)**: Already minimal animation. Progress dots use color only, no position animation.

### Accessibility Considerations

- **Contrast**: Active tab icon+label on bar background must meet WCAG AA (4.5:1). `T.pal.accent` (#E8A94A) on `#0F1724` at 80% = ~5.2:1. Passes.
- **Inactive contrast**: `T.pal.textTertiary` (white 40%) on bar = ~3.1:1. Acceptable for inactive decorative elements but add `Semantics` labels.
- **Reduce transparency**: When `AccessibilityFeatures.reduceTransparency` is on, use solid `T.pal.bgDeep` for bar background (no blur, no alpha).
- **Touch targets**: Each tab area minimum 48x48pt. With 3 tabs on 375pt width = 125pt each. Exceeds minimum.
- **Semantics**: Each tab gets `Semantics(label: 'Help Now tab', selected: isActive)`.

---

# 5. INTERACTION RULES + COMPONENT PATTERNS

## Settle Interaction Rules (15 bullets)

1. **One primary CTA per screen.** Always `GlassCta` (filled accent). No competing filled buttons.
2. **Secondary actions use `GlassPill` or underlined text links.** Never a second filled button.
3. **Optional content collapsed by default** via `ExpansionTile`. Label: "[Topic] (optional)".
4. **Back always works.** Every screen has back affordance. Bottom nav tabs reset to root on re-tap.
5. **Escape hatch always visible.** "Finish for now" or "I need a pause" on every crisis screen, never behind disclosure.
6. **No silent redirects.** Show 2-option modal before unexpected routing.
7. **Progress uses dots, not numbers or timers.** Dots show position without implying speed.
8. **Large text for crisis content.** "Say this" = `T.type.h2` (22pt) min. "Do this" = `T.type.h3` (17pt).
9. **Nighttime support is opt-in.** Prompt "Switch to sleep support?" instead of auto-routing.
10. **Disabled buttons explain why.** Label says why (e.g., "Confirm safe sleep to start").
11. **No jargon.** No "mode", "incident", "reset", "relief", "runner", "scenario" in UI.
12. **Haptic on primary CTA only.** Light haptic on `GlassCta`. None on nav or secondary.
13. **Loading states reassure.** "Getting your plan ready..." with subtle pulse, not spinner.
14. **Error states are calm.** Format: "[What happened]. [What to do]. [Your data is safe.]"
15. **Empty states guide.** Never "No data." Always: "Nothing here yet. [Start something →]"

## Component Patterns

| Pattern | Purpose | Implementation |
|---|---|---|
| **Beat Card** | One step in Guided Beats | New `lib/widgets/beat_card.dart`: GlassCard + overline + large body + CTA + progress dots |
| **Script Line** | "Say this" display | `T.type.h2`, `GlassCardAccent`, centered |
| **Action Line** | "Do this" display | `T.type.h3`, standard `GlassCard` |
| **Progress Dots** | Position in sequence | New `lib/widgets/progress_dots.dart`: Row of circles |
| **Wait Pulse** | Calming visual | Extract from `sos.dart` → `lib/widgets/calm_pulse.dart` |
| **Context Banner** | Auto-routing info | New `lib/widgets/context_banner.dart` |
| **Bottom Nav** | Persistent navigation | New `lib/widgets/settle_bottom_nav.dart` |
| **Next Step Card** | Primary action on any tab | Extract from `home.dart` → `lib/widgets/next_step_card.dart` |

---

# 6. COPY PACK + TONE GUIDE

## Before → After (Top 30)

| # | File:line | Before | After | Why |
|---|---|---|---|---|
| 1 | `home.dart:141` | "Get support now" | "Help with what's happening" | Outcome-based |
| 2 | `home.dart:144` | "Pick a situation. Get one line to say next." | "We'll give you one thing to say and do." | Warmer, no "pick" |
| 3 | `relief_hub.dart:43` | "Start Relief" | *(eliminated)* | Screen removed |
| 4 | `help_now.dart:342` | "Pick what fits. We'll give one next step." | "What's happening right now?" | Question reduces load |
| 5 | `help_now.dart:386` | "Timer" | *(removed)* | Replaced by Wait beat |
| 6 | `help_now.dart:394` | "Start 3m timer" | *(removed)* | Timer killed |
| 7 | `help_now.dart:414` | "More options (optional)" | "After the moment (optional)" | Time-based, not tool-based |
| 8 | `help_now.dart:435` | "If it gets bigger" | "If things get harder" | Empathetic |
| 9 | `help_now.dart:449` | "Context tags (optional)" | "What was going on? (optional)" | Human language |
| 10 | `help_now.dart:479` | "How did it go? (optional)" | "How did it end? (optional)" | Concrete |
| 11 | `help_now.dart:503` | "Saved. Close when you're ready." | "Noted. You can close anytime." | Warmer |
| 12 | `sos.dart:83` | "Now: Reset" | "Take a Breath" | Outcome-based |
| 13 | `sos.dart:87` | "Mode: Reset" | *(removed)* | Redundant jargon |
| 14 | `sos.dart:155` | "Need urgent human support?" | "Need to talk to someone?" | Less clinical |
| 15 | `sleep_tonight.dart:333` | "Sleep Tonight" | "Tonight's Sleep" | Personal, possessive |
| 16 | `sleep_tonight.dart:338` | "One plan tonight. Take one step at a time." | "One step at a time. We'll guide you." | Removes "plan" jargon |
| 17 | `sleep_tonight.dart:646` | "Safety check" | "Quick safety check" | "Quick" reduces burden |
| 18 | `sleep_tonight.dart:649` | "One quick check before scripts." | "Before we start, one quick check." | Conversational |
| 19 | `sleep_tonight.dart:654` | "Safe sleep setup is ready" | "Sleep space is safe" | Plain language |
| 20 | `sleep_tonight.dart:569` | "Confirm safe sleep setup to start." | "Confirm the sleep space is safe to begin." | Matches toggle |
| 21 | `sleep_tonight.dart:922` | "Tonight plan in progress" | "Tonight's plan" | Shorter |
| 22 | `sleep_tonight.dart:968` | "Next step" | "Now" | Immediate, not sequential |
| 23 | `sleep_tonight.dart:989` | "Start 2m timer" | "Wait 2 minutes" (secondary link) | Timer demoted |
| 24 | `sleep_tonight.dart:996` | "Complete step" | "Done with this step →" | Clearer action |
| 25 | `plan_progress.dart` title | "Plan & Progress" | "Progress" | Shorter |
| 26 | `today.dart:71` | "Logs" | "This Week" | Outcome-based |
| 27 | `today.dart:76` | "Day and week logs in one place." | "How this week is going." | Warmer |
| 28 | `family_rules.dart:67` | "Family Rules" | "Shared Scripts" | Less authoritarian |
| 29 | `home.dart:196` | "Take a 60-second reset" | "Take a breath" | Warm, no time pressure |
| 30 | `home.dart:108-109` | "Night/Quick support is on. Start with one small step." | "You're here. That's the first step." | Reassurance-first |

## Microcopy Style Guide

**Sentence length:** Max 12 words per line. Max 2 sentences per card.

**Verb choices:**
- Use: say, do, try, start, close, breathe, wait, stay
- Avoid: manage, handle, control, fix, solve, optimize, track

**Reassurance patterns:**
- "You're doing enough right now."
- "This will pass."
- "One step at a time."
- "You can close anytime."
- "Your data is safe."

**CTA verbs:**
- Primary: "Help with...", "Start...", "Continue...", "Review..."
- Secondary: "Open...", "See...", "Learn why..."
- Exit: "Finish for now", "Close", "Done"

**Forbidden words in UI:**
- "should", "failed", "wrong", "bad", "never", "always"
- "mode", "incident", "scenario", "runner", "reset", "relief"
- "optimize", "track", "log" (use "note" or "review" instead)

**Tone:** First-person plural ("we'll guide you") or second-person ("you're doing enough"). Never imperative without softening ("Try this" not "Do this now").

---

# 7. VISUAL CALM FIXES

## Top 10 Visual Stressors (remaining after v1 audit)

| # | Stressor | Location | Fix |
|---|---|---|---|
| 1 | **No persistent nav = spatial disorientation** | All screens | Add bottom nav (Phase 3) |
| 2 | **Help Now incident grid is visually dense** | `help_now.dart:626-663` | Reduce to 2 primary tiles + disclosure. Increase `childAspectRatio` to 1.5 for breathing room |
| 3 | **Sleep Tonight safety gate dominates above-fold** | `sleep_tonight.dart:407-445` | Collapse into single toggle + disclosure for red flags |
| 4 | **Inconsistent header patterns** | All screens | Standardize: overline label + h2 title + caption subtitle. Extract to shared `ScreenHeader` widget |
| 5 | **ExpansionTile arrow competes with content** | Multiple screens | Use custom disclosure with subtle chevron, not Material ExpansionTile default arrow |
| 6 | **GlassCard padding varies (16, 18, 20, 22)** | Multiple screens | Standardize: default 16, accent cards 18, primary content 20. Remove 22. |
| 7 | **Crisis output card has 3 sections (Say/Do/Timer) with equal visual weight** | `help_now.dart:362-398` | Guided Beats separates these into sequential cards, solving the hierarchy problem |
| 8 | **Plan & Progress vertical scroll length** | `plan_progress.dart` | Split into primary card + disclosure. Target: 1.5 screen heights max |
| 9 | **Legacy Night Mode had 5 stacked cards** | `night_mode.dart:62-155` | Reduce to: Primary card + Wait badge + SOS link. Move Feed/Settle and Reassurance behind disclosure |
| 10 | **Settings is a flat list of toggles** | `settings.dart:74-150+` | Group into: Profile card, Feature focus, Notifications, Accessibility. Use section headers |

## Spacing/Type Scale

Already well-defined in `settle_tokens.dart`. Enforce consistently:

| Use | Token | Value |
|---|---|---|
| Between major sections | `T.space.md` | 12px |
| Between cards in a group | `T.space.sm + 2` | 10px |
| Screen horizontal padding | `T.space.screen` | 20px |
| Card internal padding (default) | 16px | — |
| Card internal padding (primary) | 20px | — |
| Above-fold breathing room | `T.space.lg` | 16px after header |

## "One-Screen Glance" Rule

What must be visible without scrolling on each tab:

| Tab | Must see | Must NOT see |
|---|---|---|
| Help Now | 2 incident tiles + "Something else" + "I need a pause" | Outcome logging, context tags, escalation notes |
| Sleep (no plan) | Scenario picker + "Start tonight's plan" CTA | Advanced options, safety red flags (behind disclosure) |
| Sleep (active plan) | Current step title + script + "Continue" CTA | Utility actions, escalation rule, evidence links |
| Progress | This week's focus card + primary CTA | Day planner, rhythm inputs, bottleneck detection |

---

# 8. IMPLEMENTATION PLAN

## Phase 1: Quick Wins (1-2 days)

These reduce confusion immediately with minimal structural change.

### 1.1 Kill Relief Hub intermediary
- **Files**: `lib/router.dart`, `lib/screens/home.dart`, `lib/screens/relief_hub.dart`
- **Change**: Home CTA routes directly to `/now` (Help Now). Remove `/relief` route. Keep `relief_hub.dart` for reference but remove from router.
- **Acceptance**: Tapping primary CTA on Home goes directly to Help Now incident picker. No intermediate screen.
- **Regression**: Test Home → Help Now navigation. Test night-time routing still works.

### 1.2 Remove age band picker when profile has age
- **Files**: `lib/screens/help_now.dart`, `lib/services/help_now_age_band_mapper.dart`
- **Change**: In `_onIncidentTapped`, if `_inferAgeBand()` returns non-null, skip `_AgeBandPicker` and go straight to output.
- **Acceptance**: User with completed profile never sees age picker. User without profile still sees it.
- **Regression**: Test with profile (skip picker), without profile (show picker).

### 1.3 Demote timer to optional in Help Now
- **Files**: `lib/screens/help_now.dart`
- **Change**: Move "Timer" section from primary card into "After the moment (optional)" disclosure. Change label to "Set a wait timer (optional)".
- **Acceptance**: Output card shows only "Say this" + "Do this" + primary CTA "I said it" (prep for Guided Beats). Timer is behind disclosure.
- **Regression**: Timer still functions when expanded. Event logging still captures `timerMinutes`.

### 1.4 Fix night auto-redirect
- **Files**: `lib/screens/help_now.dart`
- **Change**: Replace silent redirect (lines 284-310) with a modal: "It's nighttime. Would you like sleep support or crisis help?" Two buttons: "Sleep support" → Sleep Tonight, "Crisis help" → stay on Help Now.
- **Acceptance**: At night, user sees choice modal instead of flash redirect.
- **Regression**: Test at night (modal appears), during day (no modal). Test both modal choices route correctly.

### 1.5 Copy fixes (top 15 strings)
- **Files**: `help_now.dart`, `sos.dart`, `sleep_tonight.dart`, `home.dart`
- **Change**: Apply Before→After for items 1, 4, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19 from copy pack.
- **Acceptance**: All changed strings render correctly. No truncation.
- **Regression**: Golden image tests will need baseline update.

### 1.6 Remove SOS jargon
- **Files**: `lib/screens/sos.dart`
- **Change**: "Now: Reset" → "Take a Breath". Remove "Mode: Reset" line. "Need urgent human support?" → "Need to talk to someone?"
- **Acceptance**: SOS screen shows warm, non-clinical language.
- **Regression**: SOS screen renders, breathing animation works, crisis resources visible.

## Phase 2: Structural (3-5 days)

### 2.1 Add bottom navigation shell
- **New files**: `lib/widgets/settle_bottom_nav.dart`, `lib/screens/shell.dart`
- **Modify**: `lib/router.dart`, `lib/main.dart`
- **Change**: Create `ShellRoute` with `SettleBottomNav`. Three tabs: Help Now (`/now`), Sleep (`/sleep`), Progress (`/progress`). Implement liquid glass spec for bottom bar.
- **Acceptance**: 3 tabs visible. Tapping switches content. Active tab highlighted with accent pill. Back button within tab navigates sub-screens. Re-tapping active tab returns to root.
- **Regression**: All existing routes still accessible. Deep links work. Night routing works. Settings accessible via gear icon.

### 2.2 Implement Guided Beats for Help Now
- **New files**: `lib/widgets/beat_card.dart`, `lib/widgets/progress_dots.dart`, `lib/widgets/calm_pulse.dart`
- **Modify**: `lib/screens/help_now.dart`
- **Change**: Replace output card (lines 358-525) with beat stepper. 4 beats: Say → Do → Wait → Done/Escalate. Extract `_PulsingCircle` from `sos.dart` into shared widget.
- **Acceptance**: After incident selection, user sees Beat 1 (Say this) with progress dots. Tapping advances. Beat 3 shows calming pulse. Beat 4 shows outcome logging. No timer visible by default.
- **Regression**: All incident types produce correct Say/Do/Escalate content. Event logging still fires. Outcome recording works.

### 2.3 Refactor Sleep Tonight as tab root
- **Modify**: `lib/screens/sleep_tonight.dart`, `lib/router.dart`
- **Change**: Sleep Tonight becomes root of Sleep tab. Remove back-button header (tab handles navigation). Keep legacy `/night` links redirecting into Sleep. Demote step timer to secondary action, promote "Done with this step" to primary CTA.
- **Acceptance**: Sleep tab shows scenario picker or active plan. Legacy `/night` links land on Sleep. Timer is secondary.
- **Regression**: Plan creation, step completion, wake logging, abort all work. Safety gate functions.

### 2.4 Simplify Progress tab
- **Modify**: `lib/screens/plan_progress.dart`
- **Change**: Primary card: "This week's focus" with experiment + CTA. Secondary: 3 links (Logs, Learn, Shared Scripts). Move day planner, rhythm inputs, bottleneck detection behind "More details" disclosure.
- **Acceptance**: Above-fold shows only focus card + 3 links. Everything else behind disclosure.
- **Regression**: Weekly focus selection works. Day planner accessible. Evidence sheet works.

### 2.5 Eliminate Home screen
- **Modify**: `lib/router.dart`, `lib/screens/splash.dart`
- **Change**: Splash routes to shell (default tab based on time/plan). `/home` redirects to shell. Remove `HomeScreen` from active routes (keep file for reference).
- **Acceptance**: App opens to appropriate tab. No Home screen in flow.
- **Regression**: Onboarding still routes to shell after completion. All `/home` deep links redirect.

### 2.6 Move Family Rules into Settings
- **Modify**: `lib/screens/settings.dart`, `lib/router.dart`
- **Change**: Add "Shared Scripts" section in Settings. `/rules` redirects to `/settings` with auto-scroll to scripts section.
- **Acceptance**: Shared Scripts accessible from Settings and from Progress tab link.
- **Regression**: Rule editing, diff review, version tracking all work.

## Phase 3: Polish + Design System (2-3 days)

### 3.1 Standardize screen headers
- **New file**: `lib/widgets/screen_header.dart`
- **Modify**: All screen files
- **Change**: Extract common header pattern (overline + h2 + caption) into reusable widget.
- **Acceptance**: All screens use `ScreenHeader`. Consistent spacing.

### 3.2 Standardize card padding
- **Modify**: All screen files using `GlassCard`
- **Change**: Default 16, primary 20. Remove ad-hoc 18/22 values.
- **Acceptance**: Visual consistency across all cards.

### 3.3 Custom disclosure widget
- **New file**: `lib/widgets/settle_disclosure.dart`
- **Modify**: All screens using `ExpansionTile`
- **Change**: Replace Material `ExpansionTile` with custom widget using subtle chevron, consistent padding, no divider hack.
- **Acceptance**: All disclosures look identical. No `Theme(dividerColor: transparent)` hacks.

### 3.4 Reduce-motion support
- **Modify**: `lib/theme/settle_tokens.dart`, `lib/screens/sos.dart`, `lib/widgets/calm_pulse.dart`
- **Change**: Check `MediaQuery.of(context).disableAnimations` and skip animations accordingly.
- **Acceptance**: With reduce-motion on, no pulsing circles, no fade transitions, instant tab switches.

### 3.5 Empty state patterns
- **New file**: `lib/widgets/empty_state.dart`
- **Modify**: `lib/screens/today.dart`, `lib/screens/plan_progress.dart`
- **Change**: Replace "No data" states with guided empty states: "Nothing here yet. [Start something →]"
- **Acceptance**: Every empty state has a CTA.

### 3.6 Loading state patterns
- **Modify**: `lib/screens/sleep_tonight.dart`, `lib/screens/plan_progress.dart`
- **Change**: Replace `CircularProgressIndicator.adaptive()` with calm text + pulse: "Getting your plan ready..."
- **Acceptance**: No spinners in the app. All loading states show reassuring text.

---

## Test Checklist

### Navigation
- [ ] App opens to correct tab (Help Now day / Sleep night)
- [ ] Bottom nav switches tabs
- [ ] Re-tap active tab returns to root
- [ ] Back button navigates within tab
- [ ] Gear icon opens Settings from any tab
- [ ] Deep links to old routes redirect correctly
- [ ] `/home` redirects to shell
- [ ] `/relief` redirects to `/now`

### Help Now (Guided Beats)
- [ ] Incident selection → Beat 1 (Say this)
- [ ] Beat 1 → Beat 2 (Do this)
- [ ] Beat 2 → Beat 3 (Wait with them)
- [ ] Beat 3 "calming" → Beat 4a (Done)
- [ ] Beat 3 "escalating" → Beat 4b (Escalation guidance)
- [ ] Progress dots update correctly
- [ ] "I need a pause" → SOS overlay
- [ ] Outcome logging works from Beat 4
- [ ] Event bus fires correctly for all beats
- [ ] Age band auto-inferred from profile

### Sleep
- [ ] No plan: scenario picker visible
- [ ] Plan creation works
- [ ] Active plan: step runner visible
- [ ] Step completion advances plan
- [ ] Timer works as secondary action
- [ ] Legacy `/night` and `/night-mode` links redirect to Sleep tab
- [ ] Safety gate functions
- [ ] Red flag triggers pause guidance

### Progress
- [ ] Weekly focus card visible above fold
- [ ] Logs accessible
- [ ] Learn accessible
- [ ] Shared Scripts link works
- [ ] Day planner behind disclosure

### Night routing
- [ ] Night time: Sleep tab default + banner
- [ ] Banner "crisis help" routes to Help Now
- [ ] No silent redirects anywhere

### Accessibility
- [ ] Reduce motion: no animations
- [ ] Reduce transparency: solid bottom bar
- [ ] VoiceOver: all tabs labeled
- [ ] Touch targets >= 48pt
- [ ] Contrast ratios pass WCAG AA

### State
- [ ] Profile-less user sees onboarding
- [ ] Feature rollout flags respected
- [ ] Hive persistence works across tab switches
- [ ] No state leaks between tabs
