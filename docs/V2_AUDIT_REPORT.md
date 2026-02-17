# Settle v2.0 — Full Audit Report

**Audit date:** 2025-02-16  
**Reference:** `PLAN.md` (Settle v2.0 Implementation Plan), 8 phases (0–8).

---

## Step 1 — Codebase Discovery

### Project structure

| Layer | Location | Notes |
|-------|----------|--------|
| **Routes** | `lib/router.dart` | GoRouter; v1/v2 shell selected by `v2NavigationEnabled`; `buildRouter(v2NavigationEnabled, v2OnboardingEnabled, regulateEnabled)`; router cache refreshed from Hive `release_rollout_v1` box. |
| **Models** | `lib/models/` | Hive type adapters; `approach.dart` (Approach, AgeBracket, FamilyStructure, RegulationLevel, PrimaryChallenge, FeedingType); `baby_profile.dart` (fields 0–12); `v2_enums.dart` (UsageOutcome, RegulationTrigger, PatternType, NudgeType); `user_card.dart`, `usage_event.dart`, `regulation_event.dart`, `pattern_insight.dart`, `nudge_record.dart`. |
| **Providers** | `lib/providers/` | `release_rollout_provider.dart` (schema 3, 9 v2 flags); `user_cards_provider.dart`, `usage_events_provider.dart`, `regulation_events_provider.dart`, `patterns_provider.dart`, `nudges_provider.dart`; `profile_provider.dart`. |
| **Screens** | `lib/screens/` | Plan: `plan_home_screen.dart`, `debrief_section.dart`, `prep_nudge_section.dart`; Library: `library_home_screen.dart`, `saved_playbook_screen.dart`, `patterns_screen.dart`; Family: `family_home_screen.dart`; Onboarding: `onboarding_v2_screen.dart` + `steps/` (7 steps); Sleep: `sleep_mini_onboarding.dart` (gate + screen). |
| **Widgets** | `lib/widgets/` | `output_card.dart`, `settle_bottom_nav.dart`; `release_surfaces.dart` (RouteUnavailableView, ProfileRequiredView). |
| **Services** | `lib/services/` | `card_content_service.dart`, `pattern_engine.dart`, `nudge_scheduler.dart`, `notification_service.dart` (plan nudges). |
| **Assets** | `assets/guidance/` | `cards_registry_v2.json` (version 1, 12 cards). |

### Route table (v2 when `v2NavigationEnabled` true)

| Route | Screen / behavior |
|-------|-------------------|
| `/` | SplashScreen → `/plan` when v2+profile, else `/now` or `/onboard` (splash reads releaseRolloutProvider) |
| `/onboard` | OnboardingV2Screen when `v2OnboardingEnabled`, else OnboardingScreen |
| `/home` | redirect → `/plan` |
| `/now` | redirect → `/plan` |
| `/plan` | PlanHomeScreen |
| `/plan/regulate` | RegulateFlowScreen (5 steps; RegulationEvent on completion) |
| `/plan/card/:id` | PlanCardScreen |
| `/plan/log` | TodayScreen |
| `/family` | FamilyHomeScreen |
| `/family/shared` | FamilyRulesScreen |
| `/family/invite` | InviteScreen (deep link copy) |
| `/family/activity` | ActivityFeedScreen |
| `/sleep` | SleepMiniOnboardingGate → SleepMiniOnboardingScreen or SleepHubScreen |
| `/sleep/tonight`, `/sleep/rhythm`, `/sleep/update` | SleepTonightScreen, CurrentRhythmScreen, UpdateRhythmScreen |
| `/library` | LibraryHomeScreen |
| `/library/saved`, `/library/learn`, `/library/logs`, `/library/patterns`, `/library/insights`, `/library/cards/:id` | SavedPlaybookScreen, LearnScreen, TodayScreen, PatternsScreen, MonthlyInsightScreen, PlanCardScreen(fallbackRoute: '/library') |
| `/breathe` | redirect → `/plan/regulate` when v2+regulateEnabled, else SosScreen |
| `/settings` | SettingsScreen |
| `/rules` | redirect → `/family/shared` |
| Compatibility (v2) | `/progress`, `/tantrum`, `/sos`→/plan/regulate or /breathe per regulateEnabled, `/today`, `/learn`, etc. | As in PLAN |

