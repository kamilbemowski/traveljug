<!-- IMPL-REVIEW-REPORT -->
# Implementation Review v2: S-07 Edit & Delete Everything

- **Plan**: context/changes/edit-delete-everything/plan.md
- **Prior review**: context/changes/edit-delete-everything/reviews/impl-review.md (8 findings, all marked FIXED)
- **Date**: 2026-08-06
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical, 3 warnings, 3 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | WARNING |
| Success Criteria | WARNING |

## Findings

### R1 — F1 fix regression: clear-date buttons still present, silently revert

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM
- **Dimension**: Safety & Quality
- **Location**: `lib/widgets/edit_trip_dialog.dart:137-139, 148-150, 235-239`
- **Detail**: Impl-review v1 F1 decided "removed clear-date buttons" (Fix A). The fix hasn't held — the current `_DateField` still renders a clear (X) icon when `value != null && onClear != null`, and both date fields pass `onClear` callbacks that set local state to null. Since `TripDao.updateTrip()` uses `Value.absentIfNull` for all fields, null means "no change" — clearing a date in the dialog looks correct in the UI, but the old date silently persists in the DB and reappears on next load. The TravelContext "Default" option WAS removed correctly (dropdown only has city/roadTrip), so the fix was partially applied — dates were missed or regressed.
- **Fix A ⭐ Recommended**: Actually remove the clear-date affordances — delete the `onClear` callback from both `_DateField` usages and remove the clear icon rendering from `_DateField.build`. 3-line change.
- **Fix B**: Add explicit null-write support to the DAO (stop using `absentIfNull` for date fields). More invasive, needs testing of all callers.

### R2 — TravelContext silently defaults to "city" for null trips

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW
- **Dimension**: Safety & Quality
- **Location**: `lib/widgets/edit_trip_dialog.dart:60`
- **Detail**: `_travelContext = parseTravelContext(widget.trip.travelContext) ?? TravelContext.city;` — when a trip has null travelContext, the dialog shows "city". The dropdown has no null option. Saving the dialog writes "city" to the DB even if the user made no changes — merely opening and saving silently mutates a null context into "city". This is semantic drift: the user didn't set this value, it was chosen for them.
- **Fix**: Add a null/"Not set" option to the TravelContext dropdown, or skip the `?? TravelContext.city` fallback and let null pass through. The DAO already handles null travelContext correctly (it's just a display label mapping).

### R3 — Attraction location clear button silently no-ops

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW
- **Dimension**: Safety & Quality
- **Location**: `lib/screens/trip_detail_screen.dart:832-838`
- **Detail**: The `_EditAttractionDialog` has a clear button on the location tile that sets `_lat = null; _lng = null; _placeName = null;`. But `AttractionDao.updateAttraction()` uses `Value.absentIfNull` for latitude/longitude/placeName — same pattern as R1. The user clears a location, saves, the UI shows no location, but the old coordinates persist in the DB. On next edit, the old location reappears.
- **Fix**: Remove the location clear button from the edit dialog, OR add explicit null-write support to the DAO for coordinate fields. The add-attraction dialog has the same clear button (line 647-649) but it works there because it clears local state before create — on edit it's the DAO's absentIfNull that blocks the write.

### R4 — No S-07 widget tests despite plan claims

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Success Criteria
- **Location**: `test/screens/trip_list_screen_test.dart`, `test/screens/trip_detail_screen_test.dart`
- **Detail**: Plan items 1.3 ("Widget test: delete from list triggers confirmation dialog") and 2.3 ("Widget test: edit dialog opens with pre-filled values") are checked off with commit SHAs. But no S-07 commit (`35402e4`, `df9ef02`, `9ed9be1`, `2445f1a`, `3a39039`) touched any test file. Current test files: `trip_list_screen_test.dart` (65 lines, 3 tests — empty state, FAB, list display) and `trip_detail_screen_test.dart` (93 lines, 2 tests — S-05 intensity bar, overstuffing). Zero edit/delete widget coverage. All 77 tests pass because the DAO integration tests cover the data layer, but the UI layer (FR-001 through FR-005) has no widget-level coverage.
- **Fix**: Add widget tests for: edit dialog opens with pre-filled values, delete confirmation dialog appears, save updates entity, cancel leaves entity unchanged. The pattern already exists in the S-05 tests — same in-memory DB setup.

### R5 — Roadmap status stale for S-07

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Pattern Consistency
- **Location**: `context/foundation/roadmap.md:32, 82`
- **Detail**: Roadmap lists S-07 as "ready" in both the At a glance table and the slice section. But S-07 is fully implemented, impl-reviewed, and merged to develop — it should be at least "implementing" or match S-08's prior state. Also the Backlog Handoff still says "Run `/10x-plan edit-delete-everything`" — this was already done and executed.
- **Fix**: Update roadmap to reflect actual status (e.g., "implementing" or "impl_reviewed"). Remove from Backlog Handoff.

### R6 — Delete from trip list is long-press only — no visual affordance

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Pattern Consistency
- **Location**: `lib/screens/trip_list_screen.dart:133`
- **Detail**: The only way to delete a trip from the list is long-press (`onLongPress: () => _deleteTrip(trip)`). There's no visible delete icon, no swipe-to-delete, no hint text. The trip detail screen has a visible red delete icon in the AppBar. Users must discover the long-press gesture. The plan explicitly scoped this, so it's not a scope violation — but it's an inconsistent UX between the two screens.
- **Fix**: Add a trailing delete icon to the trip tile (matching the detail screen pattern), or accept the long-press-only approach and note it in the plan. Low priority — discoverability is the only concern.

---

## Comparison with prior review (v1, 2026-08-05)

| Prior finding | Claimed fix | Actually fixed? |
|---|---|---|
| F1 — clear-date/Default silently revert | Remove clear buttons + Default option | **Partial** — Default option removed ✅, clear-date buttons still present ❌ |
| F2 — ghost trip after delete-from-detail | `.then((_) => _loadTrips())` on detail push | ✅ Confirmed — present at line 131 |
| F3 — missing Form validators | Form + validators added | ✅ Confirmed — all dialogs have validators |
| F4 — duplicated edit dialog | Extracted to `edit_trip_dialog.dart` | ✅ Confirmed — single shared widget |
| F5 — controllers not disposed | Disposed after dialog close | ✅ Confirmed — `_EditTripDialogState` disposes controllers |
| F6 — _loadTimeline no error handling | try/catch added | ✅ Confirmed — line 80-83 |
| F7 — two-step delete without transaction | Single delete, FK cascade | ✅ Confirmed — line 255 |
| F8 — per-row writes without atomicity | `db.transaction()` wrapper | ✅ Confirmed — lines 94, 222 |

**Of 8 prior fixes**: 7 confirmed still in place ✅, 1 regressed/partial (F1 — clear-date buttons) ❌.

## Summary

S-07 is functionally complete and all 5 FRs are satisfied. The 3 warnings (R1, R2, R3) share the same root cause: the dialog UI allows clearing nullable fields (dates, location, context) but the DAO's `Value.absentIfNull` semantics silently block null writes. The prior review identified this for trip dates (F1) but the fix didn't fully land. R2 and R3 are the same pattern in different fields. All fixes are low-risk, narrowly scoped, and don't touch the database layer.

**Recommendation**: Apply the 3 warning fixes (estimated 20 lines), add 2-3 widget tests for the edit/delete paths, then re-verify. No DAO or schema changes required.
