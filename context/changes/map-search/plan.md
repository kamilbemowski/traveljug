# S-08: Map Search (Geocoding) — Implementation Plan

## Overview

Add a search bar with Place autocomplete to the existing `MapPickerScreen`. User types a place name (minimum 3 characters), sees matching predictions as a dropdown overlay above the map, taps a result → fetches place details (coordinates + name) → map animates to position, pin appears, Confirm returns both coordinates AND the place name. Uses `flutter_places_sdk` (native Google Places SDK). Existing tap-to-place and timeout fallback behaviors are preserved.

> **Implementation note (2026-08-05):** The implementation used `flutter_places_sdk` (Google Places SDK native) instead of the `geocoding` package originally considered. This gives richer results — place names, autocomplete predictions, and structured addresses — at the cost of requiring a Google API key. The free tier covers 10,000 autocomplete + 10,000 details per month.

## Current State Analysis

- `lib/screens/map_picker_screen.dart` (362 lines) — full-screen map picker with GoogleMap widget, tap-to-place pin, search bar with autocomplete, predictions overlay, 5-second timeout fallback to manual coordinate entry.
- `lib/services/geocoding_service.dart` (113 lines) — `PlacesService` wrapping `flutter_places_sdk`, with in-memory session cache (LinkedHashMap, 50 entries, LRU eviction), test injection via `setTestPlacesService()`.
- `lib/screens/trip_detail_screen.dart` — both `_AddAttractionDialog` and `_EditAttractionDialog` call `MapPickerScreen.show(context, searchQuery: ...)` and receive `MapPickerResult` (coordinates + name).
- `flutter_places_sdk: ^0.1.0` in `pubspec.yaml`. API key injected via `--dart-define=MAPS_API_KEY=...`.
- `google_maps_flutter: ^2.18.0` — map rendering and marker API.
- No schema changes needed. No DAO or timeline engine changes.

### Key Design Decisions:

- **`MapPickerResult`** (not bare `LatLng`) — carries both `coordinates` and `name` so the attraction dialog can pre-fill the place name.
- **`PlacesService` singleton** — `getPlacesService()` for production, `setTestPlacesService()` for tests (matching the `setTestDatabase()` pattern).
- **`searchQuery` parameter** — `MapPickerScreen.show(context, searchQuery: ...)` pre-fills the search bar. Both add/edit attraction dialogs pass the current name text.
- **`@visibleForTesting fetchPredictions()`** — overridable hook so cache tests can intercept SDK calls without mocking the native layer.

## Desired End State

User opens MapPickerScreen → sees search field at top of map → types "wieża eiffla" (min 3 chars) → after 300ms pause, overlay shows autocomplete predictions with place names and addresses → taps first result → SDK fetches place details → map animates to coordinates, pin appears → Confirm returns `MapPickerResult(coordinates, name)`. If API key missing, inline message suggests manual coordinate entry. Results cached in memory for the session — repeat searches are instant.

## What We're NOT Doing

- No search history persistence across sessions (session-only cache)
- No reverse geocoding (coordinates → address)
- No autocomplete suggestions while typing (only search after 3+ chars)
- No separate search screen — everything happens on the map
- No changes to `_AddAttractionDialog` or `_EditAttractionDialog` beyond passing `searchQuery`
- No OSM Nominatim fallback (Google Places SDK only)

## Implementation Approach

Single phase — one screen modification + one service file. Add search bar + predictions overlay + place-details fetch + session cache to `MapPickerScreen`. Use `flutter_places_sdk` which talks to the native Android/iOS Places SDK. One new service file (`geocoding_service.dart`), one new test file.

## Critical Implementation Details

- **Timing & lifecycle**: The search debounce timer (300ms) must be cancelled in `dispose()` alongside the existing timeout timer. Two timers, both need cleanup.
- **State sequencing**: Search field must be hidden when `_timedOut == true` (fallback mode shows manual entry UI, not map). Check `_timedOut` before rendering search bar and before calling Places SDK.
- **API key**: Injected at build time via `--dart-define=MAPS_API_KEY=...`. The `String.fromEnvironment('MAPS_API_KEY')` call returns `''` when not set — `PlacesService.isAvailable` checks for empty key.
- **ProGuard**: Release builds need `-keep` rules for `flutter_places_sdk` native bindings (added in `android/app/proguard-rules.pro`).

---

## Phase 1: Geocoding search in MapPickerScreen

### Overview

Add search field + predictions overlay + place-details fetch + in-memory cache to the existing map picker. User can find places by name, see structured results (name + address), and pin them on the map. Existing tap-to-place and timeout fallback preserved.

### Changes Required:

#### 1. Add flutter_places_sdk dependency

