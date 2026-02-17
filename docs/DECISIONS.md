# Settle — Decision Log

> One line per decision. Stops agents from re-litigating what's already been decided.
> Format: `Date · Decision · Why · Impacted files`

**See also:** [CANON.md](CANON.md) (locked decisions, precedence), [wireframes/WIREFRAMES.md](wireframes/WIREFRAMES.md) (screen spec).

---

## How to use this file

- **Before proposing a change**, search this log. If the decision has been made, follow it.
- **After making a decision**, add it here. One line. No essays.
- Decisions are listed newest-first within each category.

---

## Navigation & Tab Structure

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2025-02 | Sleep tab has no Tonight/Rhythm toggle — Tonight is the tab, Rhythm is a passive summary line | Toggle risked 3am parents landing on Rhythm setup | `wireframes/WIREFRAMES.md` S0, all Sleep routes |
| 2025-02 | Tantrum tab uses two visible tiles, not a segmented toggle | Toggles hide content; post-meltdown parents need "Just happened" visible immediately | `wireframes/WIREFRAMES.md` T0 |
| 2025-02 | Tab order is Reset · Sleep · Tantrum · Playbook (left to right) | Reset is hero action; leftmost = most thumb-accessible for right-handed parent holding child | Tab bar component, router config |
| 2025-02 | Moment is a widget/shortcut, not a tab | It's a 10s reflex tool — doesn't warrant persistent nav space | Widget config, shortcut config |
| 2025-02 | Screen S1 (Tonight situation chooser) eliminated — tiles on S0 go direct to S2 | One fewer screen = one fewer decision for a sleep-deprived parent | `wireframes/WIREFRAMES.md` S0→S2 routing |
| 2025-02 | Playbook stays as a tab (revisit if <20% unprompted visits after 4 weeks of usage data) | Needs real data to justify demotion to drawer | Tab bar, `wireframes/WIREFRAMES.md` P0 |

## Onboarding & Personalization

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2025-02 | Parenting style removed from onboarding — discovered post-3rd-Reset (R5) | Forcing self-categorization at 2am is premature and anxiety-inducing | `wireframes/WIREFRAMES.md` O3, R5 |
| 2025-02 | Onboarding is exactly 4 screens: O1→O2→O3→O4 | Every screen must earn its existence; 4 gets to first value in <60s | `wireframes/WIREFRAMES.md` O1–O4, onboarding router |
| 2025-02 | O2 defaults to age-range chips, not a date picker | Faster, less cognitive load; exact birthdate available one tap deeper | `wireframes/WIREFRAMES.md` O2 |
| 2025-02 | "Stress" renamed to "Big feelings" in O3 | More specific, less clinical, signals emotional vocabulary | `wireframes/WIREFRAMES.md` O3 copy |
| 2025-02 | Style options are "Warmth first" / "Structure first" / "No preference" — not "Responsive" / "Gentle" / "Structured" | Avoids identity labels; focuses on output the parent wants | `wireframes/WIREFRAMES.md` R5, `PRODUCT_ARCHITECTURE_v1_3.md` §9, Settings ST2 |

## Reset Flow

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2025-02 | Max 3 "Another" swaps per session — then button disappears (not grayed out) | Prevents doom-scrolling through advice; disappearing is cleaner than disabled | `wireframes/WIREFRAMES.md` R3 |
| 2025-02 | Soft friction threshold is 4+ resets within 2 hours | "Heavy + repeated" was too vague to implement; this is codeable | `wireframes/WIREFRAMES.md` R1, `PRODUCT_ARCHITECTURE_v1_3.md` §2 |
| 2025-02 | R2 framing changed to "What needs attention?" with "How I feel" / "How they feel" | Previous "I feel bad" / "They're still upset" was a false binary — both are usually true | `wireframes/WIREFRAMES.md` R2 |
| 2025-02 | "Share" renamed to "Send" throughout | Active verb; implies sending to co-parent, not generic social sharing | `wireframes/WIREFRAMES.md` R3, R4, P1, all copy |
| 2025-02 | Card sharing (R4) promoted from optional to first-class flow | Co-parent texting "say this when you go in" is the strongest organic growth loop | `wireframes/WIREFRAMES.md` R4 |

