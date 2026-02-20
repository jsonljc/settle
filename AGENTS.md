# AGENTS.md (Settle)

This file is the single source of truth for how we build Settle. If anything conflicts, **this wins**.

**Related docs:** When this file is silent, follow [docs/CANON.md](docs/CANON.md) for precedence. See also [docs/UX_RULES.md](docs/UX_RULES.md) (7 Laws, anti-patterns), [docs/ACCESSIBILITY.md](docs/ACCESSIBILITY.md) (a11y fail conditions), [docs/DECISIONS.md](docs/DECISIONS.md) (decision log), [docs/PRODUCT_ARCHITECTURE_v1_3.md](docs/PRODUCT_ARCHITECTURE_v1_3.md) (product spec), [docs/wireframes/WIREFRAMES.md](docs/wireframes/WIREFRAMES.md) (screen-by-screen UX).

**Parallel agents:** Cursor = implementation (UI, routes, core). Codex = verification (tests, lint, docs). Use separate worktrees/branches — see [docs/PARALLEL_AGENTS_SETUP.md](docs/PARALLEL_AGENTS_SETUP.md).

---

## North Star

Settle is built for **sleep-deprived, emotionally flooded parents**. The app must reduce cognitive load and get them to the next right step fast.

But crisis is the acquisition hook, not the retention engine. Most parent-weeks aren't crisis. Settle must also be valuable on ordinary days — or parents will install it at 2am, use it once, and forget it.

**The full promise:** In stressful moments, Settle gets you to the next right step in seconds. On normal days, Settle keeps your family's rhythm visible so you don't have to hold it all in your head.

---

## Non-negotiables

1. **20-second win (crisis flows):** open flow → actionable guidance visible in ≤ 20 seconds.
2. **Rhythm is the daily home screen:** not a settings page, not buried in Sleep. The default daily experience is "here's your plan for today."
3. **No "timer-as-the-product":** do not center the experience on timing parents during a crisis.
4. **Crisis flows must be light:** no dense scenario forms before showing help.
5. **Method integrity:** if a parent chooses an approach, guidance must stay consistent with that approach. Alternatives are optional, clearly labeled, and never sprung mid-flow.
6. **Offline-first:** core scripts and today's rhythm must work without internet.
7. **Calm by design:** fewer choices, bigger type, more whitespace, no clutter.
8. **Expert-authored content:** all crisis scripts must be authored or reviewed by a credentialed specialist. No guidance ships without clinical review. (See Content Authorship below.)
9. **Both parents, same plan:** Family sharing is a first-class feature, not a bolt-on. Both caregivers see the same rhythm, same scripts, same progress.

---

## Information Architecture (v2 — canonical)

> **Migration note:** v1 navigation (Help Now / Sleep / Tantrums / Progress) is deprecated. v2 is the active IA for all new users. Legacy v1 routes redirect to v2 equivalents. Do not build new features against v1 paths.

### Bottom nav (3 tabs + 2 overlays)

| Tab | Purpose | Mental model |
|-----|---------|--------------|
| **Now** | Crisis flows — sleep, tantrums, regulation | "During" — something is happening |
| **Sleep** | Tonight scenarios + Rhythm (daily surface) | "Before / Plan" — preparing and maintaining |
| **Library** | Logs, learn content, after-incident review | "After" — reflecting and growing |

| Overlay | Purpose |
|---------|---------|
| **Family** | Shared rhythm, shared scripts, caregiver sync, activity feed |
| **Settings** | Child profiles, method preferences, notifications, account |

### Pocket (crisis shortcut)

Persistent mini-launcher accessible from any tab. Surfaces 2–3 contextual crisis entries (e.g., "Night wake", "Tantrum now", "I need to regulate"). Pocket replaces Help Now as the crisis entry point — it's always reachable without navigating away from the current context.

### Default screen behavior

- **First open of the day:** Land on Sleep tab → Rhythm daily view ("Here's today").
- **Pocket tap:** Expand crisis options contextually (nighttime window → sleep scenarios first; daytime → tantrum/regulation first).
- **Deep links / notifications:** Land directly inside the relevant flow, never on a generic hub.

### Nighttime handoff rule

If it's within the configurable nighttime window and the user opens the app or taps Pocket, default suggestions toward Sleep Tonight scenarios first, with a visible switch to other crisis flows.

