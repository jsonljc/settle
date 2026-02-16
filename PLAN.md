# Settle v2.0 Implementation Plan (Audit-Revised)

## Codebase Audit Findings

Full audit completed against all models, providers, screens, router, engines, services, and assets. The original plan is structurally sound. Below are corrections, gaps, and refinements discovered.

---

## Current State Summary

**What exists (v1):**
- 4-tab shell: Help Now | Sleep | Progress | Tantrum
- Onboarding: 5-7 steps (name, age, focus mode, family, sleep/tantrum setup)
- Sleep module: full (wake windows, rhythm, tonight, adaptive scheduler)
- Tantrum module: full (capture, cards, deck, insights, crisis view)
- Help Now: incident guidance with age-band mapping
- Progress: plan progress + logs + learn
- SOS/Breathe: breathing exercise overlay
- Family Rules: caregiver scripts
- Design system: glass morphism, tokens, stagger animations
- Persistence: Hive with type adapters
- Notifications: wake window + wind-down + schedule drift

**What v2 spec asks for:**
- 4-tab shell: Plan | Family | Sleep | Library + Pocket overlay
- Completely new onboarding flow (7 screens, parent-type segmentation)
- Plan tab: Debrief + Prep + Regulate (replaces Help Now + Tantrum + Progress)
- Family tab: partner/caregiver sync (new)
- Library tab: saved playbook + learn + patterns (replaces Progress)
- Pocket: floating overlay for in-moment scripts (new)
- Regulate flow: multi-step parent emotional support (evolves SOS)
- Pattern detection engine (new)
- Smart nudge system (new)
- Usage event tracking + "did this help?" (new)
- Output card format: Prevent / Say / Do (evolves tantrum cards)

---

## Migration Strategy: Incremental, Not Big-Bang

The v2 spec is a substantial product pivot. Rather than rewrite everything, we'll **migrate incrementally** using feature flags, preserving all existing working code and progressively replacing surfaces.

### Phase 0: Foundation & Data Model Extensions
### Phase 1: Navigation Shell Swap + Plan Tab Core
### Phase 2: Onboarding Rebuild
### Phase 3: Library Tab + Output Cards
### Phase 4: Pocket Overlay
### Phase 5: Regulate Flow
### Phase 6: Family Tab
### Phase 7: Smart Nudges + Pattern Engine
### Phase 8: Retention Features

---

## Audit Corrections & Gaps

### Correction 1: UserCard Model — Separate Content from User State

**Original plan:** `UserCard` (TypeId 50) stores both card content (preventLine, sayLine, doLine) AND user state (pinned, savedAt, usageCount).

**Problem:** Current tantrum cards live in `tantrum_registry_v1.json` and are loaded via `TantrumCardSelectorService` — card content is never persisted to Hive. Only `TantrumEvent.selectedCardId` references which card was used.

**Fix:** `UserCard` should be a **join record only**:
- `{ cardId (String), pinned (bool), savedAt (DateTime), usageCount (int), lastUsed (DateTime?) }`
- Card content stays in `cards_registry_v2.json`, loaded via `CardContentService`
- This avoids duplicating content across Hive + JSON and keeps JSON as single source of truth

### Correction 2: BabyProfile Field Types

**Original plan:** `@HiveField(9) String? regulationLevel` and `@HiveField(11) String? childAge`

**Fix:**
- `regulationLevel` should be a **Hive enum** (`RegulationLevel`, TypeId 43) — not a String. Every other profile field uses typed enums; a String would break the pattern and lose type safety.
- `childAge` as freeform String is redundant with `ageBracket`. The v2 spec wants a **month-precise age slider** (12mo–5yr). Better: `@HiveField(11) int? ageMonths`. The existing `ageBracket` can be derived from `ageMonths` for backward compatibility with engines.

**Revised BabyProfile extensions:**
```
@HiveField(9)  RegulationLevel? regulationLevel  // new Hive enum (TypeId 43)
@HiveField(10) String? preferredBedtime           // "19:00"
@HiveField(11) int? ageMonths                     // precise age, ageBracket derived
```

### Gap 1: Sleep Onboarding Deferral

The v2 onboarding drops sleep-specific setup (approach, challenge, feeding). But `BabyProfile` has `approach`, `primaryChallenge`, and `feedingType` as **required non-nullable fields**. All sleep engines depend on these.

