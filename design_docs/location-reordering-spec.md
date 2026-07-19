# Location Reordering

**Status:** Draft for review
**Date:** 2026-07-19
**Scope:** User-driven reordering of Locations from the Locations screen, plus
the state re-computation required to keep every location-ordered collection
coherent.

## Goal

Allow the user to change the order of Locations in the Locations screen
([locations.dart](lib/screens/locations/locations.dart)). Location order is the
master ordering of the whole project — outlets, patches, hoists, cables, and
exports all present themselves in location order — so a reorder must ripple
through dependent state atomically.

**Guiding principle:** the patch is declarative. State always reflects what a
fresh patch computed from the current inputs would produce. A location reorder
therefore re-runs the power patch immediately — even where that shuffles phase
assignments — rather than deferring the change to some later
`performPowerPatch` call. The diffing screen exists precisely so the user can
make a batch of changes and review the consequences afterwards.

---

## 1. How ordering works today (background)

There is no explicit `sortIndex` anywhere. Ordering is carried entirely by
**map insertion order** (`Map<String, T>` in Dart is a `LinkedHashMap`).
`FixtureState` ([fixture_state.dart](lib/redux/state/fixture_state.dart)) holds
every collection as such a map, and serialization
([serialize_project_file.dart](lib/serialization/serialize_project_file.dart))
writes `map.values.toList()`, so insertion order round-trips through
save/load. Location order is established at fixture import
([read_raw_fixtures.dart](lib/screens/file/import_module/read_raw_fixtures.dart))
and never changes afterwards.

The invariant the codebase silently maintains:

> `fixtures`, `powerMultiOutlets`, `dataMultis`, `dataPatches`, `hoists`,
> `hoistMultis`, and `cables` are each stored **grouped by location, in
> `locations` iteration order** (and sorted by `number` / `sequence` within
> each location).

## 2. Audit: code that assumes iteration order matches location order

The suspicion that outlet/hoist code silently assumes location-aligned
iteration order is correct — the assumption is widespread. Findings, ordered
by severity:

### 2.1 Critical — wrong data if violated