### Feature flags (ReleaseRolloutState, schema 3)

- `v2NavigationEnabled`, `v2OnboardingEnabled`, `planTabEnabled`, `familyTabEnabled`, `libraryTabEnabled`, `pocketEnabled`, `regulateEnabled`, `smartNudgesEnabled`, `patternDetectionEnabled` — all present; read from Hive in router and provider.

### Dependencies (relevant)

- `flutter`, `go_router`, `hive_flutter`, `flutter_riverpod`; `flutter_animate`; `flutter_test`.

### Card registry schema (validated)

- **Expected:** `{ id, triggerType, prevent, say, do, ifEscalates?, evidence?, ageRange?, match? }`
- **Actual:** `cards_registry_v2.json` uses `id`, `triggerType`, `prevent`, `say`, `do`, `ifEscalates`, `evidence`, `ageRange`, `match[]` — **matches**.  
- **Count:** 12 cards (2 per trigger type: transitions, bedtime_battles, public_meltdowns, no_to_everything, sibling_conflict, overwhelmed). **Meets minimum.**

---

## Step 2 — Phase-by-Phase Audit

### Phase 0: Foundation & Data Model Extensions

| Item | Status | Notes |
|------|--------|--------|
| RegulationLevel enum (TypeId 43) in approach.dart | ✅ | calm, stressed, anxious, angry |
| FamilyStructure extended (coParent, blended) | ✅ | @HiveField(4), (5) in approach.dart |
| v2_enums (UsageOutcome 55, RegulationTrigger 56, PatternType 57, NudgeType 58) | ✅ | lib/models/v2_enums.dart |
| BabyProfile HiveFields 9–12 (regulationLevel, preferredBedtime, ageMonths, sleepProfileComplete) | ✅ | baby_profile.dart; constructor & copyWith include them |
| UserCard (50), UsageEvent (51), RegulationEvent (52), PatternInsight (53), NudgeRecord (54) | ✅ | Models exist; join record only for UserCard |
| New Hive boxes opened in main.dart | ✅ | user_cards, usage_events, regulation_events, patterns, nudges, release_rollout_v1 |
| All adapters registered in main.dart | ✅ | Including RegulationLevel, v2 enums, UserCard, UsageEvent, RegulationEvent, PatternInsight, NudgeRecord |
| user_cards, usage_events, regulation_events, patterns, nudges providers | ✅ | All five provider files present |
| ReleaseRolloutState schema 3, 9 v2 flags | ✅ | release_rollout_provider.dart |
| Tantrum deck → user_cards migration on v2 flip | ✅ | _migrateTantrumDeckIfNeeded, guard key v2_tantrum_deck_migrated |
| cards_registry_v2.json (min 2 per trigger) | ✅ | 12 cards, 2 per type |
| CardContentService (load registry, selectBestCard, getCardById) | ✅ | card_content_service.dart; match-rule specificity used |

**Phase 0:** ✅ **Complete**

---

### Phase 1: Navigation Shell Swap + Plan Tab Core

| Item | Status | Notes |
|------|--------|--------|
| Two StatefulShellRoute configs (v1 vs v2) selected by v2NavigationEnabled | ✅ | _buildV1ShellRoute / _buildV2ShellRoute in router.dart |
| v2 nav items: Plan, Family, Sleep, Library | ✅ | _v2NavItems in router; passed to AppShell |
| SettleBottomNav accepts nav items from shell | ✅ | navItems passed from router → AppShell → SettleBottomNav |
| AppShell accepts overlay slot | ✅ | `overlay` parameter; Stack with child + overlay |
| Plan home screen at /plan | ✅ | PlanHomeScreen |
| Regulate First banner (when regulationLevel stressed/anxious/angry) | ✅ | GlassCardRose + CTA to /plan/regulate |
| Debrief section — "What's been hardest?" + 6 trigger pills | ✅ | DebriefSection; trigger order from triggerOrderByUsageProvider (Phase 7) |
| Prep nudge section | ✅ | PrepNudgeSection; "Based on your patterns" when approaching time-pattern window (Phase 7) |
| Output card widget (Prevent/Say/Do, ifEscalates, Save/Share/Log/Why) | ✅ | output_card.dart |
| /plan/regulate | ✅ | RegulateFlowScreen (full 5-step flow) |
| /plan/card/:id, /plan/log | ✅ | PlanCardScreen, TodayScreen |
| v2 redirects: /now, /home → /plan; /progress → /library; /tantrum → /plan; /sos → /plan/regulate or /breathe per regulateEnabled; /plan → /progress removed | ✅ | _compatibilityRoutes when v2NavigationEnabled |
| Pocket FAB / overlay in AppShell | ✅ | PocketFABAndOverlay when pocketEnabled (Week 2) |