**Solution:** Two parts:
1. v2 onboarding sets sensible defaults for these fields (e.g., `Approach.stayAndSupport`, `PrimaryChallenge.fallingAsleep`, `FeedingType.solids`)
2. Build a **sleep mini-onboarding** that triggers on first Sleep tab visit when profile was created via v2 onboarding. This collects the real approach + feeding type before Sleep Tonight works.

**New flag needed on BabyProfile:** `@HiveField(12) bool? sleepProfileComplete` — false for v2 onboarding users until they complete sleep mini-onboarding.

### Gap 2: Legacy Redirect Updates

The router has **14+ legacy redirect routes** (e.g., `/home` → `/now`, `/plan` → `/progress`, `/sos` → `/breathe`). When `v2NavigationEnabled` is true:
- `/now` must redirect to `/plan` (not the other way around)
- `/progress` must redirect to `/library`
- `/tantrum` must redirect to `/plan`
- `/plan` redirect to `/progress` must be **removed** (since `/plan` is the primary route)
- `/sos` redirect to `/breathe` must redirect to `/plan/regulate` instead
- All notification deep links must check the v2 flag and route appropriately

### Gap 3: FocusMode Retirement

v1 uses `FocusMode` (sleepOnly/tantrumOnly/both) to control tab visibility and feature access. v2 eliminates this — everyone gets Plan+Family+Sleep+Library.

**No migration needed** — `FocusMode` becomes dead code when `v2NavigationEnabled` is true. It continues working for v1 users.

### Gap 4: New Enums Need TypeIds

The plan mentions enum values for UsageEvent.outcome, RegulationEvent.trigger, etc. but doesn't assign TypeIds. Each Hive enum needs its own TypeId:

| New Enum | TypeId | Values |
|----------|--------|--------|
| `RegulationLevel` | 43 | calm, stressed, anxious, angry |
| `UsageOutcome` | 55 | great, okay, didntWork, didntTry |
| `RegulationTrigger` | 56 | aboutToLoseIt, childMelting, alreadyYelled, needMinute |
| `PatternType` | 57 | time, strategy, regulation |
| `NudgeType` | 58 | predictable, pattern, content, family |

TypeIds 44-54 are skipped to leave room near existing enums and models.

### Gap 5: build_runner After Model Changes

Every new Hive model/enum needs `.g.dart` codegen. Must run after each model phase:
```
dart run build_runner build --delete-conflicting-outputs
```

### Gap 6: Card Content Authoring

