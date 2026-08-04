<!-- PLAN-REVIEW-REPORT -->
# Plan Review: Location-Based Travel Time (S-06)

- **Plan**: context/changes/location-based-travel/plan.md
- **Mode**: Deep
- **Date**: 2026-08-04
- **Verdict**: SOUND
- **Findings**: 0 critical, 2 warnings, 1 observation

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS |
| Lean Execution | PASS |
| Architectural Fitness | PASS |
| Blind Spots | PASS |
| Plan Completeness | WARNING |

## Grounding
9/9 paths ✓, 9/9 symbols ✓, brief↔plan ✓, 48 tests referenced ✓, 18 createAttraction call sites all compatible, 4 reapplyOverrides call sites accounted for, minSdkVersion 24 supports google_maps_flutter (needs ≥20)

## Findings

### F1 — Undefined identifier `flatTravel` + wrong class name in Phase 3 contract

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Phase 3, Change 2 (computeTimeline contract)
- **Detail**: The contract references `fallbackMinutes: flatTravel` but the actual code defines `effectiveTravel` at line 26. As written, the implementer won't find the variable to rename. Also Phase 1 Change 3 says `TripsCompanion.insert()` but the actual code uses `AttractionsCompanion.insert` (attraction_dao.dart:22) — wrong table prefix.
- **Fix**: Rename `flatTravel` → `effectiveTravel` in the contract. Fix `TripsCompanion` → `AttractionsCompanion` in Phase 1.
- **Decision**: FIXED

### F2 — reapplyOverrides line citations wrong

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Phase 3, Change 3 (reapplyOverrides contract)
- **Detail**: Current State Analysis says reapplyOverrides recomputes travel gaps at lines 147-148. The actual recomputation is at lines 153 and 158. Lines 147-148 are the `date` fallback computation — unrelated. Implementer looking at the cited lines will see the wrong code.
- **Fix**: Update line references to 153 (`final travel = ...`) and 158 (`final travelGap = ...`).
- **Decision**: FIXED

### F3 — Key Discovery undercounts effectiveTravel consumption sites

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Plan Completeness
- **Location**: Current State Analysis — Key Discoveries
- **Detail**: Plan says `effectiveTravel` has "the single line" to replace (line 37). Actually there are 3 consumption sites: line 37 (`travelCost`), line 45 (`travelFromPrevMin` in "fits" branch), line 73 (`travelFromPrevMin` in "overstuffed" branch). Phase 3 contract self-corrects by explicitly listing both construction sites for replacement. The discovery statement is misleading but the fix is fully specified.
- **Fix**: Update Key Discovery to say "3 consumption sites" or trust the Phase 3 contract (which is correct). No implementer impact — the contract covers all sites.
- **Decision**: FIXED
