<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: S-08 Map Search (Geocoding)

- **Plan**: context/changes/map-search/plan.md
- **Scope**: Phase 1 of 1
- **Date**: 2026-08-05
- **Verdict**: APPROVED
- **Findings**: 0 critical, 3 warnings, 6 observations — all fixed

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | PASS |
| Architecture | PASS |
| Pattern Consistency | PASS |
| Success Criteria | PASS |

## Findings

### F1 — Unreachable "Failed to search" error message

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: `lib/services/geocoding_service.dart:40-54` → `lib/screens/map_picker_screen.dart:311`
- **Detail**: `PlacesService.autocomplete()` caught `PlacesException` and generic `Exception`, returning `[]` for all failure modes. The screen's catch block was dead code.
- **Fix**: Removed generic catch; `PlacesException` now logged then rethrown. Screen's catch block fires on real errors.
- **Decision**: FIXED (Fix A — log + rethrow from service)

### F2 — Stale autocomplete response race

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Safety & Quality
- **Location**: `lib/screens/map_picker_screen.dart:79-82, 289-314`
- **Detail**: No request sequencing. `initState` prefill and keystroke debounce could overlap; slow SDK responses could overwrite newer results.
- **Fix**: Added `_searchSeq` monotonic counter; discard stale responses. Prefill now routed through `_searchTimer` (debounce timer) instead of raw `Future.delayed`.
- **Decision**: FIXED (Fix A — _searchSeq + prefill via Timer)

### F3 — Fallback Confirm button enabled without valid input

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Safety & Quality
- **Location**: `lib/screens/map_picker_screen.dart:126`
- **Detail**: When `_timedOut`, Confirm button always enabled but silently no-ops if coordinate parsing fails.
- **Fix**: Added `_fallbackCoordsValid` getter; Confirm enabled only when both lat/lon parse and validate. Added `onChanged` callbacks to fallback text fields for reactivity.
- **Decision**: FIXED

### F4 — _selectedName not cleared on map re-tap

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Safety & Quality
- **Location**: `lib/screens/map_picker_screen.dart:147-150`
- **Detail**: After picking a search result, tapping a different map location kept the old `_selectedName`, creating name/coordinate mismatch in DB.
- **Fix**: Added `_selectedName = null` to map `onTap` handler.
- **Decision**: FIXED

### F5 — Unguarded (0,0) coordinates in details()

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Safety & Quality
- **Location**: `lib/services/geocoding_service.dart:68-88`
- **Detail**: If SDK returns place without `latLng`, `details()` produced (0,0) — Gulf of Guinea instead of error.
- **Fix**: Return `null` when `place.latLng == null`. Screen already handles null → "Could not load place details."
- **Decision**: FIXED

### F6 — Doc comment claims session-free pricing but no session tokens

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Safety & Quality
- **Location**: `lib/services/geocoding_service.dart:11-14`
- **Detail**: Header said "free within a session ending in fetchPlace" but no `sessionToken` is implemented.
- **Fix**: Updated comment to reflect per-call pricing.
- **Decision**: FIXED

### F7 — _openInMaps ignores coordinates and unhandled launch failure

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Safety & Quality
- **Location**: `lib/screens/map_picker_screen.dart:112-117`
- **Detail**: Always opened bare `maps.google.com`; `launchUrl` could throw uncaught `PlatformException`.
- **Fix**: Added `?q=lat,lng` when coordinates are known. Wrapped `launchUrl` in try/catch.
- **Decision**: FIXED

### F8 — Zero coverage of timeout/manual-fallback branch

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Success Criteria
- **Location**: `test/screens/map_picker_screen_test.dart`
- **Detail**: Fallback UI had zero test coverage. F3 would have been caught.
- **Fix**: Added 3 widget tests: fallback UI renders after 5s, Confirm enables/disables with valid/invalid coords, valid coords + Confirm returns result. (Total: 77 tests, +3)
- **Decision**: FIXED

### F9 — Misleading service file name

- **Severity**: 💡 OBSERVATION
- **Impact**: 🏃 LOW — quick decision
- **Dimension**: Pattern Consistency
- **Location**: `lib/services/geocoding_service.dart`
- **Detail**: File named `geocoding_service.dart` but contains `PlacesService` (autocomplete + details, not geocoding).
- **Fix**: Renamed to `lib/services/places_service.dart`. Updated imports in `map_picker_screen.dart` and test file.
- **Decision**: FIXED