The v2 spec assumes cards for 6 behavior categories (transitions, bedtime battles, public meltdowns, "no" to everything, sibling conflict, I'm overwhelmed). The existing `tantrum_registry_v1.json` has ~20 cards focused on tantrum triggers.

**Strategy:** Create `cards_registry_v2.json` fresh. Keep the existing specificity-scoring match system from `TantrumCardSelectorService` — it works well. Port relevant existing cards (especially transition cards) with format change (remember → prevent). Author new cards for non-tantrum categories.

**Minimum viable set:** 2 cards per trigger type (12 cards total) for Phase 0/1. Expand to 4+ per type iteratively.

### Gap 7: BabyProfile Constructor + copyWith Alignment

Adding HiveFields 9-12 is not sufficient by itself. `BabyProfile` constructor and `copyWith` must also be updated to safely handle the new fields.

**Implementation note:**
- Keep existing sentinel behavior for `tantrumProfile` (nullable + explicit clear)
- For new nullable primitives/enum fields (`regulationLevel`, `preferredBedtime`, `ageMonths`, `sleepProfileComplete`), standard null-coalescing in `copyWith` is sufficient

### Gap 8: Bottom Nav Configurability

`SettleBottomNav` is currently hardcoded to the v1 4-tab set. v2 rollout needs tab configuration to come from routing/shell context.

**Implementation note:**
- Make nav items an input model passed from `AppShell`
- Derive items from `v2NavigationEnabled` at router shell build time

### Gap 9: Router Structure for v1/v2 Shell

Conditional branch swapping inside one shell route will get brittle quickly. The cleaner structure is two complete `StatefulShellRoute` trees selected at router build time.

**Implementation note:**
- Keep existing v1 shell route unchanged
- Add a separate v2 shell route definition
- Choose one using `v2NavigationEnabled`

### Gap 10: Pocket FAB Placement

Pocket requires overlap behavior relative to bottom nav. `Scaffold.floatingActionButton` positioning constraints are too rigid for this requirement.

**Implementation note:**
- Place Pocket FAB in an `AppShell` `Scaffold.body` `Stack` overlay
- Anchor to bottom-right with explicit offset above the nav bar

### Gap 11: Child Name in v2 Onboarding

Spec copy references `[child's name]` across Plan/Regulate/Nudges. Name capture should not be deferred.

**Decision:** Add a quick child-name input to onboarding Screen 1 alongside age.
- If skipped: store fallback display name `"your child"`

### Gap 12: Tantrum Deck State Migration

v1 tantrum deck state (`savedIds`, `pinnedIds`, `favoriteIds` in `tantrum_deck`) must migrate to v2 `UserCard` records when users first enter v2 nav.

**Migration trigger:**
- One-time migration when `v2NavigationEnabled` flips false → true
- Idempotent guard key in rollout box to prevent re-running

---

## Phase 0: Foundation & Data Model Extensions

**Goal:** Extend models and persistence to support v2 without breaking v1.

### 0a. New Hive Enums

Add to `approach.dart`:
- `RegulationLevel` (TypeId 43): calm, stressed, anxious, angry
- Extend `FamilyStructure` with: `@HiveField(4) coParent`, `@HiveField(5) blended`

New file `lib/models/v2_enums.dart`:
- `UsageOutcome` (TypeId 55): great, okay, didntWork, didntTry
- `RegulationTrigger` (TypeId 56): aboutToLoseIt, childMelting, alreadyYelled, needMinute
- `PatternType` (TypeId 57): time, strategy, regulation
- `NudgeType` (TypeId 58): predictable, pattern, content, family

### 0b. New Hive Models

1. **`UserCard`** (TypeId 50) — user's relationship to a card (join record)
   - 0: `cardId` (String)
   - 1: `pinned` (bool)
   - 2: `savedAt` (DateTime)
   - 3: `usageCount` (int)
   - 4: `lastUsed` (DateTime?)

2. **`UsageEvent`** (TypeId 51) — tracks every card use
   - 0: `cardId` (String)
   - 1: `timestamp` (DateTime)
   - 2: `outcome` (UsageOutcome?)
   - 3: `context` (String?)
   - 4: `regulationUsed` (bool)

3. **`RegulationEvent`** (TypeId 52) — tracks parent regulation usage
   - 0: `timestamp` (DateTime)
   - 1: `trigger` (RegulationTrigger)
   - 2: `completed` (bool)
   - 3: `durationSeconds` (int)

4. **`PatternInsight`** (TypeId 53) — generated insights
   - 0: `patternType` (PatternType)
   - 1: `insight` (String)
   - 2: `confidence` (double)
   - 3: `basedOnEvents` (int)
   - 4: `createdAt` (DateTime)

5. **`NudgeRecord`** (TypeId 54) — sent notification tracking
   - 0: `nudgeType` (NudgeType)
   - 1: `sentAt` (DateTime)
   - 2: `opened` (bool)
   - 3: `actedOn` (bool)

### 0c. Extended Existing Models

**`BabyProfile`** — add new nullable HiveFields (backward-compatible):
- `@HiveField(9) RegulationLevel? regulationLevel`
- `@HiveField(10) String? preferredBedtime`
- `@HiveField(11) int? ageMonths`
- `@HiveField(12) bool? sleepProfileComplete`
- Update constructor to accept new optional fields with safe defaults
- Update `copyWith` to include new fields (retain sentinel only for `tantrumProfile`)

**`FamilyStructure` enum** — add:
- `@HiveField(4) coParent`
- `@HiveField(5) blended`

Update `FamilyStructure.label` getter for new values.

### 0d. New Hive Boxes

`'user_cards'`, `'usage_events'`, `'regulation_events'`, `'patterns'`, `'nudges'`

### 0e. New Providers (Scaffolded)

- `userCardsProvider` — manages saved output cards (CRUD + pin/unpin)
- `usageEventsProvider` — logs usage events, queries by card/time
- `regulationEventsProvider` — logs regulation events
- `patternsProvider` — generated pattern insights (read-only, populated by PatternEngine)
- `nudgesProvider` — sent nudge tracking

### 0f. New Feature Flags

Add to `ReleaseRolloutState` (bump schema to 3):
- `v2NavigationEnabled` (default false) — master switch for new nav shell
- `v2OnboardingEnabled` (default false)
- `planTabEnabled` (default false)
- `familyTabEnabled` (default false)
- `libraryTabEnabled` (default false)
- `pocketEnabled` (default false)
- `regulateEnabled` (default false)
- `smartNudgesEnabled` (default false)
- `patternDetectionEnabled` (default false)

### 0g. Card Content Registry

Create `assets/guidance/cards_registry_v2.json`:
- Format: `{ id, triggerType, prevent, say, do, ifEscalates?, evidence?, ageRange? }`
- Minimum 2 cards per v2 trigger type (transitions, bedtime_battles, public_meltdowns, no_to_everything, sibling_conflict, overwhelmed)
- Keep match-rule specificity scoring from tantrum card selector

Create `lib/services/card_content_service.dart`:
- Loads registry JSON
- Finds best card for a trigger type (reuses specificity scoring logic from `TantrumCardSelectorService`)
- Returns card content by ID

### 0h. Step-by-Step Order Within Phase 0

1. Add `RegulationLevel` enum to `approach.dart`, extend `FamilyStructure`
2. Create `lib/models/v2_enums.dart` with UsageOutcome, RegulationTrigger, PatternType, NudgeType
3. Add HiveFields 9-12 to `BabyProfile` + update constructor/copyWith
4. Create 5 new model files
5. Run `build_runner`
6. Register all new adapters in `main.dart`
7. Open 5 new Hive boxes in `main.dart`
8. Create 5 new provider files
9. Add 9 feature flags to `ReleaseRolloutState`, bump schema to 3
10. Add one-time `tantrum_deck` → `user_cards` migration (run when `v2NavigationEnabled` flips on)
11. Create `cards_registry_v2.json` with minimum card set
12. Create `CardContentService`

**Files to create/modify:**
- `lib/models/approach.dart` (extend)
- `lib/models/v2_enums.dart` (new)
- `lib/models/user_card.dart` (new)
- `lib/models/usage_event.dart` (new)
- `lib/models/regulation_event.dart` (new)
- `lib/models/pattern_insight.dart` (new)
- `lib/models/nudge_record.dart` (new)
- `lib/models/baby_profile.dart` (extend)
- `lib/providers/user_cards_provider.dart` (new)
- `lib/providers/usage_events_provider.dart` (new)
- `lib/providers/regulation_events_provider.dart` (new)
- `lib/providers/patterns_provider.dart` (new)
- `lib/providers/nudges_provider.dart` (new)
- `lib/providers/release_rollout_provider.dart` (extend)
- `lib/main.dart` (register new adapters, open new boxes)
- `lib/providers/tantrum_providers.dart` (migration read source)
- `lib/services/card_content_service.dart` (new)
- `assets/guidance/cards_registry_v2.json` (new)

---

## Phase 1: Navigation Shell Swap + Plan Tab Core

**Goal:** Replace the 4-tab layout with the new Plan | Family | Sleep | Library tabs, gated behind `v2NavigationEnabled`.

### 1a. New Navigation Shell

- New bottom nav: Plan (home icon) | Family (people icon) | Sleep (moon icon) | Library (book icon)
- Plan becomes default `/plan` route (was `/now`)
- Family is new `/family` route
- Sleep stays `/sleep`
- Library replaces Progress at `/library`
- Build **two full `StatefulShellRoute` configs** (v1 + v2) and select one by `v2NavigationEnabled` at router build time
- Make `SettleBottomNav` item list configurable via `AppShell` constructor (no hardcoded static tabs)
- Update **all 14+ legacy redirects** to be v2-aware:
  - `/now` → `/plan`, `/home` → `/plan`
  - `/progress` → `/library`
  - `/tantrum`, `/tantrum/capture` → `/plan`
  - Remove `/plan` → `/progress` redirect
  - `/sos`, `/breathe` → `/plan/regulate` (when regulateEnabled)
  - `/rules`, `/family-rules` → `/family/shared`

### 1b. Plan Tab Home Screen

**Route:** `/plan`

The Plan tab consolidates Help Now + Tantrum capture into a unified "debrief" flow.

**Layout (above fold):**
1. **Regulate First banner** (conditional) — shows if `regulationLevel` is stressed/angry/anxious OR user used regulate 2+ times in past week
2. **Debrief section** — "What's been hardest?" with personalized trigger list (max 6 items). Taps produce an inline output card.
3. **Prep nudges** (conditional) — approaching known pattern times

The trigger list starts with the spec's 6 defaults (Transitions, Bedtime battles, Public meltdowns, "No" to everything, Sibling conflict, I'm overwhelmed) and over time reorders based on `UsageEvent` frequency.