| Site | Assumption |
|---|---|
| [perform_power_patch.dart:121-181](lib/perform_power_patch.dart#L121-L181) `_mapToMultiOutlets` | Re-marries fixtures onto balancer outlets purely by iteration order. The in-code comment calls this out explicitly ("If the Ordering of the outlets has changed... we will end up assigning the wrong fixtures to the wrong outlets, this is a critical error"). It defends itself by re-sorting both sides against `locations` before zipping, so it is safe **as long as fixtures and locations are passed consistently**. |
| [hoist_selectors.dart:149-186](lib/containers/hoist_selectors.dart#L149-L186) `selectSidebarItems` | Computes `globalIndexOffset` by accumulating per-location hoist counts in `locations.values` order, then uses `oldRawIndex + globalIndexOffset` to index into the **raw** `hoists.values.toList()`. This only works if the `hoists` map iteration order equals the location-grouped order. If locations are reordered without re-sorting `hoists`, dragging a hoist in the sidebar would move the *wrong hoist*. |
| [perform_power_patch.dart:225-240](lib/perform_power_patch.dart#L225-L240) `_balanceOutlets` | Carries cumulative `PhaseLoad` across outlets **sequentially**, so location order feeds into which phases fixtures land on. Reordering locations and re-running the patch can shift phase assignments. **This is accepted and desired** — see the guiding principle above; the change lands immediately and is reviewable in the diffing screen. |

### 2.2 Ordering producers — the tools a reorder must invoke

- [perform_power_patch.dart](lib/perform_power_patch.dart)
  `performPowerPatch` — the declarative source of truth for
  `powerMultiOutlets` and fixtures' patch data. Internally sorts fixtures and
  outlets against `locations` and finishes with `_assertPowerMultiState`,
  which emits the outlet map already grouped in location order. Re-running it
  with the reordered locations map produces both correct content *and*
  correct order for power.
- [fixture_model.dart:167-186](lib/redux/models/fixture_model.dart#L167-L186)
  `FixtureModel.sort` — fixtures grouped by location order, by `sequence`
  within. `performPowerPatch` returns fixtures in their *input* order, so the
  reducer must wrap the result, exactly as
  [file_reducer.dart:22](lib/redux/reducers/fixture_state/file_reducer.dart#L22)
  does.
- [multi_outlet_asserts.dart:9-33](lib/multi_outlet_asserts.dart#L9-L33)
  `assertMultiOutletState<T extends MultiOutlet>` — for `dataMultis` and
  `hoistMultis` (the `MultiOutlet` sealed class covers only those two).
  Sorts against `locations.values` and re-asserts per-location names/numbers.
- [multi_outlet_asserts.dart:70-82](lib/multi_outlet_asserts.dart#L70-L82)
  `assertDataPatchState` — same treatment for `dataPatches`.
- [assert_cable_state.dart](lib/redux/reducers/fixture_state/assert_cable_state.dart)
  `assertCableState` — orders cables by walking the outlet maps'
  `groupListsBy(locationId)` group order. Note it does **not** consult
  `locations` directly: cable order is *derived from outlet map order*, so it
  must run **after** the outlet maps have been recomputed.

Note there is no equivalent producer for `hoists` — hoist order within a
location is user-managed via drag (`reorderHoists`,
[hoist_actions.dart:84-102](lib/redux/actions/hoist_actions.dart#L84-L102)),
and hoist names are deliberately never re-asserted (see the comment at
[location_reducer.dart:69-71](lib/redux/reducers/fixture_state/location_reducer.dart#L69-L71)).
A reorder must re-group hoists by the new location order while **preserving
their existing relative order within each location** and touching nothing
else.

### 2.3 Order consumers — self-healing, no changes needed

These iterate `locations.values` and group other collections by `locationId`
at read time, so they automatically reflect whatever order the state holds:

- Locations screen ([locations_container.dart](lib/containers/locations_container.dart))
- Fixtures view models ([select_fixture_view_models.dart](lib/data_selectors/select_fixture_view_models.dart))
- Power patch view models ([select_power_patch_view_models.dart](lib/containers/select_power_patch_view_models.dart))
- Looms outlet sidebar ([looms_container.dart:98-140](lib/containers/looms_container.dart#L98-L140))
- Rack selectors ([rack_selectors.dart:24,48](lib/containers/rack_selectors.dart#L24))
- Breakout cabling ([breakout_cabling_container.dart:220](lib/containers/breakout_cabling_container.dart#L220))
- Excel exports ([create_breakout_cabling_sheet.dart:19](lib/excel/create_breakout_cabling_sheet.dart#L19) and the other sheet builders, which iterate the already-ordered outlet maps)
- Cable graph ([cable_graph.dart:278](lib/cable_graph/cable_graph.dart#L278))
- Diffing screen ([diffing_screen_container.dart:136](lib/containers/diffing_screen_container.dart#L136))

### 2.4 Label stability

Outlet **names and numbers are per-location** (`assertOutletNameAndNumbers`
numbers outlets by their index *within* their location, and names come from
the location's own prefix/delimiter). Data multis, data patches, hoist multis,
and hoists keep their labels across a reorder. Power multi labels are also
per-location, but because the patch re-runs, the balancer may redistribute
fixtures across phases/circuits — those content changes surface in the
diffing screen for review.

---

## 3. Why a dedicated action rather than reusing `SetLocations`

Dispatching the reordered map through the existing `SetLocations` gets the
power side right (it re-runs `performPowerPatch`, which emits power multis in
the new order), but **it does not actually re-sort the other maps**:

- Its `assertOutletNameAndNumbers` calls
  ([location_reducer.dart:42-77](lib/redux/reducers/fixture_state/location_reducer.dart#L42-L77))
  group with `groupListsBy`, which preserves *input* order — `dataMultis`,
  `dataPatches`, and `hoistMultis` come out still grouped in the OLD location
  order, breaking the invariant in §1 (and with it the hoist sidebar index
  math in §2.1).
- It never touches `hoists` or `cables` order at all.

A dedicated `ReorderLocations` action with its own reducer branch closes
those gaps.

---

## 4. Design

### 4.1 Action

Add to [location_sync_actions.dart](lib/redux/actions/location_sync_actions.dart):

```dart
class ReorderLocations {
  /// Every location uid, in the new desired order. Must be a permutation of
  /// the current locations key set.
  final List<String> orderedLocationIds;
  ReorderLocations(this.orderedLocationIds);
}
```

Carrying ids rather than a rebuilt map keeps the action minimal and prevents a
stale UI snapshot of location *content* from overwriting concurrent edits.

### 4.2 Reducer

New branch in
[location_reducer.dart](lib/redux/reducers/fixture_state/location_reducer.dart):

```dart
if (a is ReorderLocations) {
  return _reorderLocations(state, a.orderedLocationIds);
}
```

`_reorderLocations` steps, in order:

1. **Validate.** If `orderedLocationIds.toSet()` is not exactly
   `state.locations.keys.toSet()`, return `state` unchanged (defends against a
   stale UI dispatch racing a location add/remove).
2. **Rebuild `locations`** by mapping the ordered ids through the existing map.
3. **Re-run the power patch** with the new locations map, mirroring the
   `SetLocations` branch: `performPowerPatch(... locations: newLocations ...)`.
   Take `powerMultiOutlets` from the result. Set
   `fixtures: FixtureModel.sort(result.fixtures, newLocations)` (the same
   wrap [file_reducer.dart:22](lib/redux/reducers/fixture_state/file_reducer.dart#L22)
   applies at import). Phase assignments may shift; that is the declarative
   behaviour we want, and it lands immediately.
4. **Recompute `dataMultis` and `hoistMultis`** via
   `assertMultiOutletState<T>(multiOutlets: …, locations: newLocations,
   cables: state.cables)` — unlike the `SetLocations` branch, this re-sorts
   the maps into the new location order, not just the labels.
5. **Recompute `dataPatches`** via `assertDataPatchState`.
6. **Re-sort `hoists`**: group by `locationId`, concatenate groups in new
   location order, preserving existing relative order within each group. No
   renaming/renumbering (hoist names are user-owned, §2.2). A small helper in
   the reducer file is sufficient. Hoists whose `locationId` is not in the
   locations map (defensive) are appended at the end in their existing order
   rather than dropped.
7. **Re-sort `cables`** last, via `assertCableState` fed the *updated* outlet
   maps from steps 3-6 (cable order derives from outlet map order, §2.2).

`looms`, `hoistControllers`, racks, feeds, trusses, and all other collections
are untouched — their ordering is user-managed or location-independent.

Because the reducer returns a new `FixtureState`, the unsaved-changes
middleware ([unsaved_changes_middleware.dart](lib/redux/middleware/unsaved_changes_middleware.dart))
flags the project dirty automatically; no registration needed.

### 4.3 UI — Locations screen

The Locations screen is a `TableView.builder`
(two_dimensional_scrollables), which has no native row drag-reorder. Rather
than fight the table, reuse the pattern already established for hoists
(`ReorderableList` + `ReorderableDragStartListener`,
[hoist_location_item.dart](lib/screens/hoists/hoist_location_item.dart)):

- Add a **"Reorder…" button** to the Locations screen (alongside the screen's
  existing header/toolbar area).
- It opens a sheet via the existing `openShadSheet` helper (same entry style
  as `AddOrEditRiggingLocation`), containing a `ReorderableList` of all
  locations — each row: drag handle, `MultiColorChit`, location name, and the
  rigging-only / hybrid tags where applicable.
- The sheet is **modal** and batches: drags only mutate a local ordered list
  held in the sheet's own state (`onReorder` mirrors `reorderHoists`' index
  arithmetic: `if (oldIndex < newIndex) newIndex -= 1;`). Nothing is
  dispatched while dragging.
- **Apply** dispatches a single `ReorderLocations` with the final ordered id
  list (via a thunk in
  [location_actions.dart](lib/redux/actions/location_actions.dart)), so the
  power patch re-runs exactly once per reorder session. **Cancel** (or
  dismissing the sheet) discards the local order and dispatches nothing.
- If Apply is pressed after the underlying locations changed (add/remove
  raced the sheet), the reducer's permutation validation (§4.2 step 1)
  makes the dispatch a no-op rather than corrupting state.
- Per the project's accessibility rule, the sheet gets an explicit title
  ("Reorder Locations").

Alternative considered: move-up/move-down buttons inline in the table's
Actions column. Rejected as primary UX (tedious for long moves) but cheap to
add later since the action supports any permutation.

### 4.4 Hybrid and rigging-only locations

Hybrid locations are ordinary entries in the `locations` map and reorder
freely; their derived names are unaffected. Rigging-only locations likewise.
No special casing — the reorder is a pure permutation of the map.

---

## 5. Known limitations / accepted behaviour

- **Phase assignments may shuffle immediately.** Accepted and intended: the
  patch is declarative, and the resulting content changes (fixture
  `powerPatch` labels, multi children) are property-level changes the diffing
  screen will surface for review.
- **A *pure* reorder won't appear in the diffing screen.** Order is not a
  diffed property (`LocationModel.getDiffValues` compares per-uid
  properties). If the balancer output happens to be unchanged, the only
  difference is serialization order — the dirty flag and save behave
  correctly, but the diff shows no delta. Accepted for v1.
- **No undo.** The app has no undo system; same as every other mutation.

---

## 6. Testing

Reducer unit tests (new file
`test/redux/reorder_locations_reducer_test.dart`), against a fixture state
with ≥3 locations populated with fixtures, power multis, data multis, data
patches, hoists, hoist multis, and cables:

1. `locations` map keys come out in the requested order.
2. Every dependent map (`fixtures`, `powerMultiOutlets`, `dataMultis`,
   `dataPatches`, `hoists`, `hoistMultis`, `cables`) iterates grouped by the
   new location order.
3. **Declarative equivalence:** `powerMultiOutlets` and fixture patch data
   after the reorder equal a direct `performPowerPatch` run over the
   reordered locations — i.e. the state holds exactly what a fresh patch
   would produce, no more and no less.
4. **Non-power content is untouched:** data multis, data patches, hoist
   multis, and hoists keep identical models (names, numbers, ids) — only map
   order changes.
5. Hoist relative order within each location is preserved, and hoist names
   are untouched.
6. Reordering with a stale/incomplete id list (missing id, extra id) returns
   the identical state instance.
7. Round-trip: serialize → deserialize preserves the new order.
8. Regression guard for §2.1: after a reorder, `selectSidebarItems`' global
   index arithmetic maps a sidebar drag to the correct hoist (can be asserted
   by checking `hoists.values.toList()` matches the location-grouped
   flattening).