**File**: `pubspec.yaml`

**Intent**: Add `flutter_places_sdk` for native Google Places autocomplete and place details.

**Contract**: Add `flutter_places_sdk: ^0.1.0` under dependencies.

#### 2. Create PlacesService wrapper

**File**: `lib/services/geocoding_service.dart` (new file)

**Intent**: Wrap `flutter_places_sdk` in a service class so the SDK can be mocked in tests. Matches the existing pattern in `lib/services/timeline_service.dart`. Also encapsulates the in-memory session cache.

**Contract**:
- Class `PlacesService` with:
  - `autocomplete(String query)` → `Future<List<AutocompletePrediction>>` — SDK autocomplete with cache check/store
  - `details(String placeId)` → `Future<PlaceDetails?>` — fetch place coordinates + name
  - `fetchPredictions(String query)` → overridable hook for tests
  - `clearCache()` — for test cleanup
  - `isAvailable` — checks API key is non-empty
- Cache: `LinkedHashMap<String, List<AutocompletePrediction>>` keyed by lowercased query, capped at 50 entries, evicts eldest on overflow
- `PlaceDetails` data class with `name`, `latitude`, `longitude`
- `kPlacesApiKey` const from `String.fromEnvironment('MAPS_API_KEY')`
- Singleton: `getPlacesService()`, `setTestPlacesService()`, `clearTestPlacesService()`

#### 3. Add search bar to the map view

**File**: `lib/screens/map_picker_screen.dart` (`_MapPickerScreenState`)

**Intent**: Add a search `TextField` at the top of the map view (hidden when `_timedOut`). Uses a `Timer`-based 300ms debounce. Minimum 3 characters to trigger search.

**Contract**:
- New fields: `_searchController`, `_searchTimer`, `_predictions: List<AutocompletePrediction>`, `_searching: bool`, `_searchError: String?`, `_selectedName: String?`
- `_buildSearchBar()` — `Card` with `TextField`, search icon prefix, clear button / spinner suffix
- `onChanged`: clear timer, if `length >= 3` set 300ms debounce → `_performSearch(text)`
- `_performSearch(query)`: calls `getPlacesService().autocomplete(query)` → `setState`
- `initState()`: pre-fill search if `widget.searchQuery` is provided, trigger delayed search
- `dispose()`: cancel `_searchTimer`, dispose `_searchController`

#### 4. Add predictions overlay dropdown

**File**: `lib/screens/map_picker_screen.dart` (`_MapPickerScreenState`)

**Intent**: When predictions exist, show them as a `ListView` overlay below the search field. Tapping a result fetches place details, moves the map, and sets the pin.

**Contract**:
- `_buildPredictionsOverlay()` — `Positioned` `Card` with `ListView.builder`, each tile shows `primaryText` + `secondaryText` + location icon
- `onTap` → `_onPredictionTap(prediction)`:
  1. Sets `_searching = true`, clears predictions
  2. Calls `getPlacesService().details(prediction.placeId)`
  3. Sets `_position`, `_selectedName`, `_searchController.text`
  4. Animates camera via `_controller.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15))`
  5. Sets `_searching = false`
- Map tap also clears predictions (`onTap: ... { _predictions = []; }`)

#### 5. MapPickerResult (named result)

**File**: `lib/screens/map_picker_screen.dart`

**Intent**: Return both coordinates and place name so the attraction dialog can pre-fill the name field. Replaces bare `LatLng` return.

**Contract**:
- Class `MapPickerResult` with `coordinates: LatLng` and `name: String`
- `show()` returns `Future<MapPickerResult?>` and accepts optional `searchQuery`
- `_confirm()` pops with `MapPickerResult(coordinates: result, name: _selectedName ?? '')`

#### 6. Error handling and availability

**File**: `lib/screens/map_picker_screen.dart`

**Intent**: Check Places SDK availability before searching. Show inline error messages for failures.

**Contract**:
- In `_performSearch()`: check `getPlacesService().isAvailable`, show error if unavailable
- On empty results: show "No places found."
- On exception: show "Failed to search. Check your connection."
- On failed place details: show "Could not load place details. Try again."
- `_searchError` cleared on next keystroke

#### 7. Hide search UI when map times out

**File**: `lib/screens/map_picker_screen.dart`

**Intent**: When the map fails to load (existing 5-second timeout), hide the search bar. The fallback view already shows manual coordinate entry.

**Contract**: In `_buildMap()`: wrap search bar + overlay in `if (!_timedOut)`.

#### 8. Create widget test file

**File**: `test/screens/map_picker_screen_test.dart` (new file)

**Intent**: Widget tests verifying search field renders, debounce triggers after 300ms, predictions overlay appears with mock data, tapping result sets pin, error states show inline message, and cache returns results without repeated SDK calls.