### 1c. Output Card Widget

The shared card component used everywhere (Plan, Pocket, Library):
```
[Scenario badge]
Prevent: [1 line, bold, 12-15 words]
Say: [large text, 10 words max]
Do: [1 line, 12 words]
[Optional "If escalates →" expandable]
---
[Primary: "Save to Playbook"]
[Secondary: "Share with partner" | "Log how it went" | "See why this works"]
```

Evidence pop-up: "See why this works" opens modal overlay.

### 1d. Plan Subroutes

- `/plan/regulate` — opens Regulate flow (Phase 5, stub for now → redirects to `/breathe`)
- `/plan/card/:id` — full-screen output card view
- `/plan/log` — optional logging (reuse existing `TodayScreen` adapted)

**Files to create/modify:**
- `lib/router.dart` (dual shell route configs + redirect updates)
- `lib/widgets/settle_bottom_nav.dart` (accept nav items from shell)
- `lib/screens/app_shell.dart` (accept nav items + support overlay stack region)
- `lib/screens/plan/plan_home_screen.dart` (new)
- `lib/screens/plan/debrief_section.dart` (new)
- `lib/screens/plan/prep_nudge_section.dart` (new)
- `lib/widgets/output_card.dart` (new)

---

## Phase 2: Onboarding Rebuild

