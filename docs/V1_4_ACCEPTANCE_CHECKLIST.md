# Settle v1.4 Acceptance Checklist

- [ ] Preserve product identity: Settle remains a post-moment recovery tool (relief + repair + prevention), not a tracker, dashboard, course, or engagement system.
- [ ] Maintain locked navigation/entry decisions: tab model and flow entry behavior match `docs/DECISIONS.md` and `docs/PRODUCT_ARCHITECTURE_v1_3.md` (including Moment as shortcut, not a full tab lane).
- [ ] Enforce one-primary-action hierarchy per screen/section; secondary actions are visibly lower emphasis.
- [ ] Deliver usable value in 15 seconds or less from any flow entry (and within ~5 seconds for direct crisis entries).
- [ ] Keep copy calm and low-load: short blocks (about 1-2 short sentences), no dense paragraphs, no judgmental/guilt-inducing tone.
- [ ] Keep interaction lightweight: no forms outside onboarding O2; use taps/chips/toggles/time pickers instead of keyboard input.
- [ ] Ensure every flow has a clear end state (Close moment or direct equivalent); no dead ends.
- [ ] Keep Reset "sacred": no bloat, max 3 `Another` swaps/session, and soft friction only at 4+ resets in 2 hours.
- [ ] Keep Sleep tactical: Tonight is the hero lane, scenarios stay micro-flow length, Rhythm is supportive/passive (not a dashboard lane).
- [ ] Keep Tantrum post-event: `Just happened` routes into Reset, debrief appears only under locked trigger conditions, and prevention is capped to 3 cards/visit.
- [ ] Keep Moment minimal: 10-second haptic regulation, two script choices, tap-to-close, optional later handoff to Reset.
- [ ] Keep Playbook as sanctuary: saved repair/prevention cards plus supportive resurfacing; no charts, counters, streaks, scores, or punitive framing.
- [ ] Respect sharing/notification boundaries: native share sheet co-parent sharing in v1, no forced social loops, and no pressure notifications (no streaks/"we miss you").
- [ ] Enforce design-system calm baseline: token spacing/type, approved primitives, accent reserved for primary CTA, rose/red only for urgent safety, SOS/Regulate on `T.pal.focusBackground`, and accessibility minimums (44x44 tap targets, large text support, reduced motion).

## Final Audit (2026-02-17)

- [FAIL] Preserve product identity (no tracker/dashboard): dashboard-style stats/charts still exist in `lib/screens/today.dart:1`, `lib/screens/today.dart:399`, `lib/screens/today.dart:424`, `lib/screens/library/patterns_screen.dart:72`.
- [FAIL] Maintain locked navigation/entry decisions from v1.3 docs: shell nav labels are `Home/Family/Sleep/Library` in `lib/router.dart:47`, `lib/router.dart:52`, `lib/router.dart:57`, `lib/router.dart:62`, which diverges from v1.3 tab model.
- [FAIL] One primary action hierarchy: multiple primary CTAs remain on Reset (`lib/screens/plan/reset_flow_screen.dart:211`, `lib/screens/plan/reset_flow_screen.dart:213`) and Sleep close step (`lib/screens/sleep_tonight.dart:1479`, `lib/screens/sleep_tonight.dart:1482`).
- [PASS] 15-second value in core crisis flows: smoke test coverage passes in `test/domain_flow_contract_smoke_test.dart` (Moment, Sleep Tonight entry, Tantrum→Reset, Reset constraints).
- [FAIL] Calm/low-load copy density everywhere: several repair cards still exceed 3-sentence density (`assets/guidance/repair_cards_seed.json:5`, `assets/guidance/repair_cards_seed.json:25`, `assets/guidance/repair_cards_seed.json:85`, `assets/guidance/repair_cards_seed.json:105`).
- [FAIL] No forms outside onboarding O2: keyboard fields remain in non-onboarding flows (`lib/screens/family_rules.dart:282`, `lib/screens/plan/plan_script_log_screen.dart:164`, `lib/screens/sleep_tonight.dart:319`, `lib/screens/current_rhythm_screen.dart:162`).
- [PASS] Clear end-state/closure in core guided flows: Reset and Moment both close safely (`lib/screens/plan/reset_flow_screen.dart:262`, `lib/screens/plan/reset_flow_screen.dart:267`, `lib/screens/plan/moment_flow_screen.dart:92`, `lib/screens/plan/moment_flow_screen.dart:95`).
- [FAIL] Reset sacred rule fully met: max `Another` is enforced (`lib/providers/reset_flow_provider.dart:30`), but 4+ resets/2h soft-friction behavior is not implemented in flow/UI.
- [FAIL] Sleep tactical lane only: Sleep flow still includes recap text input and multi-action clusters (`lib/screens/sleep_tonight.dart:319`, `lib/screens/sleep_tonight.dart:1479`, `lib/screens/sleep_tonight.dart:1482`).
- [FAIL] Tantrum constraints fully proven: routing to Reset is present (`lib/router.dart:237`), but checklist conditions for debrief trigger gating and prevention-card cap are not fully verifiable from current active v2 flow code.
- [PASS] Moment minimal design: 10-second calm + two script choices are implemented (`lib/screens/plan/moment_flow_screen.dart:41`, `lib/screens/plan/moment_flow_screen.dart:227`, `lib/screens/plan/moment_flow_screen.dart:234`).
- [FAIL] Playbook as sanctuary (no metrics framing around it): app still surfaces confidence/event metrics in adjacent library surfaces (`lib/screens/library/patterns_screen.dart:72`, `lib/screens/today.dart:406`).
- [FAIL] Sharing/notification boundaries fully aligned: native text-only share is present (`lib/screens/plan/reset_flow_screen.dart:272`, `lib/screens/library/saved_playbook_screen.dart:92`, `lib/screens/sleep_tonight.dart:658`), but plan nudge cap still allows up to 7 in `more` mode (`lib/services/nudge_scheduler.dart:81`).
- [FAIL] Design-system calm baseline fully enforced: long animation durations remain (`lib/screens/plan/moment_flow_screen.dart:304`, `lib/widgets/calm_loading.dart:27`, `lib/theme/settle_tokens.dart:289`), plus CTA hierarchy and form-density violations above.