---

## Rhythm: The Daily Surface

Rhythm is Settle's retention engine. It answers the question "what do I do today?" even when nothing is going wrong.

### What Rhythm shows daily

- Child's expected windows for the day (naps, feeds, bedtime) anchored from wake time.
- What to do at each transition (brief, actionable — not a wall of text).
- Simple end-of-day check-in: "How did today go?" (1-tap rating, optional note).
- Current plan context: "Day 4 of your sleep plan. Bedtime target: 7:15pm."

### Rhythm rules

- Rhythm is generated from a simple input: wake time anchor + child age + chosen method. Not a 15-field form.
- Rhythm outputs **windows** (flex ranges), not rigid minute-by-minute schedules.
- "Repeat this routine for the next 7 days" is the default. Adjust weekly, not daily.
- If a time is missed, guidance adapts calmly. No red warnings, no guilt.
- Both caregivers see the same rhythm when Family is connected.

### Rhythm is not

- A tracker (Settle does not require parents to log every feed/diaper to get value).
- A settings screen that you configure once and forget.
- Dependent on historical data to be useful on day 1.

---

## Crisis Flow Pattern (standard)

All crisis flows follow the same skeleton:

- **Step 0 (optional):** 1 quick selection if needed (2–4 options max, big tap targets).
- **Step 1:** Show first actionable guidance immediately. Big text, one step, no preamble.
- **Step 2+:** "Next step" advances. "Try a different style" available but never forced.
- **End:** "Worked?" (Yes / Not quite).
  - If "Not quite": offer 2–3 alternate paths (no typing required).
  - Optional: 1-line note.
  - Data feeds into Progress.

### Crisis flow constraints

- No scrolling required to find the primary CTA.
- Steps are 1–2 sentences max.
- Never show more than 4 options in a crisis context.
- Never require typing during a crisis flow.
- Must work offline.

---

## Progress: The Feedback Loop

Progress answers "is this working?" — the question every sleep-training parent asks at 3am on night 3.

### What Progress shows

- **Weekly trend:** simple visualization of the metric that matters most (e.g., night wakes this week vs last week, tantrum frequency, bedtime duration).
- **Supportive framing:** "Night wakes went from 3 to 1. The first few nights are the hardest — you're past that." Never punitive, never clinical.
- **Plan context:** "You're on day 8 of gentle return. Most families see improvement by day 10."
- **What worked:** aggregated micro-check data ("gentle return worked 4/5 times this week").

### Progress rules

- Progress must be useful with minimal input. The "Worked? / Not quite" micro-check from crisis flows is the primary data source. Do not require parents to log separately.
- Trends require at least 3 data points before showing. Don't show a graph on day 1.
- All framing is supportive. No red/green judgement colors. No "you failed" states.
- Progress is personal by default. When Family is connected, both caregivers see shared progress.

### Progress is not

- A medical record or clinical assessment.
- A leaderboard or comparison to other families.
- Dependent on comprehensive tracking (feeds, diapers, etc.) to function.

---

## Family

Family sharing is a growth multiplier and retention lever. When both caregivers use the same app with the same plan, consistency improves outcomes, and Settle becomes household infrastructure rather than a single-parent tool.

### Family scope (v1)

- **Shared rhythm:** both caregivers see the same daily plan.
- **Shared scripts:** both caregivers get the same crisis guidance for the same method.
- **Shared progress:** both see the same "is this working?" data.
- **Activity feed:** lightweight log of what happened ("Dad used gentle return at 2:15am — worked").
- **Invite flow:** simple invite link, no account creation required for the second caregiver until they accept.

### Family rules

- Family is opt-in. Single-parent households must never feel like they're missing a core feature.
- Shared data is clearly labeled. Parents must know what the other caregiver can see.
- Conflicts (e.g., different method preferences) are surfaced gently, not blocked. "You and [partner] have different sleep method preferences. Want to align?"
- Family features degrade gracefully if one caregiver is offline.

### Family is not (v1)

- Extended family / grandparent access (future consideration).
- A messaging or chat system.
- A co-parenting coordination tool for separated parents (different product).

---

## Content Authorship

Settle's value proposition depends entirely on the quality and trustworthiness of the guidance. This is not negotiable.

