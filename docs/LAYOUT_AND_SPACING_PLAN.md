# Layout and Spacing Plan — Settle

**Status:** Plan only. No implementation yet.

**Goal:** Structure layout and spacing consistently across all screens so the app feels coherent, calm, and predictable. Use design tokens everywhere; remove ad‑hoc magic numbers.

---

## 1. Current state summary

### 1.1 Design system (existing)

- **SettleSpacing:** `xs=4`, `sm=8`, `md=16`, `lg=20`, `xl=24`, `xxl=32`, `cardPadding=20`, `screenPadding=20`, `cardGap=10`, `sectionGap=24`.
- **SettleGap:** Widget that maps to the same scale (xs → xxl). Doc comment in `settle_gap.dart` is wrong (says md=12, lg=16, etc.); actual values follow SettleSpacing.
- **ScreenHeader:** Uses `SettleSpacing.md` above title row, `SettleSpacing.sm` below title, optional subtitle. No standard “gap between header and body” defined.
- **SolidCard / GlassCard:** Default padding `SettleSpacing.cardPadding` (20). Cards are the main content blocks.

### 1.2 What’s consistent

- **Horizontal:** Most screens use `SettleSpacing.screenPadding` (20) for left/right. A few use it only on header and again on scroll content (e.g. Settings).
- **Shell:** `SafeArea` + `GradientBackgroundFromRoute` + `Padding(horizontal: screenPadding)` + `Column` with header then `Expanded(SingleChildScrollView|ListView)` is the common pattern.
- **Sleep Tonight / Today / Settings:** Use `SettleSpacing.cardGap` (10) between cards in places.

### 1.3 Inconsistencies (to fix)

| Issue | Where | Current | Desired |
|-------|--------|--------|--------|
| **Header → body gap** | Many screens | Mixed: `SettleGap.xs()`, `SettleGap.lg()`, `SettleGap.md()`, `SizedBox(height: 12)`, `SizedBox(height: 14)` | One standard (e.g. `sectionGap` or `lg`) |
| **Raw SizedBox heights** | 50+ files | 8, 10, 12, 14, 16, 18, 20, 24, 28, 32 used literally | Replace with SettleGap / SettleSpacing tokens |
| **Section header → content** | Library, Settings, Current Rhythm, Tantrum | Mix of `SettleGap.sm()`, `SettleGap.md()`, `SizedBox(12)` | One token (e.g. `sm` after section label) |
| **Between cards / sections** | App-wide | `cardGap` (10), `SettleGap.md()`, `SettleGap.xxl()`, `SizedBox(24)` | Define: card-to-card vs section-to-section |
| **Scroll bottom padding** | ListView / SingleChildScrollView | Mixed: 32, 24, 12, 8, none | Single token (e.g. `scrollBottomPadding`) |
| **Section headers** | Library, Settings, Current Rhythm, Tantrum | Multiple private `_SectionHeader` / `_RhythmSectionHeader` implementations (different typography/padding) | One shared component + token for “below section label” |
| **Onboarding steps** | All step_*.dart | Heavy use of raw 8, 10, 12, 18, 20, 24, 28, 32 | Map to scale: xs/sm/md/lg/xl/xxl |

---

## 2. Principles (to align with AGENTS.md)

- **Calm by design:** Predictable rhythm; same “breathing room” in similar contexts.
- **Tokens only:** No raw `SizedBox(height: 12)` (or similar) in screen layout; use `SettleGap` or named constants from `SettleSpacing`.
- **One screen shell:** All “standard” screens share the same outer structure (SafeArea, horizontal padding, header, then body).
- **Sections vs blocks:** “Section” = heading + related content. “Block” = card or compact group. Spacing between blocks ≤ spacing between sections.

---

## 3. Proposed layout and spacing structure

### 3.1 Standard screen shell (template)

Apply to every screen that has a title and scrollable body:

```
Scaffold
  body: GradientBackgroundFromRoute
    child: SafeArea
      child: Padding(horizontal: screenPadding)
        child: Column(crossAxisAlignment: start)
          [ScreenHeader]
          [headerToBodyGap]   ← single token
          Expanded
            SingleChildScrollView / ListView
              padding: EdgeInsets.only(bottom: scrollBottomPadding)  ← single token
              [body]
```

