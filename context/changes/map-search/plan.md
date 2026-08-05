# S-08: Map Search (Geocoding) — Implementation Plan

## Overview

Add a search bar with geocoding to the existing `MapPickerScreen`. User types a place name (minimum 3 characters), sees matching results as a dropdown overlay above the map, taps a result to move the map and drop a pin. Uses Flutter Geocoding plugin (free, no API key, native Android geocoder via Google Play Services). Existing tap-to-place and timeout fallback behaviors are preserved.

## Current State Analysis

- `lib/screens/map_picker_screen.dart` (152 lines) — full-screen map picker with GoogleMap widget, tap-to-place pin, 5-second timeout fallback to manual coordinate entry. No search functionality.
- `lib/screens/trip_detail_screen.dart:703-806` — `_AddAttractionDialog` calls `MapPickerScreen.show(context)` and receives `LatLng?`.
- `google_maps_flutter: ^2.18.0` already in `pubspec.yaml` — map rendering and marker API.
- Package `geocoding: ^4.0.0` by Baseflow needed — uses Android's native Geocoder (Google Play Services), free, no API key.
- No schema changes needed. No DAO or timeline engine changes.

### Key Discoveries:

- `MapPickerScreen._position` (line 27) — the existing pin state. Search results will set this directly.
- `MapPickerScreen._timedOut` (line 29) — when true, switches to fallback view. Search bar is hidden in fallback mode.
- `_AddAttractionDialogState._showLocation` (line 798 in trip_detail_screen.dart) — controls whether map picker button is visible. Integration point unchanged.
- `Geocoding().locationFromAddress()` returns `List<Location>` — Android Geocoder API via Play Services. `Location` has `latitude`, `longitude`, `timestamp`.
- `Geocoder.isPresent()` (Android only) — checks Play Services availability before calling geocoder.

## Desired End State

User opens MapPickerScreen → sees search field at top of map → types "wieża eiffla" (min 3 chars) → after 300ms pause, overlay shows matching results → taps first result → map animates to `48.8584, 2.2945`, pin appears → Confirm returns coordinates. If geocoder unavailable, inline message suggests manual coordinate entry. Results cached in memory for the session — repeat searches are instant.

## What We're NOT Doing

- No search history persistence across sessions (session-only cache)
- No reverse geocoding (coordinates → address)
- No autocomplete suggestions while typing (only search after 3+ chars)
- No separate search screen — everything happens on the map
- No changes to `_AddAttractionDialog` or any other screen
- No Google Geocoding API key or billing setup
- No OSM Nominatim fallback (Flutter Geocoding only)

## Implementation Approach

Single phase — one screen modification. Add search bar + results overlay + geocoding call + session cache to `MapPickerScreen`. Use Flutter Geocoding plugin which talks to Android's native Geocoder (free, already present via Play Services). No new files beyond tests. Mock the geocoding layer in widget tests.

## Critical Implementation Details

- **Timing & lifecycle**: The search debounce timer (300ms) must be cancelled in `dispose()` alongside the existing timeout timer. Two timers, both need cleanup.
- **State sequencing**: Search field must be hidden when `_timedOut == true` (fallback mode shows manual entry UI, not map). Check `_timedOut` before rendering search bar and before calling geocoder.

---

## Phase 1: Geocoding search in MapPickerScreen

### Overview

Add search field + results overlay + in-memory cache to the existing map picker. User can find places by name and pin them on the map. Existing tap-to-place and timeout fallback preserved.

### Changes Required:

#### 1. Add geocoding dependency

**File**: `pubspec.yaml`

**Intent**: Add the `geocoding` Flutter package for native Android geocoding.

**Contract**: Add `geocoding: ^4.0.0` under dependencies, next to `google_maps_flutter`.

#### 2. Create GeocodingService wrapper

**File**: `lib/services/geocoding_service.dart` (new file)

**Intent**: Wrap the `geocoding` package in a service class so the geocoder can be mocked in tests. Matches the existing pattern in `lib/services/timeline_service.dart` (stateless service with static or instance methods). Also encapsulates the in-memory cache.