**Goal:** Replace current onboarding with the 7-screen v2 flow.

### Flow:
1. **Child Name + Age** — quick name field + slider (12mo–5yr), stores `name`, `ageMonths`, derives `ageBracket`
2. **Parent Type** — single-column list mapping to `FamilyStructure` (together/coParent/single/blended/withSupport)
3. **Hardest Challenge** — 6 items (v2 trigger types, NOT v1 `PrimaryChallenge`)
4. **Instant Value** — first output card from `CardContentService` based on challenge. "Save to My Playbook" CTA.
5. **Regulation Check** — how do you feel? Maps to `RegulationLevel` enum. If not calm, show regulate preview.
6. **Partner Invite** — conditional (if twoParents/coParent/withSupport). Preview Family tab.
7. **Pricing** — trial flow (RevenueCat integration deferred; show UI only)

### BabyProfile Creation (v2):
- Sets: `name` (fallback `"your child"` when skipped), `ageMonths`, derived `ageBracket`, `familyStructure`, `regulationLevel`, `preferredBedtime` (optional)
- Sets defaults: `approach = stayAndSupport`, `primaryChallenge = fallingAsleep`, `feedingType = solids`, `focusMode = both`
- Sets: `sleepProfileComplete = false`
- Name collection: captured in Screen 1 with optional skip

### Sleep Mini-Onboarding (First Sleep Tab Visit):
When `sleepProfileComplete == false` and user taps Sleep tab:
1. Quick approach selection (5 options, same as v1 StepSetup)
2. Quick feeding type (4 options)
3. Sets `sleepProfileComplete = true`
This unblocks all sleep engines.

**Files to create/modify:**
- `lib/screens/onboarding/onboarding_v2_screen.dart` (new)
- `lib/screens/onboarding/steps/step_child_name_age.dart` (new)
- `lib/screens/onboarding/steps/step_parent_type.dart` (new)
- `lib/screens/onboarding/steps/step_challenge_v2.dart` (new)
- `lib/screens/onboarding/steps/step_instant_value.dart` (new)
- `lib/screens/onboarding/steps/step_regulation_check.dart` (new)
- `lib/screens/onboarding/steps/step_partner_invite.dart` (new)
- `lib/screens/onboarding/steps/step_pricing.dart` (new)
- `lib/screens/sleep/sleep_mini_onboarding.dart` (new)
- `lib/router.dart` (conditional onboarding route)