**Contract**:
- `MockPlacesService` extends `PlacesService`, overrides `autocomplete()` and `details()`
- `CacheTestPlacesService` extends `PlacesService`, overrides `fetchPredictions()`, counts calls
- Tests: search field renders, <3 chars shows nothing, 3+ chars triggers autocomplete, tap fetches details + sets pin, auto-search on `searchQuery`, empty results error, missing API key error, cache avoids repeat SDK calls

#### 9. ProGuard rules for release builds

**File**: `android/app/proguard-rules.pro`

**Intent**: Prevent R8 from stripping `flutter_places_sdk` native method bindings in release builds.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter test` — all 74 tests pass (73 existing + 1 cache test)
- Widget test: search field renders on map screen
- Widget test: typing 3+ characters triggers search after 300ms debounce
- Widget test: results overlay appears with mock predictions, tap fetches details + sets pin
- Widget test: auto-search when `searchQuery` is passed
- Widget test: search bar hidden in fallback mode (via timeout)
- Widget test: error message when autocomplete returns empty
- Widget test: error message when API key is missing
- Widget test: cache returns results for repeat query without calling SDK again

#### Manual Verification:

- Open map picker from Add Attraction → search "Eiffel Tower" → predictions appear → tap → map moves to Eiffel Tower coordinates, pin visible, name pre-filled
- Search "Luwr" → results appear → clear field → predictions disappear
- Search with < 3 chars → no predictions, no API call
- Disable network → search → inline error message appears
- Timeout fallback still works — wait 5s on slow/no connection → manual entry view appears
- Edit attraction → map picker opens with current name pre-filled in search

---

## Testing Strategy

### Widget Tests:

- Search field renders when map is loaded, hidden when timed out
- Debounce: search triggered after 300ms, not immediately
- Min query length: < 3 chars shows no results
- Predictions overlay: items render, tap fetches details and sets pin position
- Auto-search: passing `searchQuery` triggers search on open
- Error state: inline error message when autocomplete returns empty or API key missing
- Cache: `fetchPredictions` called only once for repeated query

Mock approach: `MockPlacesService` overrides `autocomplete()`/`details()` with canned callbacks. `CacheTestPlacesService` overrides `fetchPredictions()` and counts calls, letting the real `autocomplete()` cache path run.

### Manual Testing Steps:

1. Open Add Attraction → Pick on map → search "Eiffel Tower" → tap result → Confirm → coordinates + name populate
2. Search "asdfghjkl" → "No places found." message
3. Missing API key → "Places search not available." message
4. Type 2 chars "Pa" → no search triggered
5. Type "Paris" → wait 300ms → predictions appear → tap map background → predictions dismiss
6. Existing tap-to-place still works — tap map directly, pin appears, Confirm works
7. Edit attraction with existing place name → map opens with name pre-filled in search

## Performance Considerations

- In-memory cache capped at 50 entries, LRU-eviction via `LinkedHashMap` — prevents unbounded growth
- Debounce 300ms prevents excessive SDK calls while typing
- `findAutocompletePredictions()` uses native Places SDK (~50-200ms latency)
- `fetchPlace()` is only called on tap (not during typing) — minimizes API costs

## Migration Notes

No migration needed. New package only. Schema unchanged at v4.

## References

- Research: `context/changes/map-search/research.md`
- Existing map picker: `lib/screens/map_picker_screen.dart`
- Places service: `lib/services/geocoding_service.dart`
- PRD v2: `context/foundation/prd-v2.md` — S-08
- ProGuard rules: `android/app/proguard-rules.pro`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Geocoding search in MapPickerScreen

#### Automated

- [x] 1.1 `flutter analyze` passes
- [x] 1.2 `flutter test` — all 74 tests pass
- [x] 1.3 Widget test: search field renders, hidden in fallback mode
- [x] 1.4 Widget test: typing 3+ chars triggers debounced search, predictions overlay appears
- [x] 1.5 Widget test: tapping result fetches details and sets pin position
- [x] 1.6 Widget test: geocoder error shows inline message
- [x] 1.6a Widget test: auto-search when searchQuery is passed
- [x] 1.6b Widget test: cache avoids repeat SDK calls

#### Manual

- [ ] 1.7 Search "Eiffel Tower" → predictions → tap → map moves, pin set, name populated
- [ ] 1.8 Search < 3 chars → no API call
- [ ] 1.9 Network off → inline error message
- [ ] 1.10 Timeout fallback still works after 5s
- [ ] 1.11 Cache: repeat query returns instant results
- [ ] 1.12 Edit attraction: map opens with existing name pre-filled in search