**Contract**:
- Class `GeocodingService` with method `Future<List<GeocodingLocation>> search(String query)`.
- Internally calls `Geocoding().locationFromAddress(query)`.
- Maintains `_cache: LinkedHashMap<String, List<GeocodingLocation>>`, capped at 50 entries (evict eldest on insert when full).
- `GeocodingLocation` is a simple data class with `latitude: double` and `longitude: double` (decouples from the `geocoding` package's `Location` type).
- For tests: add a module-level `setTestGeocodingService(GeocodingService service)` function + `_instance` static, mirroring the `setTestDatabase()` / `getDatabase()` pattern.

#### 3. Add search bar to the map view

**File**: `lib/screens/map_picker_screen.dart` (`_MapPickerScreenState`)

**Intent**: Add a search `TextField` at the top of the map view (hidden when `_timedOut`). Uses a `Timer`-based 300ms debounce. Minimum 3 characters to trigger search.

**Contract**:
- New fields: `_searchController: TextEditingController`, `_searchTimer: Timer?`, `_searchResults: List<GeocodingLocation>`, `_searching: bool`
- New widget: `_buildSearchBar()` — returns `TextField` with `InputDecoration(hintText: 'Search for a place...', prefixIcon: Icon(Icons.search))`, embedded in a `Padding` above the map in `_buildMap()` using a `Stack` + `Positioned`
- Cache lives inside `GeocodingService` (see Change 2) — not in the screen state.
- `onChanged`: clear previous timer, set new 300ms timer, on fire: if `text.length >= 3`, call `_performSearch(text)`
- `_performSearch(String query)`: calls `GeocodingService().search(query)` → `setState(() => _searchResults = locations)`
- `dispose()`: cancel `_searchTimer`, dispose `_searchController`

#### 4. Add results overlay dropdown

**File**: `lib/screens/map_picker_screen.dart` (`_MapPickerScreenState`)

**Intent**: When search results exist, show them as a `ListView` overlay below the search field, floating above the map. Tapping a result moves the map and sets the pin.

**Contract**:
- New widget: `_buildResultsOverlay()` — returns a `Positioned` `Card` with `ListView` of `ListTile`s. Each tile shows result name (from `Location.latitude, Location.longitude`). Max 5 results visible, scrollable if more.
- `onTap` per tile: `setState(() { _position = LatLng(loc.latitude, loc.longitude); _searchResults = []; });` — clears results, sets pin. Then call `_controller.animateCamera(CameraUpdate.newLatLng(...))` to move map.
- `_controller: GoogleMapController?` — new field, obtained from `GoogleMap.onMapCreated` callback (already exists at line 97, just capture the controller).
- Overlay appears only when `_searchResults.isNotEmpty`.
- Extend existing `onTap` callback on `GoogleMap` (line 100) to also set `_searchResults = []` — dismissing the overlay when the user taps the map directly.

#### 5. Add geocoder availability check and error handling

**File**: `lib/screens/map_picker_screen.dart` (`_MapPickerScreenState`)

**Intent**: Before searching, check if the geocoder is available. Show inline error messages for failures.

**Contract**:
- In `initState()`: call `Geocoding().isPresent()` and store result in `_geocoderAvailable: bool`.
- In `_performSearch()`: if `!_geocoderAvailable`, set `_searchError = 'Geocoding not available. Enter coordinates manually.'` and return.
- New field `_searchError: String?` — shown as `Text` below search field when non-null. Cleared on next keystroke.
- On `locationFromAddress()` exception: set `_searchError = 'Failed to find places. Check your connection.'`.

#### 6. Hide search UI when map times out

**File**: `lib/screens/map_picker_screen.dart` (`_MapPickerScreenState`)

**Intent**: When the map fails to load (existing 5-second timeout), hide the search bar. The fallback view already shows manual coordinate entry — search is irrelevant when there's no map.

**Contract**: In `_buildMap()`: wrap the search bar + overlay in `if (!_timedOut)`. The existing `_timedOut` check at line 87 already switches between `_buildMap()` and `_buildFallback()`.

#### 7. Create widget test file

**File**: `test/screens/map_picker_screen_test.dart` (new file)

**Intent**: Widget tests verifying search field renders, debounce triggers after 300ms, results overlay appears with mock data, tapping result sets pin, and error states show inline message. Matches the existing pattern in `test/screens/trip_detail_screen_test.dart`.

**Contract**:
- Use `setTestDatabase()` in `setUp` / `clearTestDatabase()` in `tearDown` (matching existing test files).
- Inject mock geocoder via overridable `_performSearch` method on a test subclass, or a thin `GeocodingService` wrapper — whichever the implementer prefers.
- Pump `MapPickerScreen` inside `MaterialApp`, trigger search via `tester.enterText()`, advance timers for debounce, assert overlay widgets appear.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter test` — all 66 existing tests pass (no regression)
- Widget test: search field renders on map screen
- Widget test: typing 3+ characters triggers search after 300ms debounce
- Widget test: results overlay appears with mock results, tap sets position
- Widget test: search bar hidden in fallback mode
- Widget test: cache returns same results for repeated query

#### Manual Verification:

- Open map picker from Add Attraction → search "Eiffel Tower" → overlay shows results → tap → map moves to Eiffel Tower coordinates, pin visible
- Search "Luwr" → results appear → clear field → results disappear
- Search with < 3 chars → no results, no API call
- Disable network → search → inline error message appears
- Timeout fallback still works — wait 5s on slow/no connection → manual entry view appears
- Cache works: search same query twice → second result instant (no network call)

---

## Testing Strategy

### Widget Tests:

- Search field renders when map is loaded, hidden when timed out
- Debounce: search triggered after 300ms, not immediately
- Min query length: < 3 chars shows no results
- Results overlay: items render, tap sets pin position
- Error state: inline error message when geocoder throws
- Cache: mock geocoder returns stored results on second call

Mock approach: wrap the geocoding call in a thin method (`_geocode(String query)`) that can be overridden or injected in tests. Use a `setTestGeocoder()` pattern matching existing `setTestDatabase()`.

### Manual Testing Steps:

1. Open Add Attraction → Pick on map → search "Eiffel Tower" → tap result → Confirm → coordinates populate
2. Search "asdfghjkl" → "No places found" message
3. Airplane mode → search anything → "Geocoding not available" message
4. Type 2 chars "Pa" → no search triggered
5. Type "Paris" → wait 300ms → results appear → tap map background → results dismiss
6. Existing tap-to-place still works — tap map directly, pin appears, Confirm works

## Performance Considerations

- In-memory cache capped at 50 entries, LRU-eviction via `LinkedHashMap` — prevents unbounded growth for edge case of hundreds of unique queries
- Debounce 300ms prevents excessive geocoder calls while typing
- `locationFromAddress()` calls Android Geocoder (local, no network needed for Play Services), ~10-50ms latency

## Migration Notes

No migration needed. New package only. Schema unchanged at v4.

## References

- Research: `context/changes/map-search/research.md`
- Existing map picker: `lib/screens/map_picker_screen.dart`
- Flutter Geocoding docs: `/baseflow/flutter-geocoding` (Context7)
- PRD v2: `context/foundation/prd-v2.md` — S-08

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Geocoding search in MapPickerScreen

#### Automated

- [x] 1.1 `flutter analyze` passes
- [x] 1.2 `flutter test` — all 66 existing tests pass
- [x] 1.3 Widget test: search field renders, hidden in fallback mode
- [x] 1.4 Widget test: typing 3+ chars triggers debounced search, results overlay appears
- [x] 1.5 Widget test: tapping result sets pin position
- [x] 1.6 Widget test: geocoder error shows inline message

#### Manual

- [ ] 1.7 Search "Eiffel Tower" → results → tap → map moves, pin set
- [ ] 1.8 Search < 3 chars → no API call
- [ ] 1.9 Network off → inline error message
- [ ] 1.10 Timeout fallback still works after 5s
- [ ] 1.11 Cache: repeat query returns instant results