**Phase 1:** ✅ **Complete**

---

### Phase 2: Onboarding Rebuild

| Item | Status | Notes |
|------|--------|--------|
| OnboardingV2Screen with 7-step flow | ✅ | onboarding_v2_screen.dart |
| Step 1: Child name + age (12mo–5yr slider, ageMonths, name fallback "your child") | ✅ | step_child_name_age.dart; _ageMonths, _nameController |
| Step 2: Parent type (FamilyStructure) | ✅ | step_parent_type.dart |
| Step 3: Hardest challenge (6 v2 trigger types) | ✅ | step_challenge_v2.dart |
| Step 4: Instant value card + Save to Playbook | ✅ | step_instant_value.dart; CardContentService.selectBestCard, userCardsProvider.save |
| Step 5: Regulation check (RegulationLevel) | ✅ | step_regulation_check.dart |
| Step 6: Partner invite (conditional) | ✅ | step_partner_invite.dart; shown for twoParents/coParent/withSupport |
| Step 7: Pricing (UI only) | ✅ | step_pricing.dart |
| BabyProfile from v2: name, ageMonths, ageBracket derived, familyStructure, regulationLevel, defaults (approach, primaryChallenge, feedingType, focusMode), sleepProfileComplete: false | ✅ | _finish() in onboarding_v2_screen.dart |
| Router /onboard conditional (v2OnboardingEnabled → OnboardingV2Screen) | ✅ | router.dart |
| Sleep mini-onboarding gate (Sleep tab when sleepProfileComplete == false) | ✅ | SleepMiniOnboardingGate in router v2 sleep branch |
| Sleep mini-onboarding screen (approach + feeding, then set sleepProfileComplete: true) | ✅ | SleepMiniOnboardingScreen; 5 approach options, 4 feeding; save → context.go('/sleep') |

**Phase 2:** ✅ **Complete**

---

### Phase 3: Library Tab + Output Cards

| Item | Status | Notes |
|------|--------|--------|
| Library home at /library | ✅ | LibraryHomeScreen |
| Your Patterns section (preview + link to /library/patterns) | ✅ | _PatternsPreviewCard; patternsProvider |
| Saved Playbook section (preview + link to /library/saved) | ✅ | _SavedPlaybookPreviewCard; userCardsProvider, CardContentService.getCards |
| Learn section (link to /library/learn) | ✅ | GlassCard + CTA to /library/learn |
| Logs section (link to /library/logs) | ✅ | GlassCard + CTA to /library/logs |
| /library/saved, /library/learn, /library/logs, /library/patterns, /library/cards/:id | ✅ | All routed; PlanCardScreen with fallbackRoute '/library' for cards/:id |

**Phase 3:** ✅ **Complete**

---

### Phase 4: Pocket Overlay

| Item | Status | Notes |
|------|--------|--------|
| Pocket FAB (bottom-right, above nav, glass style) | ✅ | pocket_fab.dart; used in PocketFABAndOverlay |
| Pocket modal (top pinned script, ifEscalates, CTAs, "regulate first" inline) | ✅ | pocket_overlay.dart; PocketOverlayBody (script \| regulate \| afterLog \| celebration) |
| Pocket after-use log (UsageEvent: outcome, context, regulationUsed) | ✅ | pocket_after_log.dart |
| AppShell overlay wired to Pocket when pocketEnabled | ✅ | Consumer in v2 shell; overlay = PocketFABAndOverlay when pocketEnabled |
| /pocket modal route | ✅ | No route; overlay-only (by design) |

**Phase 4:** ✅ **Complete** — Pocket FAB, overlay, after-log, micro-celebration on "This helped" (Week 2)