- **headerToBodyGap:** New named constant (e.g. `SettleSpacing.headerToBodyGap = 24` or reuse `sectionGap`).
- **scrollBottomPadding:** New constant (e.g. `SettleSpacing.scrollBottomPadding = 32`) so list content doesn’t sit on the nav bar.

Screens that are full-bleed (e.g. SOS, Moment) or custom (onboarding carousel) can opt out but should still use tokens for internal spacing.

### 3.2 Spacing roles (semantic tokens)

| Role | Token | Value (proposed) | Use |
|------|--------|-------------------|-----|
| Screen horizontal | `screenPadding` | 20 | Left/right of main content |
| Header → body | `headerToBodyGap` or `sectionGap` | 24 | Below ScreenHeader before scroll |
| Section label → content | `sm` | 8 | Below “Section” / “Today” / “Tonight” labels |
| Card to card (same section) | `cardGap` | 10 | Between adjacent cards |
| Section to section | `sectionGap` | 24 | Between major blocks (e.g. “Tonight” block vs “Today” block) |
| In-card vertical | `xs`, `sm`, `md` | 4, 8, 16 | Between lines/blocks inside a card |
| Scroll bottom | `scrollBottomPadding` | 32 | Bottom padding of scroll content |

No new scale values needed if we adopt `sectionGap` for header→body and keep `scrollBottomPadding` as 32 (or lg/xxl).

### 3.3 Section header component (unify)

- **Single shared widget** (e.g. in `theme/` or `widgets/`): e.g. `SettleSectionLabel` or reuse/extend a common “section header”.
- Same typography everywhere: e.g. overline/label style, sentence case, muted color.
- Same padding: e.g. `EdgeInsets.only(left: xs)` and `SettleGap.sm` below before content.
- Screens to migrate: Current Rhythm (`_RhythmSectionHeader`), Library (`_SectionHeader`), Settings (`_SectionHeader`), Tantrum cards library (`_SectionHeader`), and any other local section headers.

### 3.4 Card spacing rules

- **Between two cards in the same section:** `SettleSpacing.cardGap` (10) or `SettleGap.sm` if we want 8.
- **Between two sections (each with optional section label + cards):** `SettleSpacing.sectionGap` (24).
- **Inside a card:** Prefer `SettleGap.xs` / `sm` / `md`; avoid raw numbers.

### 3.5 ListView vs SingleChildScrollView

- **ListView:** Use `padding: EdgeInsets.symmetric(horizontal: screenPadding).copyWith(bottom: scrollBottomPadding)` so one place defines horizontal and bottom.
- **SingleChildScrollView:** Wrap child `Column` in `Padding(padding: EdgeInsets.only(bottom: scrollBottomPadding))` or pass padding into the scroll view where supported.
- Ensure every scrollable screen has sufficient bottom padding so content isn’t hidden above the nav bar.

---

## 4. Token and constant changes (design system)

- Add **`scrollBottomPadding`** (e.g. 32) to `SettleSpacing`.
- Decide and document **header-to-body**: either add **`headerToBodyGap`** (e.g. 24) or standardize on **`sectionGap`** for that role.
- Fix **SettleGap** doc comment so it matches `SettleSpacing` (md=16, lg=20, xl=24, xxl=32).
- Optionally add **`sectionLabelGap`** (e.g. 8) for “below section label” if we want it named.

No breaking renames; additive constants and replacement of raw numbers with existing tokens.

---

## 5. Screen-by-screen / area plan

### 5.1 Tab roots (Now / Sleep / Library)

| Screen | Focus |
|--------|--------|
| **Help Now** | Header→body: use standard gap. Replace any `SizedBox` with SettleGap. Scroll bottom padding. |
| **Current Rhythm** | Already uses SettleGap in many places; replace remaining raw heights. Use shared section header. Standard scroll bottom. |
| **Sleep Tonight** | Uses cardGap in places; unify all vertical spacing to tokens. Scroll bottom. |
| **Library home** | Section headers → shared component. Section-to-section = sectionGap. Scroll bottom. |

