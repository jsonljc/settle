# Settle UX Redesign Plan v1

Date: 2026-02-14

> Note (2026-02-15): the standalone Night Mode surface was retired in Phase 1. Legacy references below are historical context.

---

# 1. CURRENT EXPERIENCE MAP

## Route Map

```
/              → SplashScreen (auto-routes to /home or /onboard)
/onboard       → OnboardingScreen (7-step conditional flow)
/home          → HomeScreen (single-page, no tabs)
/relief        → ReliefHubScreen (triage: sleep vs incident)
/now            → Multiplexed by ?mode=
                  mode=incident → HelpNowScreen (crisis scripts + timer)
                  mode=sleep    → SleepTonightScreen (tonight plan runner)
                  mode=night    → legacy alias; now redirects to /sleep
                  mode=reset    → legacy alias; use /breathe
/plan           → PlanProgressScreen (weekly focus + day planner)
  /plan/logs    → TodayScreen (sleep/incident logs + charts)
  /plan/learn   → LearnScreen (Q&A evidence cards)
/rules          → FamilyRulesScreen (shared caregiver scripts)
/settings       → SettingsScreen (profile, toggles, approach)
```

Legacy redirects: `/help-now`, `/sleep-tonight`, `/night-mode`, `/night`, `/sos`, `/today`, `/learn`, `/plan-progress`, `/family-rules` all redirect to canonical paths.

Internal-only: `/release-metrics`, `/release-compliance`, `/release-ops`.

## Top-Level Destinations (current)

| Destination | What it is | Job |
|---|---|---|
| **Home** (`/home`) | Landing page | Show child name, one CTA to Relief Hub, secondary actions behind disclosure |
| **Relief Hub** (`/relief`) | Triage screen | Route user to correct crisis/sleep sub-screen |
| **Help Now** (`/now?mode=incident`) | Crisis incident scripts | Pick situation → get "Say this / Do this" + timer |
| **Sleep Tonight** (`/now?mode=sleep`) | Tonight sleep plan runner | Configure or run a step-by-step sleep plan |
| **Night Aliases** (`/night`, `/night-mode`) | Compatibility redirects | Route to `/sleep` |
| **SOS / Breathe** (`/breathe`) | Parent self-regulation | Breathing circles + permission statements |
| **Plan & Progress** (`/plan`) | Weekly focus + day planner | Pick one experiment, track rhythm |
| **Logs** (`/plan/logs`) | Historical data | Day/week sleep charts |
| **Learn** (`/plan/learn`) | Evidence Q&A | Cited answers to parent questions |
| **Family Rules** (`/rules`) | Shared scripts | Boundary scripts for caregivers |
| **Settings** (`/settings`) | Profile & preferences | Age, approach, toggles |

## User Flow (current)

```
Splash → Home → "Get support now" → Relief Hub → {Sleep Tonight | Help Now}
                                                    ↓ (night auto-route)
                                                  Sleep ↔ SOS
Home → More actions → {Sleep Tonight, SOS, Plan, Rules, Settings}
Plan → {Logs, Learn}
```

## Overlaps and Lost Moments

1. **Relief Hub is a dead-weight intermediary.** Home CTA goes to Relief Hub, which asks the same question again. Two triage screens in sequence.
2. **Help Now and Relief Hub overlap.** Both offer "Bedtime protest" routing to Sleep Tonight. User encounters the same decision in 3 places.
3. **Night auto-routing is invisible.** 7pm+ tapping Help Now silently redirects to Sleep Tonight. User sees flash of "Routing to Sleep Tonight…" with no explanation.
4. **SOS is buried.** Hidden under "More actions → Take a 60-second reset" on Home, or small link at bottom of the Sleep flow.
5. **Plan & Progress is sprawling (824 lines).** Combines weekly focus, day planner, rhythm inputs, bottleneck detection, evidence sheets, experiment tracking.
6. **Family Rules is disconnected.** Lives under "More actions" with no contextual entry from crisis flows.
7. **Logs and Learn are nested under /plan but serve different jobs.**

---

# 2. TOP CONFUSION POINTS (ranked)

