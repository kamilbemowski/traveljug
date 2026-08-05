<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: S-07 Edit & Delete Everything

- **Plan**: context/changes/edit-delete-everything/plan.md
- **Scope**: Phase 1–3 of 3 (full plan)
- **Date**: 2026-08-05
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical, 4 warnings, 4 observations

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

### F1 — Nulled values in edit dialog silently revert (clear-date / Default context)

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: trip_list_screen.dart:68-119, trip_detail_screen.dart:140-180
- **Detail**: Both trip edit dialogs offer a clear-date affordance and a "Default" (null) travel-context option. But `TripDao.updateTrip` writes `Value.absentIfNull(...)` for every field — null means "no change", not "write null". The user clears a date or picks Default context, the dialog and reloaded UI look correct, but the old value stays in the DB; the cleared value reappears on next load. The UI promises a capability the DAO can't deliver silently.
- **Fix A ⭐ Recommended**: Remove the clear-date and "Default" affordances from the edit dialogs (they don't work with the current DAO semantics). Simple, no DAO changes.
  - Strength: One-line deletions; zero risk.
  - Tradeoff: Lose the ability to clear dates/context from edit dialogs (users must live with whatever they set on create).
  - Confidence: HIGH — DAO semantics are explicit and well-tested.
  - Blind spot: Whether users actually need to clear a previously-set date.
- **Fix B**: Add explicit null-write support to the DAO (stop using `absentIfNull` for these fields, accept full-row write semantics).
  - Strength: Preserves the UI affordance; user can clear dates and context.
  - Tradeoff: Touches the DAO layer, needs migration or careful null handling, wider test surface.
  - Confidence: MEDIUM — need to verify other callers of updateTrip won't regress.
  - Blind spot: Haven't checked whether any other code relies on the current absentIfNull null-skip.
- **Decision**: FIXED via Fix A — removed clear-date buttons and Default travel-context option from both edit dialogs

### F2 — Trip list goes stale after delete-from-detail (ghost trip entry)

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: trip_list_screen.dart:194-201, trip_detail_screen.dart:216
- **Detail**: `_deleteTripFromDetail` pops with `Navigator.pop(context, true)`, but the list's `onTap` pushes `TripDetailScreen` with no `.then(...)` reload on pop. The pop result is dropped. After deleting a trip from its detail screen, the list still shows the deleted trip (ghost entry); tapping it navigates to detail which shows "Trip not found". Same stale state applies to trip edits made from detail (rename never reflects in list). Note the create-trip FAB path *does* reload via `.then` — the detail path just wasn't given the same treatment.
- **Fix**: Change `onTap` to `Navigator.push(...).then((_) => _loadTrips())`, matching the FAB pattern at line 213.
  - Strength: One-line fix, proven pattern already used in the same file.
  - Tradeoff: Minor — adds one reload per detail-screen return (even non-mutating visits).
  - Confidence: HIGH — identical pattern used successfully at line 213.
  - Blind spot: None significant.
- **Decision**: FIXED — added `.then((_) => _loadTrips())` to detail-screen Navigator.push onTap, matching the FAB reload pattern

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: trip_detail_screen.dart:321-322, trip_list_screen.dart:38-128, trip_detail_screen.dart:117-189
- **Detail**: The reference dialog `_AddAttractionDialog` validates with `Form` + validators — name required, duration positive. `CreateTripScreen` validates too. The new dialogs use raw `TextField`s with zero validation: (a) trip name/destination saved empty (blank entries), (b) invalid attraction duration → `if (dur == null || dur <= 0) return;` closes the dialog silently with no feedback. Also: no end-date-before-start cleanup that CreateTripScreen does — edit dialogs allow end < start. Additionally, attraction edit dialog omits location fields (lat/lng) present in the add-attraction form, so location is preserved on update but not editable.
- **Fix**: Wrap edit dialogs in `Form` with `TextFormField` validators (copying the `_AddAttractionDialog` pattern). On invalid duration, show inline error instead of silent return. Clamp end date when start is moved past it.
- **Decision**: FIXED — added Form + validators to all 3 edit dialogs; end-date clamping on start-date change; TravelContext defaults to city for null values

### F4 — Trip edit dialog duplicated across two files with diverging implementations

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: trip_list_screen.dart:38-128 vs trip_detail_screen.dart:117-189
- **Detail**: The ~80-line "Edit Trip" dialog is implemented twice — list screen uses a `_DateField` widget, detail screen uses a `_buildDateField` helper method. Nearly identical logic, different date-picker plumbing. Any future fix (e.g., F1, F3) must be applied in two places or they diverge further. Plan itself called this acceptable for MVP ("2 call sites"), but with three copies of `_DateField` across the codebase (create_trip_screen has a third), extraction is warranted.
- **Fix**: Extract one shared `EditTripDialog` widget (and one shared date-field widget), used by both screens.
- **Decision**: FIXED — extracted shared `showEditTripDialog` + `EditTripResult` to `lib/widgets/edit_trip_dialog.dart`; removed duplicate `_DateField` and `_buildDateField` from both screens

### F5 — TextEditingControllers in dialogs never disposed

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: trip_list_screen.dart:39-40, trip_detail_screen.dart:118-119, 265-266
- **Detail**: Controllers are created per-dialog-open and never `dispose()`d. The reference `_AddAttractionDialog` disposes its controllers (lines 720-725). Short-lived objects, so GC'd, but it's a leak pattern inconsistent with the reference.
- **Fix**: Dispose controllers after dialog closes, or move to a StatefulWidget dialog that owns and disposes its controllers.
- **Decision**: FIXED — disposed controllers in edit_trip_dialog.dart and _handleEditAttraction after dialog closes

### F6 — `_loadTimeline` has no error handling; DB failure = infinite spinner

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: trip_detail_screen.dart:40-78
- **Detail**: Every new mutation wraps its DAO call in try/catch, but `_loadTimeline` (called from initState and after every successful mutation) has none. A DB throw leaves `_loading = true` forever with an unhandled async exception. There's already an `_error` slot and placeholder UI — just not wired.
- **Fix**: Wrap the body in try/catch; on error, set `_error` state (the error slot and placeholder UI already exist).
- **Decision**: FIXED — wrapped _loadTimeline body in try/catch with error state set on failure

### F7 — `_handleDelete` removes attraction before override; partial failure leaves inconsistent state

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: trip_detail_screen.dart:387-397
- **Detail**: Two sequential deletes (attraction, then its override) outside a transaction. If the second fails, the catch shows "Failed to remove attraction" even though the attraction is gone, and the UI isn't reloaded. The override delete is likely redundant anyway — the schema cascades (TimelineOverrides has FK cascade per CLAUDE.md).
- **Fix**: Rely on the FK cascade; single `deleteAttraction` call. Or wrap both in a Drift transaction.
- **Decision**: FIXED — removed redundant override delete, relying on FK cascade

### F8 — Per-row DB writes in a loop without atomicity

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: trip_detail_screen.dart:89-91 (_handleReorder), 359-361 (_handleResetDay)
- **Detail**: `upsertOverride`/`deleteOverride` called per slot sequentially; a mid-loop failure leaves partially applied overrides with no reload. Fine at app scale (~tens of attractions), but a transaction or `batch()` would make it atomic and faster.
- **Fix**: Use a Drift `batch()` or `transaction()` for the loop.
- **Decision**: FIXED — wrapped both _handleReorder and _handleResetDay loops in db.transaction()