### 5.2 Progress / Plan

| Screen | Focus |
|--------|--------|
| **Plan progress** | Header→body, in-card gaps, scroll bottom. |
| **Today (Logs)** | Same. |
| **Reset / Moment / Regulate flows** | Standard shell where applicable; internal steps use tokens. |

### 5.3 Settings and Family

| Screen | Focus |
|--------|--------|
| **Settings** | Unify section header; list padding (horizontal + bottom). Replace raw 12 heights with sm. |
| **Family home / Activity feed / Invite** | Same pattern: screen padding, header gap, section labels, scroll bottom. |

### 5.4 Library (deeper)

| Screen | Focus |
|--------|--------|
| **Library progress / Learn / Monthly insight / Patterns / Saved playbook / Playbook detail** | Screen shell; section/card spacing; scroll bottom; no raw heights. |
| **Tantrum: hub, cards library, scripts, crisis view, pattern view, insights, etc.** | Same. Unify _SectionHeader variants. |

### 5.5 Onboarding

| Screen | Focus |
|--------|--------|
| **Onboarding v1/v2 and all steps** | Map current 8/10/12/18/20/24/28/32 to xs/sm/md/lg/xl/xxl (and sectionGap where appropriate). Keep step layout intact but token-based. |

### 5.6 Other

| Screen | Focus |
|--------|--------|
| **Update Rhythm** | Shell + tokens for step spacing and in-card spacing. |
| **Sleep mini onboarding** | Same. |
| **SOS / Splash** | Keep custom layout; internal spacing via tokens. |
| **Release/internal (metrics, compliance, ops)** | Lower priority; same rules when touched. |

---

## 6. Implementation order (phases)

**Phase 1 — Design system and shared UI**  
1. Add `scrollBottomPadding` (and if desired `headerToBodyGap`) to `SettleSpacing`.  
2. Fix `SettleGap` doc comment.  
3. Introduce shared **section label** widget and document “section label gap” (sm).  
4. (Optional) Add a small **ScreenShell** or **ScreenLayout** widget that takes header + body and applies SafeArea, screenPadding, headerToBodyGap, and scroll bottom for new/refactored screens.

**Phase 2 — High-traffic screens**  
5. Help Now, Current Rhythm, Sleep Tonight, Library home: apply standard shell, standard header gap, section labels where applicable, card/section spacing, scroll bottom.  
6. Settings, Plan progress, Today: same.

**Phase 3 — Rest of app**  
7. All other screens under `screens/` and `widgets/`: replace raw `SizedBox(height: n)` with SettleGap/SettleSpacing; apply scroll bottom; use shared section header where there is a section label.  
8. Onboarding: map spacing to tokens phase by phase (or in one pass if small).

**Phase 4 — Verification**  
9. Grep for `SizedBox(height:` and `SizedBox(width:` in `lib/` and eliminate or justify any remaining magic numbers.  
10. Quick visual pass: tab roots, Settings, one onboarding path, one tantrum path.

---

## 7. Verification checklist (post-implementation)

- [ ] No raw `SizedBox(height: 8|10|12|14|16|18|20|24|28|32)` in screens (except where explicitly justified, e.g. icon size).
- [ ] Every scrollable screen has bottom padding ≥ `scrollBottomPadding`.
- [ ] All “section” labels use the shared section label component (or one documented pattern).
- [ ] Screen shell (SafeArea, screenPadding, header, headerToBodyGap, Expanded + scroll) is consistent on standard screens.
- [ ] SettleSpacing and SettleGap docs are accurate and sufficient for contributors.

---

## 8. Open decisions (to resolve before or during implementation)

1. **headerToBodyGap:** Use 24 (sectionGap) or a separate constant (e.g. 20)?
2. **Section label:** New widget name and location (`SettleSectionLabel` in `widgets/` vs in design system).
3. **ScreenShell widget:** Worth a thin wrapper for “header + scroll body” or keep copy-paste pattern with clear doc?
4. **Onboarding:** One bulk pass vs. “fix as you touch” (given many steps).

---

*Document created from layout/spacing audit. Update this plan when decisions are made or implementation is completed.*
