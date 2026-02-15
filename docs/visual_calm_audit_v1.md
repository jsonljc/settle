# Visual Calm Audit v1

Date: 2026-02-14

## Implementation Status

- Applied on `Home`, `Start Relief`, `Help Now`, `Sleep Tonight`, `Plan & Progress`, `Settings`, `Family Rules`, and `Logs`.
- Remaining follow-up is golden image refresh for changed screens when visual baselines are intentionally updated.

## Top 15 Visual Stressors

1. Home had competing top-level actions before primary/secondary split.
   Location: `lib/screens/home.dart`
   Change: Keep one primary card CTA (`Get support now`) and move all secondary actions under `More actions`.

2. Relief decision surface showed too many equally weighted routes.
   Location: `lib/screens/relief_hub.dart`
   Change: Keep top routes visible, collapse less-common paths under `Other situations`.

3. Help Now output state had multiple equal-priority cards.
   Location: `lib/screens/help_now.dart`
   Change: Keep timer as single primary CTA, merge escalation + logging into one optional `More options` section.

4. Help Now “finish” action competed visually with the timer CTA.
   Location: `lib/screens/help_now.dart`
   Change: Downgrade `Finish for now` from pill button to subtle text link.

5. Incident selection cards felt dense due repeated hard card framing.
   Location: `lib/screens/help_now.dart`
   Change: Use `GlassCard(border: false)` for incident tiles to reduce border noise.

6. Plan & Progress had too many stacked cards before the next action.
   Location: `lib/screens/plan_progress.dart`
   Change: Keep `One experiment` as primary card; collapse evidence/rhythm/related links into `More details (optional)`.

7. Plan & Progress secondary links competed with core weekly action.
   Location: `lib/screens/plan_progress.dart`
   Change: Move `Open Learn Q&A` and `Open Logs` into optional details disclosure.

8. Sleep Tonight runner showed extra info card at same priority as actions.
   Location: `lib/screens/sleep_tonight.dart`
   Change: Move escalation guidance into `More actions` disclosure and remove separate escalation card.

9. Sleep red-flag card had a second button competing with the primary runner flow.
   Location: `lib/screens/sleep_tonight.dart`
   Change: Downgrade `Pause active plan` to subtle text action.

10. Global glass borders were slightly high-contrast for calm surfaces.
    Location: `lib/theme/settle_tokens.dart`
    Change: Border token reduced from `0x0DFFFFFF` to `0x0AFFFFFF`.

11. Screen-to-screen spacing rhythm had mixed 10/12/14 values.
    Location: `lib/screens/*`
    Change: Normalize key section spacing around major cards to 12 where practical.

12. Optional content was often always-visible.
    Location: `lib/screens/help_now.dart`, `lib/screens/plan_progress.dart`, `lib/screens/relief_hub.dart`
    Change: Use disclosure-first approach for non-critical content.

13. CTA hierarchy lacked consistent pattern naming.
    Location: `lib/theme/glass_components.dart`, `lib/screens/*`
    Change: Primary uses `GlassCta`; secondary actions use chips or subtle underlined text links.

14. Dense utility actions in Sleep Tonight runner increased cognitive load.
    Location: `lib/screens/sleep_tonight.dart`
    Change: Keep utility actions behind `More actions`.

15. Visual language drift risk across screens.
    Location: `lib/theme/settle_tokens.dart`, `lib/theme/settle_theme.dart`
    Change: Keep tokenized type/spacing/color usage as default implementation path.