---

### Phase 5: Regulate Flow

| Item | Status | Notes |
|------|--------|--------|
| /plan/regulate route | ✅ | RegulateFlowScreen |
| Step 1: Acknowledge (RegulationTrigger) | ✅ | step_acknowledge.dart |
| Step 2: Physiological (4s in / 6s out vagal, 3 cycles) | ✅ | step_breathe.dart |
| Step 3: Cognitive reframe | ✅ | step_reframe.dart |
| Step 4: Actionable next step (CardContentService) | ✅ | step_action.dart |
| Step 5: Repair (if "already yelled") | ✅ | step_repair.dart |
| RegulationEvent on completion | ✅ | _finish() calls regulationEventsProvider.notifier.log() |
| /breathe, /sos → /plan/regulate when regulateEnabled | ✅ | /sos → /breathe when !regulateEnabled |

**Phase 5:** ✅ **Complete** — Full 5-step flow + RegulationEvent (Week 1)

---

### Phase 6: Family Tab

| Item | Status | Notes |
|------|--------|--------|
| Family home at /family | ✅ | FamilyHomeScreen (shared playbook CTA, invite placeholder) |
| /family/shared | ✅ | FamilyRulesScreen |
| /family/invite | ✅ | InviteScreen (deep link copy) |
| FamilyMember model (TypeId 59) | ✅ | family_member.dart |
| family_members_provider | ✅ | family_members_provider.dart |
| Activity feed (local UsageEvents) | ✅ | activity_feed.dart; /family/activity |
| Layout by FamilyStructure (twoParents/coParent vs single/withSupport) | ✅ | Members row for partner layouts; "Your support network" for single/withSupport |
| Invite flow MVP (deep link generation) | ✅ | Copy link; deep link URL generated |

**Phase 6:** ✅ **Complete** — FamilyMember, invite (deep link), activity feed, layout by FamilyStructure (Week 3)

---

### Phase 7: Smart Nudges + Pattern Engine

| Item | Status | Notes |
|------|--------|--------|
| pattern_engine.dart (time/strategy/regulation patterns, PatternInsight) | ✅ | pattern_engine.dart |
| nudge_scheduler.dart (predictable, pattern, content nudges) | ✅ | nudge_scheduler.dart |
| NotificationService extension for nudges | ✅ | schedulePlanNudge, cancelPlanNudges, _planNudgeChannel |
| Settings: per-nudge-type toggles, quiet hours, frequency | ✅ | Plan nudges section + nudge_settings_provider |

**Phase 7:** ✅ **Complete** — pattern_engine (Week 4); nudge_scheduler + settings (Week 5)

---

### Phase 8: Retention Features

| Item | Status | Notes |
|------|--------|--------|
| Weekly reflection (Sunday banner) | ✅ | weekly_reflection.dart; Plan + Library |
| Micro-celebration after "worked great" | ✅ | micro_celebration.dart; Pocket overlay |
| Monthly insight (in-app card) | ✅ | monthly_insight_screen.dart at /library/insights |
| Smart card ordering on Plan (UsageEvent-based trigger order) | ✅ | triggerOrderByUsageProvider in Plan (Phase 7) |

**Phase 8:** ✅ **Complete** — Weekly reflection, micro-celebration, monthly insight

---

## Step 3 — Gap Report

### Complete

- **Phase 0:** All models, enums, boxes, providers, flags, migration, card registry, CardContentService.
- **Phase 1:** v2 shell, Plan home, Debrief (trigger order by usage), Prep (pattern-based "approaching" copy), RegulateFlowScreen, Pocket overlay when pocketEnabled.
- **Phase 2:** Full v2 onboarding (7 steps), BabyProfile creation with defaults, sleep mini-onboarding gate and screen.
- **Phase 3:** Library home, saved playbook, patterns, learn, logs, insights, all subroutes and card detail.
- **Phase 4:** Pocket FAB, overlay (script / regulate / afterLog / celebration), after-use log, overlay wired when pocketEnabled.
- **Phase 5:** Full regulate flow (5 steps), RegulationEvent on completion; /sos → /plan/regulate or /breathe per regulateEnabled.
- **Phase 6:** FamilyMember, family_members_provider, invite screen (deep link), activity feed, layout by FamilyStructure.
- **Phase 7:** pattern_engine, nudge_scheduler, NotificationService plan nudges, Settings Plan nudges section.
- **Phase 8:** Weekly reflection banner, micro-celebration (Pocket), monthly insight screen.

