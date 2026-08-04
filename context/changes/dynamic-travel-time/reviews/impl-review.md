<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Dynamic Travel Time (S-04)

- **Plan**: context/changes/dynamic-travel-time/plan.md
- **Scope**: Phase 1-3 (all phases)
- **Date**: 2026-08-04
- **Verdict**: NEEDS ATTENTION
- **Findings**: 0 critical, 2 warnings, 3 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | WARNING |
| Architecture | PASS |
| Pattern Consistency | WARNING |
| Success Criteria | PASS |

## Findings

### F1 — reapplyOverrides ignores travel context

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: lib/services/timeline_service.dart:147-148
- **Detail**: `computeTimeline()` correctly uses `travelMinutesForContext()`, but `reapplyOverrides()` at line 148 still uses `kDefaultTravelMinutes` directly. Additionally, line 147 calls `parsePace('intensive')` — hardcoding the pace instead of using the trip's actual pace. After any user override (reorder, move-day), travel gaps snap back to the 30-min default. A road trip shows 21 min gaps instead of 63 min.
- **Fix A ⭐ Recommended**: Thread `travelMinutesForContext(trip)` + trip's actual pace into `reapplyOverrides`. Same pattern already applied to `computeTimeline`.
  - Strength: Closes the gap completely. Confidence: HIGH — mirrors the exact change in line 25-26.
  - Tradeoff: Signature change — 3 call sites to update (trip_detail_screen + 2 tests).
  - Blind spot: None.
- **Fix B**: Document as known limitation, defer to S-06.
  - Strength: No code now. Tradeoff: User-visible bug until S-06; S-06 may not touch this code.
  - Confidence: LOW — S-06 scope uncertain.
- **Decision**: FIXED via Fix A

### F2 — parseTravelContext silently swallows unknown values

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: lib/services/pace_config.dart:10-17
- **Detail**: `parseTravelContext` returns null silently on unknown values. `parsePace` in the same file (from M3L5 fix) logs `debugPrint('WARNING: ...')` for the exact same failure mode. The new function violates the error-propagation pattern established one commit before it.
- **Fix**: Mirror `parsePace` — add `debugPrint` warning before returning null.
- **Decision**: FIXED via Fix A

### F3 — CreateTripScreen._save() has no error handling

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: lib/screens/create_trip_screen.dart:54-68
- **Detail**: `_save()` calls `tripDao.createTrip(...)` with no try/catch. M3L5's Fix B wrapped every other DB write in the app (trip_detail_screen reorder/move/delete, add-attraction dialog) in try/catch + SnackBar. This screen — which S-04 extended — is the one DB write still unwrapped. On failure: crash to Crashlytics instead of user feedback.
- **Fix**: Wrap `createTrip` in try/catch, show SnackBar on failure, keep form open. Match the `_AddAttractionDialog` m3l5 pattern.
- **Decision**: FIXED via Fix A

### F4 — Travel-minute values duplicated as UI strings

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Pattern Consistency
- **Location**: lib/screens/create_trip_screen.dart:138-151
- **Detail**: Dropdown labels hardcode "Default (30 min)", "City tour (20 min)", "Road trip (90 min)" — duplicating values from `travelMinutesForContext`. If constants change in S-06, labels drift.
- **Fix**: Derive labels from a helper or extension on TravelContext.
- **Decision**: FIXED via Fix A

### F5 — New DAO travelContext parameter untested

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Success Criteria
- **Location**: test/database/trip_dao_test.dart (unchanged)
- **Detail**: S-04 added `travelContext` to `createTrip`/`updateTrip`, but DAO roundtrip tests don't assert the value roundtrips to/from DB. `computeTimeline` tests cover the service layer, but persistence is unverified.
- **Fix**: Add a roundtrip assertion: create with city context, read back, verify travelContext == 'city'.
- **Decision**: FIXED via Fix A

### F6 — No migration upgrade-path test

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Success Criteria
- **Location**: test/integration/seed_integration_test.dart:110-164
- **Detail**: Integration test verifies `schemaVersion == 3` on fresh DB, but nothing exercises the actual v2→v3 upgrade path (open v2 DB with data, run migration, verify rows survive + travelContext is NULL). Migration itself is correct — this is coverage, not a defect. Follows existing pattern (no v1→v2 migration test either).
- **Fix**: (Optional) Add a migration-specific test; low priority for MVP.
- **Decision**: FIXED via Fix A
