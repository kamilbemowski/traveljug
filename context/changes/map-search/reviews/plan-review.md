<!-- PLAN-REVIEW-REPORT -->
# Plan Review: S-08 Map Search (Geocoding)

- **Plan**: context/changes/map-search/plan.md
- **Mode**: Deep
- **Date**: 2026-08-05
- **Verdict**: SOUND
- **Findings**: 0 critical, 2 warnings, 2 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS |
| Lean Execution | PASS |
| Architectural Fitness | PASS |
| Blind Spots | WARNING |
| Plan Completeness | WARNING |

## Grounding

4/4 paths present (test file correctly absent — planned creation), 8/8 symbols verified, brief↔plan consistent (5 changes, 1 phase, 6 automated + 5 manual checks match). Progress section format valid — exactly one `## Progress` block, phase name matches, all checkboxes enumerated.

## Findings

### F1 — Test file creation not listed in Changes Required

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Testing Strategy section; Changes Required section (missing entry)

- **Detail**: The plan lists 4 widget tests in Success Criteria, Testing Strategy, and Progress but has no `#### 6. Create test file` entry under Changes Required. The implementer knows WHAT to test but not WHERE. Existing test files follow the pattern `test/screens/trip_detail_screen_test.dart` (uses `setTestDatabase()` + `pumpWidget`). The map picker test needs the same pattern plus geocoder mocking — but without a Changes Required entry, the file path and setup pattern are left implicit.

- **Fix**: Add a Changes Required item: "#### 6. Create widget test file" with `**File**: test/screens/map_picker_screen_test.dart`, intent (test search rendering, debounce, results display, error states), and contract (use `setTestDatabase()` pattern, mock geocoder via overridable wrapper).
- **Decision**: FIXED — added Changes Required item 7 for test file creation with File, Intent, Contract

### F2 — Mock injection strategy unspecified

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Blind Spots
- **Location**: Testing Strategy — Widget Tests section

- **Detail**: The plan says to use a `setTestGeocoder()` pattern matching existing `setTestDatabase()`, but the two are structurally different. `setTestDatabase()` works because `AppDatabase._db` is a module-level static variable. Geocoding has no such singleton — the `Geocoding()` class is instantiated directly. The implementer would need to design injection from scratch (overridable wrapper class? `@visibleForTesting` setter? constructor injection?) without guidance.

- **Fix A ⭐ Recommended**: Extract a thin `GeocodingService` wrapper class with an overridable `locationFromAddress` method. The test injects a mock via constructor or setter.
  - Strength: Clean separation, testable, matches existing `TimelineService` pattern (pure-logic service class already in lib/services/).
  - Tradeoff: Adds ~30 lines of wrapper code for what's currently a one-line call.
  - Confidence: HIGH — `lib/services/` already has service classes; this follows the established pattern.
  - Blind spot: Whether `Geocoding().locationFromAddress()` has side effects that a mock would mask.

- **Fix B**: Keep geocoding inline in MapPickerScreen, use `@visibleForTesting` to override the `_performSearch` method.
  - Strength: Zero new files, minimal structural change.
  - Tradeoff: Testing private methods is fragile; `@visibleForTesting` annotations scatter testing concerns.
  - Confidence: LOW — this pattern isn't used elsewhere in the project.
  - Blind spot: Whether the test framework can cleanly override a private method on a State object.
- **Decision**: FIXED via Fix A — added GeocodingService wrapper in lib/services/ (Changes Required item 2) with setTestGeocodingService() pattern

### F3 — Cache LRU eviction not in Changes Required contract

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Performance Considerations vs Changes Required item 2

- **Detail**: Performance Considerations says "LinkedHashMap, capped at 50 entries, LRU-eviction" but Changes Required item 2 only lists `_cache: Map<String, List<Location>>` as a new field. The implementer reading Changes Required might use a plain `HashMap` without eviction. At MVP scale (~dozens of queries per session) this doesn't matter, but the plan's own spec is inconsistent with its contract.

- **Fix**: In Changes Required item 2, change the cache field contract to: `_cache: LinkedHashMap<String, List<Location>>` with note "evict eldest entry when size > 50".
- **Decision**: FIXED — cache moved to GeocodingService (Change 2) with LinkedHashMap + 50-entry cap in contract

### F4 — `_searchResults` clearing on map tap implicit

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Change 3 (overlay) — Contract

- **Detail**: The overlay change mentions "Tapping outside the overlay (on the map) clears results — handled by existing `onTap` on `GoogleMap`; extend it to clear `_searchResults`." The current `onTap` callback is `(pos) => setState(() => _position = pos)`. Extending it to also do `_searchResults = []` is a one-line addition, but it's embedded in prose rather than an explicit contract bullet. The implementer skimming the Contract could miss it.

- **Fix**: In Change 3 Contract, add an explicit bullet: "Extend existing `onTap` to also set `_searchResults = []` (dismiss overlay on map tap)."
- **Decision**: FIXED — added explicit Contract bullet for clearing _searchResults on map tap in Change 4