### Authorship requirements

- All crisis scripts (sleep, tantrum, regulation) must be **authored or reviewed by a credentialed pediatric specialist** — sleep consultant, child psychologist, pediatric nurse, or equivalent.
- The authoring specialist and their credentials must be documentable and, where agreed, attributable in the app ("Guidance reviewed by [Name], Certified Pediatric Sleep Consultant").
- Scripts must cite their methodological basis (e.g., "Based on graduated extinction," "Aligned with Collaborative & Proactive Solutions").

### Content review process

- New scripts: authored by specialist → structured into registry format → UX review for readability at crisis cognitive load → QA → ship.
- Script updates: same review cycle. No hotfixing guidance copy without specialist sign-off.
- Method additions: adding a new sleep or tantrum methodology requires a full content plan (specialist author, all flow steps, edge cases, "not working" branches) before any code is written.

### Content is not

- AI-generated at runtime. AI can help draft and iterate during authoring. The shipped guidance is static, deterministic, and human-reviewed.
- Generic. Every script must be specific to the scenario, child age range, and chosen method.
- Permanent. Scripts should be versioned and updated as evidence evolves, with a lightweight changelog.

---

## Registry-First Rule (copy + flows)

- **No hardcoded UX copy** in widgets. All user-facing strings use registry keys (e.g., `t("sleep.nightwake.step1")`).
- Flows are **deterministic** and registry-driven (JSON → UI runner). The flow engine reads a flow definition and renders steps. Adding a new flow means adding a new JSON definition, not writing new screen code.
- Registry supports entitlement gating: specific flows or content can be marked as free-tier or paid-tier without code changes.

---

## Offline-First

Crisis flows and today's rhythm must work without internet. This is non-negotiable.

### Technical approach

- Core script registry (all crisis flow definitions) is **bundled in the app binary** at build time.
- Today's rhythm plan is generated locally from inputs already on device (wake time, child age, method preference).
- Background sync updates the registry when connectivity is available. Updates are applied on next app launch, never mid-session.
- Progress data is written to local storage (Hive) first, synced to backend when available. Conflict resolution: last-write-wins per record.
- Family sync requires connectivity. When offline, the app shows the last-synced family state with a subtle "last updated [time]" indicator. No error modals.

---

## Monetization Model

> This section defines the free/paid boundary so that architecture decisions (registry gating, entitlements, onboarding flow) account for it from the start.

### Free tier (acquisition)

- Full access to crisis flows: Sleep Tonight (night wake, bedtime protest, early wake), Tantrum Now, Regulate (parent self-regulation).
- Basic rhythm: set wake time + bedtime, see today's windows.
- "Worked? / Not quite" micro-check.
- Single-caregiver use.

Free crisis flows are the acquisition hook. A parent at 2am must get value before being asked to pay.

### Paid tier (retention)

- **Rhythm+:** full daily plan with transition guidance, weekly rhythm review, plan duration tracking ("Day 4 of 14").
- **Progress:** trend visualizations, weekly summaries, supportive plan-context framing.
- **Family:** shared rhythm, shared progress, activity feed, caregiver invite.
- **Method library:** access to multiple sleep/tantrum methodologies beyond the default.
- **Personalized plan framing:** "Most families using gentle return see improvement by night 5. You're on night 3."

### Pricing guidance

- Target: $8–10/month or $80–100/year. Competitive with Huckleberry ($60–120/year) while reflecting the guidance value validated by course platforms ($99–180 one-time).
- Free trial: 7–14 days of full access after onboarding, then graceful downgrade to free tier.
- No hard paywall during a crisis flow. Ever.

---

## Growth and Distribution

> AGENTS.md is primarily a build document, but product decisions must account for how parents find Settle. Distribution is not someone else's problem.

### Acquisition model

Settle's primary acquisition channel is **word-of-mouth from a crisis moment that worked.** A parent who gets help at 2am tells every parent friend they have. The product must be built to enable this:

- **Shareability:** after a crisis flow, offer a lightweight share prompt ("This helped me tonight — share Settle with a friend"). Not aggressive, not required. Just available.
- **Family invite as growth:** every Family invite is a new user. The invite flow must be frictionless (link → install → see shared rhythm immediately).
- **Expert partnerships:** pediatricians, sleep consultants, and lactation consultants are the most trusted referral sources for new parents. Settle should be recommendable by professionals. This means: no pseudoscience, clear methodology attribution, and a professional-facing summary page.