---

## Phase 3: Library Tab + Output Cards

**Goal:** Build the Library tab with saved playbook, learn content, and patterns.

### 3a. Library Home

**Route:** `/library`

**Layout:**
1. **Your Patterns** (section) — generated insights (stub until Phase 7)
2. **Saved Playbook** — list of saved `UserCard`s, organized by `triggerType`
3. **Learn** — evidence-based content (migrates existing `LearnScreen`)
4. **Logs** (optional) — quiet weekly list (migrates existing `TodayScreen`)

### 3b. Subroutes:
- `/library/saved` — saved cards (full list)
- `/library/learn` — Q&A content
- `/library/patterns` — pattern insights view (populated by Phase 7)
- `/library/cards/:id` — card detail (uses `OutputCard` widget)

**Files to create/modify:**
- `lib/screens/library/library_home_screen.dart` (new)
- `lib/screens/library/saved_playbook_screen.dart` (new)
- `lib/screens/library/patterns_screen.dart` (new)
- `lib/router.dart` (add library branch + subroutes)

---

## Phase 4: Pocket Overlay

**Goal:** Build the floating Pocket button and modal overlay for in-moment support.

### 4a. Floating Action Button

Global overlay button visible on all tabs (when `pocketEnabled`). Positioned bottom-right, above bottom nav. Uses glass morphism styling.

**Placement rule:**
- Render Pocket FAB inside `AppShell` `Scaffold.body` `Stack` overlay (not `Scaffold.floatingActionButton`) to guarantee overlap and animation control with custom bottom nav.

### 4b. Pocket Modal

Opens as modal overlay. Shows:
1. Top pinned script (OutputCard widget with pinned `UserCard`)
2. "If escalates" expansion
3. CTAs: "This helped" / "Didn't work this time"
4. Secondary: "Different script" (if >1 pinned), "I need to regulate first", "Done"
5. If "regulate first" → inline breathing circle (adapted from SOS, 4s in / 6s out vagal tone) → back to script

### 4c. After Use (Key Data Collection)

Quick log → creates `UsageEvent`:
- Outcome: great / okay / didntWork / didntTry
- Optional free text context
- regulationUsed: true if they used inline breathing

**Files to create/modify:**
- `lib/widgets/pocket_fab.dart` (new)
- `lib/screens/pocket/pocket_overlay.dart` (new)
- `lib/screens/pocket/pocket_after_log.dart` (new)
- `lib/screens/app_shell.dart` (add Pocket FAB as Stack overlay)
- `lib/router.dart` (add `/pocket` modal route)

---

## Phase 5: Regulate Flow

**Goal:** Build the multi-step parent regulation flow, evolving the existing SOS/Breathe screen.

### Flow (Route: `/plan/regulate`):

1. **Acknowledge** — "You're having a hard moment too." Select situation (maps to `RegulationTrigger`).
2. **Physiological Regulation** — guided breathing with expanding/contracting circle. **Changed from SOS box breathing (5s phases) to vagal tone (4s in, 6s out)**. Auto-advances after 3 cycles (~30s).
3. **Cognitive Reframe** — "This isn't personal" + developmental context. Skipped if "need a minute" trigger.
4. **Actionable Next Step** — context-aware Say/Do script from `CardContentService`.
5. **After/Repair** — if "already yelled", shows repair scripts.

### Reuse from SOS:
- 3 concentric breathing circles animation (change timing constants)
- `_selfRegScripts` list (expand with context-aware content)
- Crisis resources disclosure (988, PSI hotline)

### New: Creates `RegulationEvent` on completion.

**Files to create/modify:**
- `lib/screens/regulate/regulate_flow_screen.dart` (new)
- `lib/screens/regulate/step_acknowledge.dart` (new)
- `lib/screens/regulate/step_breathe.dart` (new, adapted from SOS circles)
- `lib/screens/regulate/step_reframe.dart` (new)
- `lib/screens/regulate/step_action.dart` (new)
- `lib/screens/regulate/step_repair.dart` (new)
- `lib/router.dart` (update `/plan/regulate` from stub to real, `/breathe` → `/plan/regulate` redirect)

---

## Phase 6: Family Tab