### Partial

- None; all phases implemented per fix plan.

### Missing / not started

- None.

### Critical blockers (all resolved)

1. **Splash destination:** ✅ Splash reads `releaseRolloutProvider` and goes to `/plan` when v2+profile (Week 1).
2. **/sos redirect:** ✅ When `regulateEnabled` is false, `/sos` redirects to `/breathe`; when true, to `/plan/regulate` (router.dart).
3. **Regulate flow:** ✅ Full 5-step flow and RegulationEvent (Week 1).
4. **Pocket:** ✅ Pocket FAB, overlay, after-log, celebration (Week 2).
5. **Pattern engine:** ✅ pattern_engine + Prep "approaching" + trigger order (Weeks 4–5).

### Data flow / route resolution

- **Route resolution:** v2 shell and redirects resolve correctly for /plan, /family, /sleep, /library and compatibility paths. Router is built from Hive rollout state; refresh on flag change works.
- **Card content:** CardContentService loads registry; Plan and Library resolve cards by id; UserCard join records used correctly.
- **Profile:** v2 onboarding sets sleepProfileComplete: false; sleep mini-onboarding sets it true and fills approach/feedingType.

---

## Step 4 — Fix Plan

### Target state (reference)

- **File structure (v2):** Plan (plan_home_screen, debrief_section, prep_nudge_section, output_card), Library (library_home_screen, saved_playbook_screen, patterns_screen), Family (family_home_screen, invite_screen, shared_playbook_screen, activity_feed), Regulate (regulate_flow_screen + step_*.dart), Pocket (pocket_fab, pocket_overlay, pocket_after_log), Onboarding v2 + steps, Sleep mini-onboarding, Services (card_content_service, pattern_engine, nudge_scheduler), Models (FamilyMember 59), Phase 8 widgets.
- **Route table:** As in Step 1; add /pocket modal; /plan/regulate to full flow; /family/invite to real flow when built.

### Prioritized plan (week-by-week)

#### Week 1 — Regulate flow (Phase 5) + splash tweak ✅ DONE

- **Goal:** Replace /plan/regulate stub with full flow; create RegulationEvent on completion; optional: splash → /plan when v2.
- **Files created:**  
  - `lib/screens/regulate/regulate_flow_screen.dart` (orchestrator, steps 1–5, logs RegulationEvent on done).  
  - `lib/screens/regulate/step_acknowledge.dart` (RegulationTrigger picker).  
  - `lib/screens/regulate/step_breathe.dart` (vagal 4s in / 6s out, 3 cycles ~30s, then auto-advance).  
  - `lib/screens/regulate/step_reframe.dart`, `step_action.dart`, `step_repair.dart`.
- **Files modified:**  
  - `lib/router.dart`: /plan/regulate → RegulateFlowScreen; /sos when !regulateEnabled → /breathe.  
  - `lib/screens/splash.dart`: when profile exists and v2 nav enabled, go to `/plan` (reads releaseRolloutProvider).
- **Architecture:** Vagal circles driven by 10s cycle curve (0–0.4 inhale, 0.4–1.0 exhale); RegulationEvent written in _finish(); step_action uses CardContentService.selectBestCard(triggerType: 'overwhelmed').

#### Week 2 — Pocket (Phase 4) ✅ DONE

- **Goal:** Pocket FAB, modal with pinned script, after-use log (UsageEvent), "regulate first" inline option.
- **Files created:**  
  - `lib/widgets/pocket_fab.dart` (glass FAB, bottom-right above nav).  
  - `lib/screens/pocket/pocket_fab_and_overlay.dart` (ConsumerStatefulWidget: FAB + modal state; "This helped" → UsageEvent great + incrementUsage; "Didn't work" → after-log).  
  - `lib/screens/pocket/pocket_overlay.dart` (top pinned OutputCard, ifEscalates, CTAs, Different script / I need to regulate first / Done; PocketOverlayBody switches script | regulate | afterLog).  
  - `lib/screens/pocket/pocket_after_log.dart` (outcome, optional context, regulationUsed → UsageEvent).  
  - `lib/screens/pocket/pocket_inline_breathe.dart` (vagal 4s/6s inline, Back to script).
