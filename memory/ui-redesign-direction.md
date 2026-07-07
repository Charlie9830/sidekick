---
name: ui-redesign-direction
description: Agreed direction and phasing for the dark-mode/high-density UI overhaul
metadata:
  type: project
---

UI overhaul of Sidekick (Windows desktop, shadcn_flutter). Goal: keep primary dark mode + high data density, improve usability/readability.

Agreed decisions (2026-07-05):
- **Palette:** re-seed neutrals off `LegacyColorSchemes.darkStone()` to a cool near-black "instrument panel" base with a 4-step surface ramp (background → card → elevated → border/gridLine). Domain accents (power-red, data-blue/teal) must be re-tuned for the cooler ground; hold one separate accent purely for selection/active. Target WCAG ≥4.5:1 for text labels, ≥3:1 for graph/line marks.
- **First target:** `lib/screens/looms/cable_row_item.dart` (densest daily-use table) as the reference implementation before rolling tokens out.

Status: Phase 0 + Phase 1 prototype DONE (analyzer-clean). New files: `lib/theme/sidekick_color_scheme.dart` (re-seeded cool near-black ColorScheme, wired into `home_scaffold.dart` replacing `LegacyColorSchemes.darkStone()`) and `lib/theme/sidekick_colors.dart` (`SidekickColors` domain/state/line/selection tokens + `SidekickDensity`). `cable_row_item.dart` fully migrated: stateful hover, tokenized selection/gridLine/flags/icons, contrast raised (foreground/mutedForeground off light+gray shades). shadcn `ThemeData` has NO `extensions` field, so tokens are a static const library, not a Material ThemeExtension.

Phase 2 DONE: `cable_flag.dart` reworked into a semantic status chip (medium-weight white text, tokenized default); tokenized flags/status in `loom_header.dart`, `composition_item.dart`, `outlet_list_item.dart`, `add_spare_cables.dart`. Added tokens: success, motor, hoist, neutralFlag, infoFlag. Looms screen has NO range-selection (SurfaceCard); `rowRangeSelected` belongs to the Material home fixture table (`table_row.dart`).

Phase 3 DONE: `cable_view.dart` node + edge colors tokenized. Converted `CableView` to StatefulWidget with a `TransformationController`; fixture labels now fade via semantic zoom (`_kLabelFadeStart` 1.6 → `_kLabelFadeEnd` 3.2, quantized setState at >0.02 delta to throttle rebuilds; `_FixtureNode` takes `labelOpacity`, renders empty card box when ≤0). Added a `_Legend` (bottom-left, `_LegendSwatch`/`_LegendLine`): colour = cable type (power/data/data-multi/location), line weight = run type (link/fixture/home).

VERIFIED IN-APP (Windows desktop run): builds/launches with no runtime errors; cool near-black surface ramp renders correctly (elevated toolbar → card → near-black bg); Looms screen confirmed — compact 26px cable rows, subtle grid lines, strong foreground contrast, tokenized pink SP spare chips, red-bolt power / teal data outlet icons. NOT yet eyeballed: hover/selection row states (interactive) and the Breakout Cabling graph fade+legend (needs a generated graph on screen).

Phase 4 DONE (2026-07-07): `home.dart` nav shell — the 13 flat tabs are regrouped into 5 logical sections (Project: File/Export/Diff · Fixtures: Fixtures/Fixture Types/Locations · Distribution: Patch/Racks · Rigging: Hoists/Looms/Breakout Cabling · Dev: Lab/Diagnostics) separated by a `_NavGroupDivider` (inset VerticalDivider off `colorScheme.border`). Tab index→container switch mapping kept stable (keys still carry original indices), so only the visual order changed. Selected style bumped from `ButtonStyle.fixed` to `ButtonStyle.primary`.

`table_row.dart` DONE: fully migrated off Material — now a shadcn StatefulWidget with `MouseRegion` hover + `GestureDetector` tap, tokenized bg (`rowRangeSelected`/`rowSelected`/`rowHover`), no more `Colors.green[900]`/`focusColor`.

Screen sweep DONE (racks, power_patch, locations, hoists, import, export, diffing): domain/semantic `Colors.*` routed to tokens — power icons→`powerRun`, data icons→`dataRun`, hoist icon→`hoist`, overflow/warn→`warning`, error→`error`, valid/confirm→`success`. New tokens added: electrical `phase1/phase2/phase3` (used by `phase_icon.dart` + `balance_gauge.dart`) and `diffAdded/diffChanged/diffDeleted` (alias success/warning/error; used by `cable_qty_diffing.dart` + `diff_state_overlay.dart`). Small Material-leak tag widgets `rigging_only_tag.dart`/`hybrid_tag.dart` migrated to shadcn + `neutralFlag`.

Intentionally LEFT as structural (not domain colours): neutral `Colors.gray/grey/neutral/slate` text & icons, `Colors.transparent`, blue drag-over states in `merge_data_step.dart`, and `color_chit.dart` (heavy Material: InkWell/Brightness/highlightColor — out of a colour-only sweep). Location label palette (`NamedColors`, `location_model.dart`) is a genuine user palette, left alone.

VERIFIED: `flutter analyze lib` clean (only 7 pre-existing unrelated issues) + `flutter build windows --debug` succeeds. NOT yet interactively eyeballed: nav regrouping visuals, fixture-table hover/range-select, phase/diff colour changes on screen.

Phasing: 0) token foundation — `SidekickColors extends ThemeExtension` (domain + state + selection tokens) registered in `lib/home_scaffold.dart`, density/gridLine tokens, kill Material leakage. 1) looms cable rows readability. 2) unify flag/status vocabulary (CableFlag). 3) breakout-cabling graph canvas (`lib/screens/breakout_cabling/cable_view.dart`) — token colors, min readable label size, legend. 4) nav shell (13 flat tabs in `lib/screens/home/home.dart`) grouping + active state.

Key problems found: two design systems fighting (Material leaks in `table_row.dart` via `Colors.green[900]`, `focusColor`); ~151 hardcoded `Colors.*` domain-color usages across 53 files (violates CLAUDE.md semantic-token rule); low contrast from `light`/`extraLight` weights on `gray.shade300/400`; graph uses raw colors + 4–6px illegible fonts.