**Goal:** Build the Family tab for partner/caregiver coordination.

**MVP: Local-only.** Backend sync (Firebase/Supabase) is a separate infrastructure workstream.

### 6a. Family Home (Route: `/family`)

**Layout varies by FamilyStructure:**

**For twoParents/coParent/blended:**
1. Active family members (avatar row + invite CTA)
2. Shared playbook (saved `UserCard`s)
3. Activity feed (local `UsageEvent`s)
4. Sync status (alignment score — deferred until backend)

**For singleParent/withSupport:**
1. "Your support network" framing
2. Invite caregivers (grandparents, babysitters, etc.)
3. Your playbook as shareable view

### 6b. Invite Flow (Route: `/family/invite`)
- Email/phone input or copy invite link
- **MVP: generates a deep link** (actual delivery deferred to backend)
- Shows "included in your plan" messaging

### 6c. Subroutes
- `/family/home` — overview
- `/family/invite` — invite flow
- `/family/shared` — shared playbook view (migrates Family Rules concept)

### 6d. FamilyMember MVP Model

Family UI needs a local persisted member row even before backend sync.

- Add `FamilyMember` Hive model (TypeId 59)
- Minimum fields: `name`, `role`, `invitedAt`
- Backfill from current profile as initial member record on first Family tab open

**Files to create/modify:**
- `lib/models/family_member.dart` (new)
- `lib/providers/family_members_provider.dart` (new)
- `lib/screens/family/family_home_screen.dart` (new)
- `lib/screens/family/invite_screen.dart` (new)
- `lib/screens/family/shared_playbook_screen.dart` (new)
- `lib/screens/family/activity_feed.dart` (new)
- `lib/router.dart` (add family branch + subroutes)

---

## Phase 7: Smart Nudges + Pattern Engine

**Goal:** Build proactive notification system and pattern detection.

### 7a. Pattern Detection Engine

`lib/services/pattern_engine.dart` (new) — **pure computation engine** (no Flutter deps), consistent with WakeEngine/TantrumEngine pattern.

**Time Patterns** (after 10+ `UsageEvent`s):
- Day-of-week + time-of-day distribution analysis
- Output: "Transitions hardest Tue-Thu 4-6pm"

**Strategy Patterns** (after 5+ uses of same card):
- Outcome ratings per card
- Output: "'2 warnings' works great (8/10 times)"

**Regulation Patterns** (after 5+ `RegulationEvent`s):
- Time-of-day + trigger type analysis
- Output: "You stay calmest mornings"

Creates `PatternInsight` records, persisted via `patternsProvider`.

### 7b. Smart Nudge Scheduler

`lib/services/nudge_scheduler.dart` (new) — extends existing `NotificationService`:

**A) Predictable Moment Nudges** — `preferredBedtime` - 30min → "Bedtime prep in 30min"
**B) Pattern-Based Nudges** — from `PatternInsight`s after 2+ weeks
**C) Content Nudges** — age-based milestones from `ageMonths`
**D) Family Sync Nudges** — deferred until backend

### 7c. Notification Settings Extension

Extend Settings screen with:
- Per-nudge-type toggles
- Quiet hours (default 8pm–7am)
- Frequency: Smart (2-3/week) | More | Minimal

**Files to create/modify:**
- `lib/services/pattern_engine.dart` (new)
- `lib/services/nudge_scheduler.dart` (new)
- `lib/screens/settings.dart` (extend notification section)

---

## Phase 8: Retention Features

**Goal:** Weekly reflection, micro-celebrations, monthly insights.

### 8a. Weekly Reflection (Sunday evening in-app banner)
- "What helped most this week?"
- Shows: script usage count, calm moments, consistency
- Quick tap to select most helpful → feeds `PatternEngine`

### 8b. Micro-Celebrations
- After "worked great" rating → gentle animation + affirming message
- No streaks, no guilt metrics, no share pressure

### 8c. Monthly Insight (in-app card)
- Transition success rates, bedtime trends, regulation usage
- Tone: supportive coach
- (Email delivery deferred — requires email infrastructure)

### 8d. Smart Card Ordering
- Plan home reorders trigger list based on: frequency, time patterns, success ratings
- Implemented in `CardContentService` using `UsageEvent` data

