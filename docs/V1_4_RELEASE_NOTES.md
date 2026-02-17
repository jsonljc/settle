# Settle v1.4 Release Notes

Date: 2026-02-17

## What's New

- Sending scripts is clearer and faster.
  - Reset, Sleep Tonight, and Playbook now use **Send** language and generate cleaner, text-only share content that reads well on its own.
- Moment scripts are tighter.
  - Both Moment variants are now capped to two short sentences for lower cognitive load in high-stress moments.
- Notification tone is calmer.
  - Drift messaging was softened from alarm framing to a gentler "Rhythm check-in" prompt.
- Nudge frequency wording is clearer in Settings.
  - Frequency labels now better reflect lightweight reminder intent.
- Lint baseline is clean.
  - Repository-wide analyzer issues were resolved (`flutter analyze` reports no issues).

## Known Limitations

- Full test suite is not green yet.
  - Current full-run status reaches 151 passing tests, 17 failing tests, then stalls in full-suite execution at `test/router_v2_onboarding_route_test.dart` (the file passes in isolation).
- Several UX-law gaps remain in active screens.
  - Multiple primary CTA cases still exist (for example Reset and Sleep close states).
  - Keyboard input still appears in non-onboarding flows.
- Dashboard-style surfaces still exist.
  - Logs/Patterns views still show chart/counter style information that conflicts with strict "no dashboard" acceptance criteria.
- Notification cap behavior is partially misaligned.
  - `NudgeFrequency.more` still allows up to 7 scheduled nudges in a week.

## Deferred to v1.5

- Resolve all blocking acceptance checklist failures end-to-end:
  - Single-primary CTA hierarchy across all active screens.
  - Remove non-onboarding text inputs from parent-facing crisis/progress surfaces.
  - Enforce strict no-dashboard presentation in library/log surfaces.
- Stabilize full-suite automation:
  - Eliminate full-run stall condition and return full `flutter test` to deterministic completion.
  - Rebaseline or fix failing golden and outdated-route expectation tests.
- Finalize notification behavior consistency:
  - Align code-level nudge caps and quiet-hour enforcement with product policy.