- **Files modified:**  
  - `lib/router.dart`: v2 shell builder wrapped in Consumer; when `releaseRolloutProvider.pocketEnabled`, overlay = PocketFABAndOverlay().
- **Architecture:** No /pocket route; overlay-only. FAB in Stack; tap opens modal (barrier + GlassCard with PocketOverlayBody). After log calls usageEventsProvider.notifier.log; "This helped" also calls userCardsProvider.incrementUsage.

#### Week 3 — Family MVP (Phase 6 completion) ✅ DONE

- **Goal:** FamilyMember model, family_members_provider, invite screen (deep-link generation), activity feed (local UsageEvents), layout hints by FamilyStructure.
- **Files created:**  
  - `lib/models/family_member.dart` (TypeId 59: id, name, role, invitedAt).  
  - `lib/providers/family_members_provider.dart` (backfill "You" from profile on first Family open; meta box for guard).  
  - `lib/screens/family/invite_screen.dart` (copy invite link; deep link MVP).  
  - `lib/screens/family/activity_feed.dart` (ActivityFeedScreen + ActivityFeedPreview; recent UsageEvents).
- **Files modified:**  
  - `lib/main.dart`: FamilyMemberAdapter; open family_members + family_members_meta.  
  - `lib/screens/family/family_home_screen.dart`: backfill on init; members row for twoParents/coParent/blended; "Your support network" for single/withSupport; Shared playbook, Invite, ActivityFeedPreview.  
  - `lib/router.dart`: /family/invite → InviteScreen; /family/activity → ActivityFeedScreen.
- **Architecture:** FamilyMember in Hive by id; backfill once via meta box.

#### Week 4 — Pattern engine + Prep reorder (Phase 7 start + Phase 1/8 tie-in) ✅ DONE

- **Goal:** pattern_engine.dart (time/strategy/regulation), persist PatternInsight via patternsProvider; Prep nudge section uses pattern data; Plan debrief trigger order by usage (smart card ordering).
- **Files created:**  
  - `lib/services/pattern_engine.dart` — pure Dart: `compute(usageEvents, regulationEvents, cardIdToTriggerType)` → List<PatternInsight> (time after 10+ usage; strategy per card after 5+ uses; regulation after 5+ events). `orderTriggersByUsage(usage, map)` → ordered trigger list.  
  - `lib/providers/plan_ordering_provider.dart` — `cardIdToTriggerTypeProvider` (FutureProvider from registry), `triggerOrderByUsageProvider` (Provider), `patternEngineRefreshProvider` (FutureProvider runs engine and setInsights).
- **Files modified:**  
  - `lib/screens/plan/prep_nudge_section.dart`: accepts `patterns`; shows "Based on your patterns: [insight]. Preview a script now?" when a time pattern exists and current time is approaching its window (regex for "H-H" in insight).  
  - `lib/screens/plan/plan_home_screen.dart`: watches `patternEngineRefreshProvider` (triggers run), `triggerOrderByUsageProvider` (passes to DebriefSection), `patternsProvider` (passes to PrepNudgeSection).
- **Architecture:** Engine run on Plan build via watch on patternEngineRefreshProvider; patterns persisted via patternsProvider.notifier.setInsights.

#### Week 5 — Nudge scheduler + settings (Phase 7 finish) ✅ DONE

- **Goal:** nudge_scheduler.dart (predictable, pattern, content); extend NotificationService; Settings: nudge toggles, quiet hours, frequency.
- **Files created:**  
  - `lib/providers/nudge_settings_provider.dart` — NudgeSettings (predictable/pattern/content toggles, quietStartHour/quietEndHour, NudgeFrequency), persisted in Hive box `nudge_settings`.  
  - `lib/services/nudge_scheduler.dart` — `scheduleNudges(profile, patterns, settings)`: cancels plan nudges; predictable = preferredBedtime − 30min; pattern = from first time-pattern insight 30min before window; content = age-based in 3 days at 10am. Respects quiet hours.