### What we don't do (v1)

- Paid performance marketing (budget-dependent, not sustainable at early stage).
- Influencer partnerships (credibility risk if not carefully managed).
- Content marketing / SEO blog (resource-intensive, slow payoff).

### What we track

- Organic install source (where did you hear about Settle?).
- Family invite conversion rate.
- "Share with a friend" tap rate and downstream installs.
- NPS or similar after 2 weeks of use.

---

---

## Architecture Expectations

### Structure

Feature-first, predictable state, boring and testable.

```
lib/
  ui/          # widgets, screens, presentational components
  state/       # controllers, providers (Riverpod)
  domain/      # models, rules, flow definitions
  data/        # storage adapters (Hive), sync, registry loader
  theme/       # tokens, theme, glass components
```

> **Migration note:** the current codebase uses `screens/`, `widgets/`, `providers/`, `services/`. The target structure above should be adopted incrementally. Do not do a big-bang folder rename. Migrate feature-by-feature as screens are touched.

### State/UI boundary

Screens must not import from `data/` or call services directly. All data access goes through a controller/provider in `state/`. This is the P0 issue from the architecture audit — screens like `plan_home_screen.dart`, `sleep_tonight.dart`, and `help_now.dart` currently violate this boundary.

### Component standards

- Use `SettleChip` for selection controls (not local chip implementations).
- Use `SettleTappable` for interactive elements (not bare `GestureDetector`).
- Use `SettleModalSheet` for bottom sheets.
- All new interactive elements should include `Semantics` labels where applicable.

### Accessibility

- `Semantics(header: true)` on all `ScreenHeader` instances.
- `MergeSemantics` on compound controls where it improves screen reader order.

---

## Codebase Safety & Change Control

- Small atomic commits only.
- Avoid mega refactors unless explicitly planned and scoped.
- If a task is "add Tantrums", treat Sleep logic/registry as **read-only by default** except for navigation entry points.
- No screen may import directly from `lib/services/` — enforce via lint rule.

---

## AI Pairing Workflow

- Use short prompts + screenshots/wireframes.
- Work in vertical slices: UI → state → persistence → polish → tests.
- Always include a short QA checklist after changes.
- Before building a new flow, confirm: registry definition exists, specialist review is complete, free/paid tier is assigned.

---

## Safety & Trust

- Settle provides general parenting guidance, not medical advice. This distinction must be clear in onboarding and in any flow that touches health-adjacent topics.
- Safety language must be calm and non-alarming.
- If a situation indicates immediate danger (child not breathing, injury, parent in crisis), direct to local emergency / professional help with minimal text and a clear action (call button).
- Never present guidance as a substitute for professional consultation when a child has a diagnosed condition or when symptoms suggest one.

---

## Document Sync Status

> This section tracks alignment between AGENTS.md and the codebase / other docs. Update when discrepancies are resolved.

| Item | AGENTS.md says | Codebase status | Action needed |
|------|---------------|-----------------|---------------|
| IA | v2: Now / Sleep / Library + overlays | v2 shipped, v1 redirects active | Remove v1 dead code (Stage 0 of routing revert) |
| Rhythm | Daily home screen | Settings-style screens (CurrentRhythm, UpdateRhythm) | Rebuild as daily surface on Sleep tab |
| Family | First-class feature with shared rhythm | Tab exists, half-built (invites, rules, feed) | Scope to shared rhythm + progress for v1, defer extended family |
| Progress | Trend + supportive framing | "Worked/Not quite" micro-check exists; no trend visualization | Build weekly trend view + plan context |
| Content authorship | Specialist-reviewed, documented | No formal review process documented | Establish process before shipping new flows |
| Folder structure | `ui/state/domain/data/` | `screens/widgets/providers/services/` | Migrate incrementally per feature |
| Offline | Bundled registry + local rhythm | Hive for persistence, no explicit bundle strategy | Confirm registry bundling in build pipeline |
| Monetization | Free crisis + paid rhythm/progress/family | No entitlement gating in registry | Add tier field to flow definitions |
