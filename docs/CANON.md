# Settle — Canon & Decision Control

> This file is the supreme authority. When any two documents conflict, this file determines which one wins.

**Related docs:** [PRODUCT_ARCHITECTURE_v1_3.md](PRODUCT_ARCHITECTURE_v1_3.md), [wireframes/WIREFRAMES.md](wireframes/WIREFRAMES.md), [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md), [UX_RULES.md](UX_RULES.md), [ACCESSIBILITY.md](ACCESSIBILITY.md), [DECISIONS.md](DECISIONS.md).

---

## Document Precedence (highest → lowest)

When guidance conflicts across docs, follow this order:

1. **AGENTS.md** — Agent behavior rules, routing, implementation constraints
2. **docs/CANON.md** (this file) — Precedence rules, locked decisions
3. **docs/PRODUCT_ARCHITECTURE_v1_3.md** — Product identity, what Settle is and is not
4. **docs/wireframes/WIREFRAMES.md** — Screen-by-screen UX spec, state machines, copy
5. **docs/DESIGN_SYSTEM.md** — Tokens, components, visual rules
6. **docs/UX_RULES.md** — Interaction laws, formatting constraints
7. **docs/ACCESSIBILITY.md** — A11y requirements, fail conditions
8. **docs/DECISIONS.md** — Decision log (reference, not authority)
9. **GitHub Issues / PRs** — Tactical implementation items

**Rule:** If a lower-ranked doc says something that contradicts a higher-ranked doc, the higher-ranked doc wins. Always. No exceptions. Do not attempt to reconcile — follow the higher-ranked source.

---

## Locked Decisions (do not change)

These 20 decisions are settled. No agent, PR, or conversation may reverse them without an explicit human override tagged `[CANON OVERRIDE]` in the commit message.

### Product identity

1. **Settle is a post-moment recovery tool.** Not a crisis app, tracker, course, or meditation product.
2. **The hero loop is: event → Reset → repair → save → Playbook → internalize.** No steps are added or removed from this loop.
3. **Reset is a 15-second closure ritual.** It is not a coaching session, a debrief, or an analysis tool.
4. **Success = parents need Settle less over time.** Anti-addictive by design. No engagement traps.

### Navigation & structure

5. **Four tabs: Reset · Sleep · Tantrum · Playbook.** No fifth tab. Moment is a widget/shortcut, not a tab.
6. **Reset is the leftmost tab.** It is the center of gravity and the most thumb-accessible position.
7. **Sleep tab has no toggle.** Tonight is the hero surface. Rhythm is a passive background config shown as a summary line beneath the tiles.
8. **Tantrum tab shows two tiles, not a toggle.** "Just happened" and "Prepare for next time" are always visible.
9. **Playbook holds two content types:** repair cards (from Reset) and prevention cards (from Tantrum). Both are first-class.
10. **Moment is not a tab.** It lives on the lock screen widget, in-app chips, and app shortcuts.

### Onboarding & personalization

11. **Parenting style is not asked during onboarding.** It is discovered after the 3rd Reset via a low-pressure overlay (R5).
12. **Onboarding has exactly 4 screens:** Welcome → Child basics → Why you're here → Value promise. No more.
13. **O2 (Child basics) is the only screen with input fields.** Every other interaction in the entire app is taps and selections.
14. **Style affects card emphasis, not app structure.** Both warmth-first and structure-first users see the same screens, same flows, same options.

### Technical boundaries

15. **v1 is fully local.** No server, no sync, no accounts, no analytics SDK. All data on device.
16. **If storage fails, the app still works.** Personalization degrades gracefully to universal content.
17. **Every flow must end.** No open-ended states. Close moment is the universal exit pattern.
18. **Stage is derived from age, not configured.** Manual override exists in Settings but is buried.

### Tone & content

19. **No dashboards, charts, counters, streaks, or scores.** Anywhere. Ever.
20. **Notifications whisper.** Evening check-in and rare pattern-based nudges only. No daily nudges, no streak pressure, no "we miss you."

---

## How to propose a canon change

1. Open a GitHub Issue titled `[CANON PROPOSAL] <decision number> — <what you want to change>`
2. State the current locked decision
3. State the proposed change and why
4. Tag the issue for human review
5. Do not implement until a human approves and the commit includes `[CANON OVERRIDE]`

No agent may self-approve a canon change.