**Files to create/modify:**
- `lib/widgets/weekly_reflection.dart` (new)
- `lib/widgets/micro_celebration.dart` (new)
- `lib/screens/library/monthly_insight_screen.dart` (new)

---

## What Gets Retired vs Preserved

### Retired (behind v2NavigationEnabled flag):
- Help Now tab → absorbed into Plan tab debrief
- Tantrum tab → cards migrate to unified output cards
- Progress tab → becomes Library tab
- Current onboarding → replaced by v2 onboarding (behind v2OnboardingEnabled)
- FocusMode concept → everyone gets all tabs in v2

### Preserved as-is:
- Sleep tab (all screens, rhythm, tonight, update)
- SOS breathing exercise (code preserved, adapted into Regulate flow)
- Design system (tokens, glass components, stagger patterns)
- All engines (WakeEngine, AdaptiveScheduler, RhythmEngine)
- All sleep-related providers and models
- Notification infrastructure (extended with nudge scheduler)

### Migrated:
- Tantrum cards → unified output cards (remember → prevent, same say/do/ifEscalates)
- Tantrum insights + plan progress → Pattern engine + Library/Patterns
- Family Rules → shared playbook concept in Family tab
- SOS breathing → Regulate flow step_breathe (timing changed to 4s/6s vagal tone)

---

## Implementation Order & Dependencies

```
Phase 0 ──→ Phase 1 ──→ Phase 2
  (data)      (nav+plan)   (onboarding)
                │
                ├──→ Phase 3 (library)
                │
                ├──→ Phase 4 (pocket)
                │
                ├──→ Phase 5 (regulate)
                │
                └──→ Phase 6 (family)
                       │
                       └──→ Phase 7 (nudges+patterns)
                              │
                              └──→ Phase 8 (retention)
```

Phases 2-6 can be developed in parallel after Phase 1 lands.
Phase 7 depends on usage data accumulating (Phase 4's "did this help?" flow).
Phase 8 depends on Phase 7's pattern engine.

---

## Hive TypeId Allocation Map (Complete)

| Range | Current Use | v2 Addition |
|-------|------------|-------------|
| 0-4 | Approach, AgeBracket, FamilyStructure, PrimaryChallenge, FeedingType | — |
| 10-13 | BabyProfile, SleepSession, NightWake, DayPlan | — |
| 30-38 | FocusMode, TantrumType, TriggerType, ParentPattern, ResponsePriority, TantrumIntensity, PatternTrend, NormalizationStatus, DayBucket | — |
| 40-42 | TantrumProfile, TantrumEvent, WeeklyTantrumPattern | — |
| 43 | — | RegulationLevel |
| 44-49 | — | Reserved |
| 50-54 | — | UserCard, UsageEvent, RegulationEvent, PatternInsight, NudgeRecord |
| 55-58 | — | UsageOutcome, RegulationTrigger, PatternType, NudgeType |
| 59 | — | FamilyMember |

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Sleep onboarding gap | **High** | Build sleep mini-onboarding (Phase 2); set defaults for required fields |
| BabyProfile required fields | **Medium** | v2 onboarding sets sensible defaults; real values collected in sleep mini-onboarding |
| Card content authoring | **High** | Start with 12 cards (2 per trigger); expand iteratively |
| Notification deep links | **Medium** | All redirects conditional on v2NavigationEnabled flag |
| Family tab backend | **Low** (deferred) | Build UI-only MVP; sync requires Firebase/Supabase — separate workstream |
| Pricing/subscription | **Low** (deferred) | Show UI only; RevenueCat integration is separate workstream |
| Tantrum deck migration correctness | **Medium** | One-time idempotent migration on v2 flag flip; add migration tests for saved/pinned/favorite cases |

---

## Locked Decisions

1. **Child name in onboarding:** include quick name input on Screen 1 (fallback `"your child"`).
2. **Card matching:** reuse existing specificity-scoring strategy from tantrum selector.
3. **Sleep mini-onboarding UX:** bottom sheet on first Sleep-tab visit.
4. **Family MVP scope:** local-only with deep-link invite generation.
5. **Router architecture:** two full `StatefulShellRoute` trees (v1/v2), selected by rollout flag.
6. **Pocket FAB placement:** `AppShell` body `Stack` overlay, not scaffold FAB slot.