| # | P | Location | User feels | Why confusing | Smallest fix | Ideal fix |
|---|---|---|---|---|---|---|
| 1 | P0 | Home → Relief Hub → Help Now | "Another menu?" | Two consecutive triage screens | Remove Relief Hub; route directly from Home | Smart Home CTA that auto-routes by context |
| 2 | P0 | `help_now.dart:392-397` timer CTA | "Why a timer? Kid is screaming" | Timer is primary CTA; parents don't time crises | Move timer below fold | Replace with Guided Beats (Phase 2) |
| 3 | P0 | `help_now.dart:284-310` night redirect | "I wanted crisis help, not sleep" | Silent redirect with no consent | Add 2-option modal | Context-aware Home CTA with explicit choice |
| 4 | P0 | `home.dart:141,150` "Get support now" | "Support for what?" | Vague label | Change to "Help with what's happening" | Two distinct CTAs for crisis vs sleep |
| 5 | P0 | No bottom navigation | "How do I get back?" | Every screen is a push; no orientation | Add bottom nav with 3 tabs | Full tab-based IA |
| 6 | P1 | `relief_hub.dart:43` "Start Relief" | "Relief from what?" | Jargon label | Rename to "What's happening?" | Eliminate screen |
| 7 | P1 | `help_now.dart:562-615` 8 incident options | "Too many choices" | 3+5 options during crisis | Reduce primary to 2 + "Something else" | Single-question triage |
| 8 | P1 | `sleep_tonight.dart:611-702` 6 safety toggles | "Am I doing something dangerous?" | Medical checklist before guidance | Collapse; keep only "Safe sleep confirmed" | Move to onboarding |
| 9 | P1 | `help_now.dart:699-730` age band picker | "You already know my kid's age" | Age collected in onboarding but can be null | Always use profile age | Remove `_AgeBandPicker` |
| 10 | P1 | `home.dart:168-244` collapsed More actions | "Is there anything else?" | Plan, Rules, Settings invisible | Show as visible secondary tiles | Bottom nav |
| 11 | P1 | `sleep_tonight.dart:543-545` disabled Start | "Why can't I press it?" | Disabled CTA with small gray hint | Explain on the CTA itself | Pre-confirm safety in onboarding |
| 12 | P2 | `sos.dart:83-88` "Now: Reset / Mode: Reset" | "Reset what?" | Internal jargon | Change to "Take a Breath" | Warm subtitle |
| 13 | P2 | `plan_progress.dart` 824-line screen | "This is overwhelming" | Too many sections in one scroll | Split into focus + planner | Separate screens |
| 14 | P2 | `/plan/learn` buried | "Didn't know Learn existed" | Nested with no entry from crisis | Add "Why does this work?" links | Inline contextual Q&A |
| 15 | P2 | `family_rules.dart:79` version badge | "What does v3 mean?" | Developer artifact | Remove badge | Show "Last updated" date |

---

# 3. TIMER MECHANIC VERDICT

## Where the timer appears

1. **Help Now output** (`help_now.dart:385-397`): Primary CTA "Start Xm timer" (2-4 min). Counts down per-second.
2. **Sleep Tonight runner** (`sleep_tonight.dart:987-993`): Each step has "Start Xm timer" CTA.
3. **Legacy Night Mode wait badge** (retired with `night_mode.dart`): Auto-started countdown. Showed "Wait X:XX" → "Time to check".
4. **SpecPolicy** (`spec_policy.dart:19-21`): `helpNowTimerMinMinutes: 2`, `helpNowTimerMaxMinutes: 10`.

## Mismatch with real behavior

- During a meltdown, no parent thinks "let me start a timer." They need the script line immediately.
- The timer has no consequence — when it reaches 0, nothing happens.
- In Sleep Tonight, timers make more sense (timed checks are protocol), but it's the primary CTA while "Complete step" is a subtle link.
- The retired Night Mode auto-timer was the best implementation — passive, no user action required.

## Verdict

**Kill the timer as primary CTA in Help Now. Keep optional in Sleep Tonight. No separate Night Mode surface.**

## Model A: "Guided Beats" (RECOMMENDED)

Replace "Say this / Do this / Timer" card with 3-5 sequential beats. User taps "Next" to advance. No timer. Progress via dots.

**Journey:**
1. Beat 1 "Say this": Large text script line. Button: "I said it →"
2. Beat 2 "Do this": Action step. Button: "Done →"
3. Beat 3 "Wait with them": Calm holding screen with pulsing dot. "Stay close. Breathe. This will pass." Buttons: "They're calming down" / "It's getting harder"
4. Beat 4a (calming): "You handled it. Close when ready." + optional outcome logging
5. Beat 4b (escalating): Shows `ifEscalates` text. Button: "Got it →" → loops to Beat 3 or offers SOS

**Progress:** Dots at top (current = accent, done = accent 40%, future = glass fill). No numbers, no time.

**Anxiety avoidance:** No countdown. No "start" button. Guidance begins on incident tap. "Wait" beat uses calming pulse. Escape hatch always visible.

**Remove/merge:** `_startTimer()`, `_timer`, `_secondsRemaining`, `_timerLabel()` from `help_now.dart`. Remove Timer overline + GlassCta timer. Merge "If it gets bigger" into Beat 4b.

## Model B: "Hands-Free Script"

Full-screen, one line at a time. Tap anywhere to advance. Optional audio. One-handed use.

**Journey:** 5 screens, each one sentence, tap anywhere to advance. Ends with "You did it" + optional logging.

**Pros:** Maximum simplicity, one-handed, works in dark.
**Cons:** Loses Say/Do structure; no escalation path; no progress indicator.

## Recommendation: Model A

Preserves useful Say/Do structure, adds supportive "wait" beat replacing timer, clear progress without time pressure. Smaller refactor than Model B. Model B could be offered as accessibility option via existing `_simplifiedMode` toggle.
