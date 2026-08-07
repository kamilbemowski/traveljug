<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Android Auto

- **Plan**: context/changes/android-auto/plan.md
- **Scope**: Phase 1–4 of 4
- **Date**: 2026-08-07
- **Verdict**: APPROVED (all findings fixed 2026-08-07)
- **Findings**: 0 critical, 7 warnings, 4 observations — all FIXED

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | WARNING |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | WARNING |

## Findings

### F1 — showTripList onPress is a TODO stub — third fallback level dead

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Plan Adherence
- **Location**: `lib/services/android_auto_service.dart:94-97`

- **Detail**: Plan's third fallback level (show trip list for manual selection) was implemented
  as `showTripList()` and `listForSelection()`, but:
  (a) `_onAndroidAutoConnected()` in `main.dart` never calls `showTripList()` — dead code.
  (b) Each row's `onPress` in `showTripList` is a `// TODO: When tapped, load that trip's plan.`
  that just calls `complete()`. The user sees a list of trips but tapping does nothing.
  (c) The trip list is only reachable when zero trips exist, which makes it moot — the
  "no trips" message already handles that case (level 2 returns null only when DB is empty).

- **Fix A ⭐ Recommended**: Remove dead code — delete `showTripList()` and `listForSelection()`.
  Add a plan amendment noting the 3-level fallback simplifies to 2 for now.
  - Strength: Reduces code to maintain; no unused code in release.
  - Tradeoff: If we later need manual trip selection from AA, we rebuild it.
  - Confidence: HIGH — dead code can't be tested and has no user-visible effect.
  - Blind spot: None significant.

- **Fix B**: Implement the full flow — wire trip list display when level 2 returns null,
  and make each row load that trip's plan.
  - Strength: Complete implementation matching the plan's three-level design.
  - Tradeoff: More code; the flow is unreachable in practice (level 2 only returns null
    when no trips exist — but then the trip list would be empty too).
  - Confidence: MEDIUM — unclear how to trigger this path in practice.
  - Blind spot: Would need AA connection testing.

### F2 — "Open app" actions on message templates missing

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Adherence
- **Location**: `lib/services/android_auto_service.dart:67-81`

- **Detail**: Plan's Desired End State and Critical Implementation Details both specify
  "Open app" actions on message templates (no-attractions, no-trips, no-dates). The
  implementation renders bare `AAMessageTemplate` with only title+message — no action.
  Root cause: `flutter_carplay` v1.6.4's `AAMessageTemplate` does not support actions
  (constructor only takes `title` + `message`). This is a plan/package mismatch — the
  plan asked for something the package can't deliver.

- **Fix**: Accept package limitation and remove "Open app" action references from the plan.
  The message itself tells the user what to do; the AA host provides a back button.

### F3 — Phase 4 widget test marked done in Progress but doesn't exist

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: `context/changes/android-auto/plan.md` Progress 4.2

- **Detail**: Plan Progress marks "4.2 Widget test: toggle calls updateTrip" as `[x]` with
  commit `efbc5c3`. No such test exists anywhere in `test/`. The two existing screen test
  files (`trip_list_screen_test.dart`, `trip_detail_screen_test.dart`) have zero S-07/S-09
  edit/delete/toggle coverage.

- **Fix**: Write the widget test: pump trip detail screen with a trip that has dates →
  tap the Active trip switch → verify `TripDao.updateTrip` was called with `isActive: true`.
  Pattern: same in-memory DB setup as existing S-05 tests in `trip_detail_screen_test.dart`.

### F4 — Phase 3 template-building tests never written

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Success Criteria
- **Location**: Plan Progress 3.3, 3.4 (still `[ ]`)

- **Detail**: Plan calls for "Unit tests for showTodayPlan template building" and "Unit tests
  for showTripList template building". Neither exists. The `AndroidAutoService` methods
  create AA template objects that can be verified structurally (row count, titles, onPress
  presence/absence) without needing an actual AA connection.

- **Fix**: Add two unit tests: (1) `showTodayPlan` with mock TimelineDay → verify list items,
  ★ prefix for must-have, no onPress when coordinates absent; (2) `showTripList` with
  mock Trip list → verify row count, subtitle formatting.

### F5 — isActive comment claims "Only one trip should be active" — not enforced

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Safety & Quality
- **Location**: `lib/database/tables.dart:52`

- **Detail**: `isActive` column doc comment says "Only one trip should be active at a time
  (enforced by UI)". The UI does NOT enforce this — toggling isActive on trip A does not
  unset it on trip B. The unit tests explicitly test multiple-active scenarios. The comment
  is misleading and could cause confusion during maintenance.

- **Fix**: Change comment to match implementation: "Whether this trip is marked as active.
  Multiple trips can be active — TripSelectionService picks the most recently updated."

### F6 — Plan's isActive column spec says version 5→6; migration cast workaround

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Pattern Consistency
- **Location**: `lib/database/app_database.dart:35`

- **Detail**: The migration uses `m.addColumn(trips, trips.isActive as dynamic)` — the
  `as dynamic` cast is a Drift 2.34 API workaround for `BoolColumn` not matching
  `GeneratedColumn<Object>`. The plan assumed clean `addColumn` call. This is a known
  Drift limitation, not wrong — but worth documenting for future migrations.

- **Fix**: Add a comment above the migration: "`as dynamic` — Drift 2.34 addColumn rejects
  BoolColumn's type; cast necessary."

### F7 — TravelContext silently defaults to "city" when editing trips with null context

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: `lib/widgets/edit_trip_dialog.dart:63`

- **Detail**: `_travelContext = parseTravelContext(widget.trip.travelContext) ?? TravelContext.city` —
  a trip with null context ("default", 30 min base travel) opens the dialog pre-selected
  as "City tour" (20 min). Any save — even without touching the dropdown — silently writes
  `'city'` to DB, changing timeline travel estimates. This is pre-existing from S-07 but
  surfaced because the isActive toggle was added next to it.

- **Fix**: Add a "Default (30 min)" option to the dropdown or skip the `??` fallback.

### F8 — Test dates hardcoded to 2026-08-06

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Safety & Quality
- **Location**: `test/services/trip_selection_service_test.dart:26,51,84,111,142`

- **Detail**: Trip selection tests use `DateTime(2026, 8, 6)` (yesterday as of this review).
  These tests will silently pass today because the dates still match. But they will rot
  over time — a year from now, date-based assertions will need updating.

- **Fix**: Use `DateTime.now()` with `.subtract(Duration(days: 1))` for relative dates.

### F9 — Unused import in MainActivity.kt

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Pattern Consistency
- **Location**: `android/app/src/main/kotlin/.../MainActivity.kt:6`

- **Detail**: `import io.flutter.embedding.engine.dart.DartExecutor` is unused — the class
  only references `FAAConstants.flutterEngineId` and doesn't use `DartExecutor` directly.

- **Fix**: Remove the unused import.

### F10 — gradle.properties build optimization unrelated to plan scope

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Scope Discipline
- **Location**: `android/gradle.properties`

- **Detail**: Phase 3 implementation added `org.gradle.parallel=true` and
  `org.gradle.caching=true` to `gradle.properties`. These are build optimizations,
  unrelated to Android Auto. Harmless but out of scope — should have been a separate
  chore commit.

- **Fix**: Either move to a separate commit or keep as-is (benign scope creep).