## Sleep Flow

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2025-02 | Rhythm setup uses smart defaults (bedtime auto-calculated from wake time + nap count) | Parents shouldn't calculate; the app suggests, they adjust | `wireframes/WIREFRAMES.md` S4 |
| 2025-02 | Nap count options are stage-limited | Prevents impossible configs (3-year-old selecting 4 naps) | `wireframes/WIREFRAMES.md` S4 step 2 |
| 2025-02 | "Not now" changed to "I'm good" on Close moment (S3) | "Not now" implies obligation; "I'm good" validates the parent's state | `wireframes/WIREFRAMES.md` S3 |
| 2025-02 | If user picks "I'm good" 3+ times consecutively, suppress S3 for 7 days | Respect the signal; don't nag | `wireframes/WIREFRAMES.md` S3 logic |

## Tantrum Flow

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2025-02 | Debrief (T2) triggers: 2nd+ tantrum-context Reset same calendar day AND not shown today yet | Tightened from three vague signals to one codeable condition | `wireframes/WIREFRAMES.md` T2 |
| 2025-02 | Debrief categories use parent language: "Told no" not "Denied request," "Wanted control" not "Power struggle" | Less adversarial framing; child is not an opponent | `wireframes/WIREFRAMES.md` T2 copy |
| 2025-02 | "Sensory" removed from debrief options in v1 | Too clinical for most parents; sensory processing deserves its own handling later | `wireframes/WIREFRAMES.md` T2 |
| 2025-02 | Prevention cards (T3): max 3 per visit, same 3 if revisited same day, new set daily | Prevents overwhelm; daily refresh keeps content feeling alive | `wireframes/WIREFRAMES.md` T3 |

## Sharing & Co-parenting

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2026-02 | Shared card payloads use standalone text-only copy (no app suffix/chrome) across Reset, Sleep, and Playbook send actions | Recipients should understand and use the script immediately without context | `lib/screens/plan/reset_flow_screen.dart`, `lib/screens/sleep_tonight.dart`, `lib/screens/library/playbook_card_detail_screen.dart`, `lib/screens/library/saved_playbook_screen.dart` |
| 2025-02 | v1 sharing is native OS share sheet only — no sync, no shared accounts | Local-only architecture constraint; co-parent features are v2 | `PRODUCT_ARCHITECTURE_v1_3.md` §7 |
| 2025-02 | Co-parent invite prompt shown once after 5th Reset | User has experienced enough value to recommend by then | `wireframes/WIREFRAMES.md` §H |

## Notifications

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2026-02 | Drift nudge wording uses calm check-in framing ("Rhythm check-in"), not alert framing | Reduce alarm tone and preserve emotional safety | `lib/services/notification_service.dart` |
| 2025-02 | Evening check-in timed to 1hr before configured bedtime (or 6pm default) | Context-aware timing; not arbitrary | `PRODUCT_ARCHITECTURE_v1_3.md` §8, Settings ST3 |
| 2025-02 | No daily nudges, no streak pressure, no "we miss you" — ever | Parents are overloaded; the app must not become another demand | `PRODUCT_ARCHITECTURE_v1_3.md` §8 |

## Technical

| Date | Decision | Why | Impacted files |
|------|----------|-----|----------------|
| 2026-02 | Moment script assets are capped to two short sentences per variant | Keep in-moment reading load minimal and deterministic | `assets/guidance/moment_scripts.json` |
| 2025-02 | v1 is fully local — no server, no analytics SDK | Simplicity, privacy, speed; server features are v2 | `PRODUCT_ARCHITECTURE_v1_3.md` §13 |
| 2025-02 | Events stored locally only (timestamp + category + card_id) | Powers personalization without server dependency | `wireframes/WIREFRAMES.md` §L |
| 2025-02 | If storage fails, app falls back to universal content | Graceful degradation; never crash, never block | `PRODUCT_ARCHITECTURE_v1_3.md` §13 |
| 2025-02 | Stage derived from age, not manually configured | Parents shouldn't assess their child's development; birthdate is enough | `PRODUCT_ARCHITECTURE_v1_3.md` §13, Settings ST1 |

---

## Adding a new decision

Copy this template and add it to the appropriate category:

```
| YYYY-MM | <what was decided> | <why, in one phrase> | <files affected> |
```

Keep it to one line. If you need more than one line, you're explaining too much.