- **Files modified:**  
  - `lib/services/notification_service.dart`: _Ids.nudgePredictable/Pattern/Content (10–12); _planNudgeChannel; schedulePlanNudge(id, title, body, fireAt); cancelPlanNudges().  
  - `lib/screens/settings.dart`: "Plan nudges" section with _NudgeSettingsSection (toggles + frequency chips); on change persists and calls NudgeScheduler.scheduleNudges.  
  - `lib/screens/plan/plan_home_screen.dart`: one-shot schedule on first build when profile present.  
  - `lib/main.dart`: open `nudge_settings` box.
- **Architecture:** Settings UI triggers scheduler on change; Plan home triggers once per session when profile loads.

#### Week 6 — Retention (Phase 8) ✅ DONE

- **Goal:** Weekly reflection banner, micro-celebration after rating, monthly insight screen (in-app).
- **Files created:**  
  - `lib/widgets/weekly_reflection.dart` — `WeeklyReflectionBanner.shouldShow(startHour)` (Sunday, hour ≥ 17); banner with "Reflect on your week" + CTA to /library/logs; optional onDismiss.  
  - `lib/widgets/micro_celebration.dart` — `MicroCelebration(message, duration, onDismiss)`; tap or auto-dismiss after 2s.  
  - `lib/screens/library/monthly_insight_screen.dart` — scripts used, "worked great" count, regulation resets this month; "By situation" breakdown by trigger type.
- **Files modified:**  
  - `lib/screens/pocket/pocket_overlay.dart`: `PocketOverlayView.celebration`; `PocketOverlayBody` shows `MicroCelebration` with `onCelebrationDismiss`.  
  - `lib/screens/pocket/pocket_fab_and_overlay.dart`: "This helped" → log then set view to celebration; on dismiss close overlay.  
  - `lib/screens/plan/plan_home_screen.dart`: show `WeeklyReflectionBanner` when `shouldShow()` and not dismissed; dismiss hides for session.  
  - `lib/screens/library/library_home_screen.dart`: show `WeeklyReflectionBanner` when Sunday evening; add `_MonthlyInsightCard` linking to /library/insights.  
  - `lib/router.dart`: `/library/insights` → `MonthlyInsightScreen`.
- **Architecture:** Weekly reflection = Sunday 5pm+; micro-celebration only on Pocket "This helped"; monthly insight reads usage + regulation providers, current month filter.

### Architecture decisions to confirm

1. **Splash and rollout:** Splash currently has no ref to rollout. To send to /plan when v2, either (a) pass rollout from a parent that has ref, or (b) read Hive directly in splash (same box as router). Prefer (a) for consistency.
2. **Regulate flow navigation:** Linear 1→2→3→4→5 with skip for "needMinute" (skip reframe); state in RegulateFlowScreen or small state-notifier.
3. **Pocket entry:** Modal from FAB tap; no dedicated route vs /pocket — recommend overlay only (no route) to avoid back-stack complexity.
4. **Pattern engine trigger:** Run after N new UsageEvents or on Plan tab focus; avoid heavy work on every keystroke.
5. **FamilyMember storage:** Hive box `family_members`; key by id or index; backfill in family_members_provider when box is first opened and profile exists.

---

## Summary Table

| Phase | Status | Blockers / notes |
|-------|--------|------------------|
| 0 | ✅ Complete | — |
| 1 | ✅ Complete | Debrief trigger order, Prep patterns, Regulate flow, Pocket overlay |
| 2 | ✅ Complete | — |
| 3 | ✅ Complete | — |
| 4 | ✅ Complete | Pocket FAB, overlay, after-log wired when pocketEnabled |
| 5 | ✅ Complete | Full regulate flow + RegulationEvent (Week 1) |
| 6 | ✅ Complete | FamilyMember, activity feed, invite (deep link MVP), layout by FamilyStructure |
| 7 | ✅ Complete | pattern_engine, nudge_scheduler, settings |
| 8 | ✅ Complete | Weekly reflection, micro-celebration, monthly insight (smart order in Phase 7) |

**Suggested order of implementation:** Phase 5 (regulate) → Phase 4 (Pocket) → Phase 6 (family) → Phase 7 (patterns + nudges) → Phase 8 (retention), with splash v2 destination as a quick win during Phase 5.
