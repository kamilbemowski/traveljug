# S-06: Location-Based Travel Time — Implementation Plan

## Overview

Replace the flat travel-time default with real distances between consecutive attractions. User optionally taps a location on a Google Map for each attraction. The timeline computes straight-line Haversine distance, applies a distance-bracket detour factor, converts to travel minutes based on trip context (walking vs driving speed), and falls back to the S-04 flat default when coordinates are missing. Pure addition — existing trips without coordinates behave identically.

## Current State Analysis

- `kDefaultTravelMinutes = 30` in `lib/services/pace_config.dart:7` — used by `TimelineService.computeTimeline()` and `reapplyOverrides()`
- S-04 already parameterized `baseTravel` per trip context (20/90/30 min). S-06 builds on top — when coordinates are present, real distance replaces the base travel time per attraction pair.
- `Attractions` table has no coordinate columns (schema v3)
- `_AddAttractionDialog` has no location input
- No geo computation exists anywhere in the codebase
- No `google_maps_flutter` dependency

### Key Discoveries:

- `lib/services/timeline_service.dart:37` — `travelCost = isFirstInDay ? 0 : effectiveTravel` — the main consumption site (also lines 45 and 73 for `travelFromPrevMin`); all three replaced in Phase 3
- `lib/services/timeline_service.dart:153` — `reapplyOverrides()` also recomputes travel gaps flat at line 153 (`(baseTravel * config.travelMultiplier).round()`) — must also be updated
- `lib/database/tables.dart:42-79` — `Attractions` table, two new `real().nullable()` columns needed
- `lib/database/app_database.dart:13` — `schemaVersion = 3`, bump to 4 with `m.addColumn` migration
- Existing CI pattern for secrets: `GOOGLE_SERVICES_JSON` base64-decoded in `pr-check.yml:23-27`

## Desired End State

When adding an attraction, user taps "Add location (optional)" → full-screen Google Map opens → user taps the location → coordinates auto-fill behind the scenes. When viewing the timeline between two consecutive attractions that both have coordinates, the travel gap shows a distance-based estimate (Haversine × detour factor × speed) instead of the flat default. Attractions without coordinates, or trips entirely without coordinates, fall back to S-04 flat defaults. Works offline with graceful degradation (map timeout → prompt to open Google Maps app).

## What We're NOT Doing

- No geocoding API (search by name → coordinates). Map is tap-only for MVP.
- No routing API. Straight-line Haversine + detour factor is the MVP approach.
- No per-attraction travel time override.
- No reverse geocoding (coordinates → address). Stored as raw lat/lon.
- No GPS-based auto-location. User must explicitly tap.
- No iOS configuration yet (Android-only for this slice).

## Implementation Approach

```
Schema (v4) → geo_utils.dart (Haversine + detour) → TimelineService (per-pair)
     + google_maps_flutter dependency + API key config
     + Map picker full-screen dialog in _AddAttractionDialog
```

Phase order matters: schema first (unblocks everything), then geo computation (testable in isolation), then timeline integration (depends on both), then UI (depends on all three), then CI.

## Critical Implementation Details

- **Google Maps Flutter initialization**: `WidgetsFlutterBinding.ensureInitialized()` must be called before `GoogleMap` widget. The `_AddAttractionDialog` opens from a button `onPressed` — by that point Flutter is already initialized, so this is satisfied. If the map picker is a separate route pushed via `Navigator.push`, no additional init is needed.
- **API key in CI**: the same pattern as `GOOGLE_SERVICES_JSON` — store the key as a GitHub Secret (`MAPS_API_KEY`), write it into `android/app/local.properties` during CI workflow before `flutter build`. Local development uses the developer's own `local.properties` (gitignored).

---

## Phase 1: Schema — coordinate columns + migration v3→v4

### Overview

Add nullable `latitude` / `longitude` `RealColumn`s to `Attractions`, bump schema version, regenerate drift code, update DAO. No logic changes yet — existing tests must still pass with new columns.

### Changes Required:

#### 1. Attractions table — coordinate columns

**File**: `lib/database/tables.dart` (Attractions class)

**Intent**: Add two nullable real columns for GPS coordinates just before the `tripId` FK. `real()` maps to SQLite REAL (IEEE 754 double) — appropriate for lat/lon.

**Contract**:
- `RealColumn get latitude => real().nullable()();`
- `RealColumn get longitude => real().nullable()();`

#### 2. Schema migration v3→v4

**File**: `lib/database/app_database.dart`

**Intent**: Bump `schemaVersion` to 4, add migration step. Nullable columns — backward compatible, existing rows get NULL.

**Contract**:
- `schemaVersion => 4`
- `onUpgrade`: add `if (from < 4) { await m.addColumn(attractions, attractions.latitude); await m.addColumn(attractions, attractions.longitude); }`

#### 3. DAO — createAttraction / updateAttraction

**File**: `lib/database/daos/attraction_dao.dart`

**Intent**: Accept optional `double? latitude, longitude` params. Follow existing optional-param pattern (`Value(latitude)`, `Value.absentIfNull(latitude)`).

**Contract**:
- `createAttraction()`: add `double? latitude, double? longitude` params, pass via `Value(latitude)` / `Value(longitude)` in `AttractionsCompanion.insert()`
- `updateAttraction()`: add `double? latitude, double? longitude` params, pass via `Value.absentIfNull(latitude)` / `Value.absentIfNull(longitude)`

#### 4. Regenerate drift code

**File**: `lib/database/app_database.g.dart`, `lib/database/daos/attraction_dao.g.dart`

**Intent**: Generated code reflects new schema.

**Contract**: `dart run build_runner build` succeeds.

#### 5. Update schema version in integration test

**File**: `test/integration/seed_integration_test.dart`

**Intent**: Assert `schemaVersion == 4` instead of `3`.

**Contract**: Line 119: `expect(db.schemaVersion, 4, ...)`

### Success Criteria:

#### Automated Verification:

- `dart run build_runner build` succeeds
- `flutter analyze` passes
- `flutter test` — all 48 existing tests pass (backward compatible — new nullable columns don't break anything)

#### Manual Verification:

- `lib/database/tables.dart` has `latitude` / `longitude` RealColumns on Attractions
- `lib/database/app_database.dart` has `schemaVersion = 4`

---

## Phase 2: Geo computation — Haversine + detour factor

### Overview

Create `lib/services/geo_utils.dart` with pure `dart:math` Haversine formula and distance-bracket detour factor. Add speed constants and `speedKmhForContext()` to `pace_config.dart`. Unit-test Haversine against known city pairs and detour factor bracket boundaries.

### Changes Required:

#### 1. Geo utilities (new file)

**File**: `lib/services/geo_utils.dart` (new)

**Intent**: Pure-function great-circle distance with input validation. No dependencies beyond `dart:math`.

**Contract**:
- `const kEarthRadiusKm = 6371.0`
- `double? haversineKm(double? lat1, double? lon1, double? lat2, double? lon2)` — returns null if any coordinate is null or out of range (|lat| > 90, |lon| > 180)
- `double detourFactor(double km)` — returns bracket factor: <10 km → 1.6, 10–50 → 1.35, 50–200 → 1.2, >200 → 1.15
- `double? detourAdjustedKm(double? lat1, double? lon1, double? lat2, double? lon2)` — `haversineKm(…)` → if non-null → `* detourFactor(km)`

#### 2. Speed constants

**File**: `lib/services/pace_config.dart`

**Intent**: Add speed constants and lookup function. Road trip speed raised to 75 km/h because the detour factor now explicitly handles road circuity.

**Contract**:
- `const kCitySpeedKmh = 5.0`, `const kRoadTripSpeedKmh = 75.0`, `const kDefaultSpeedKmh = 5.0`
- `const kMinPairTravelMin = 5` — minimum buffer between stops with coordinates (pre-multiplier, prevents 0 min for same-point attractions)
- `double speedKmhForContext(TravelContext? context)` — returns 5/75/5 for city/roadTrip/null

#### 3. Geo utils tests (new file)

**File**: `test/services/geo_utils_test.dart` (new)

**Intent**: Verify Haversine against known distances and detour factor bracket boundaries.

**Contract**:
- Paris→London ≈ 343 km (closeTo 1.0)
- Same point → 0 km
- Warsaw→Krakow ≈ 252 km
- Equator quarter (0,0)→(0,90) ≈ 10007 km
- One null coord → null
- lat=95, lon=200 → null
- Detour factor brackets: 5 km → 1.6, 30 km → 1.35, 100 km → 1.2, 300 km → 1.15

### Success Criteria:

#### Automated Verification:

- `flutter test test/services/geo_utils_test.dart` — all Haversine + detour tests pass
- `flutter analyze` passes
- `flutter test` — all existing tests still pass

---

## Phase 3: Timeline integration — per-pair travel time

### Overview

Wire distance-based travel time into `computeTimeline()` and `reapplyOverrides()`. Add `pairTravelMinutes()` helper that combines Haversine + detour + speed + multiplier. Per-pair fallback to flat default when coordinates are missing. Update existing timeline tests to cover new edge cases.

### Changes Required:

#### 1. pairTravelMinutes helper

**File**: `lib/services/timeline_service.dart`

**Intent**: Single function that takes two attractions and returns the travel time between them, using coordinates if available, falling back to flat default otherwise.

**Contract**:
```dart
static int pairTravelMinutes(
  Attraction? prev, Attraction current, {
  required double speedKmh,
  required int fallbackMinutes,
  required double multiplier,
}) {
  if (prev == null) return 0; // first in day
  final km = detourAdjustedKm(prev.latitude, prev.longitude,
                               current.latitude, current.longitude);
  if (km == null) return fallbackMinutes;
  final baseMinutes = (km / speedKmh * 60).round();
  final buffered = baseMinutes < kMinPairTravelMin ? kMinPairTravelMin : baseMinutes;
  return (buffered * multiplier).round();
}
```

#### 2. computeTimeline — per-pair travel cost

**File**: `lib/services/timeline_service.dart` (computeTimeline method)

**Intent**: Track `previousAttr` through the loop. Replace `effectiveTravel` with `pairTravelMinutes()` for each pair. First attraction in day still has 0 travel cost.

**Contract**:
- Before loop: `final speedKmh = speedKmhForContext(parseTravelContext(trip.travelContext));` and `var previousAttr = attractions.first;`
- Replace `final travelCost = isFirstInDay ? 0 : effectiveTravel;` with `final travelCost = pairTravelMinutes(isFirstInDay ? null : previousAttr, attr, speedKmh: speedKmh, fallbackMinutes: effectiveTravel, multiplier: config.travelMultiplier);`
- Replace `travelFromPrevMin: isFirstInDay ? null : effectiveTravel` with `travelFromPrevMin: isFirstInDay ? null : travelCost` (at both construction sites)
- End of loop: `previousAttr = attr;`

#### 3. reapplyOverrides — per-pair travel gaps

**File**: `lib/services/timeline_service.dart` (reapplyOverrides method)

**Intent**: Accept `double speedKmh` parameter (alongside existing `pace`/`baseTravel`). Compute per-pair travel gaps from `rawSlots[i-1].attraction` / `rawSlots[i].attraction`.

**Contract**:
- Add `double speedKmh = kDefaultSpeedKmh` named parameter to `reapplyOverrides()` signature (default = walking speed, backward compatible — tests that don't pass it get the safe default)
- Replace `final travel = (baseTravel * config.travelMultiplier).round();` with per-pair: `final travelPair = pairTravelMinutes(i == 0 ? null : rawSlots[i-1].attraction, rawSlots[i].attraction, speedKmh: speedKmh, fallbackMinutes: (baseTravel * config.travelMultiplier).round(), multiplier: config.travelMultiplier);`
- Travel gap: `final travelGap = i == 0 ? null : travelPair;`

#### 4. Update call site in trip_detail_screen

**File**: `lib/screens/trip_detail_screen.dart` (_loadTimeline method)

**Intent**: Pass speed to `reapplyOverrides()`.

**Contract**: Add `speedKmh: speedKmhForContext(parseTravelContext(trip.travelContext))` to the `reapplyOverrides()` call.

#### 5. Timeline tests — coordinate-based travel

**File**: `test/services/timeline_service_test.dart`

**Intent**: The `_attr` helper gets optional `double? latitude, double? longitude` params. New test cases for coordinate-based travel.

**Contract**:
- Update `_attr` helper: add `double? latitude, double? longitude` params (default null)
- New tests:
  - Two attractions with coordinates → travel gap from Haversine + detour
  - First missing coordinates → flat fallback
  - Both missing → flat fallback
  - Same coordinates → 5 min buffer × multiplier
  - Day boundary with coords → first slot on new day has `travelFromPrevMin: null`
  - `reapplyOverrides` with coordinates → gaps survive reorder
  - Invalid coords (lat=95) → flat fallback

### Success Criteria:

#### Automated Verification:

- `flutter test` — all new timeline tests pass, all existing tests pass
- `flutter analyze` passes

#### Manual Verification:

- N/A (pure logic — covered by automated tests)

---

## Phase 4: Map picker UI

### Overview

Add `google_maps_flutter` dependency. Full-screen dialog with Google Map — user taps a location, coordinates flow back to the form. Timeout fallback (if map doesn't load in 5s) prompts to open Google Maps app. Manual coordinate text fields as secondary fallback.

### Changes Required:

#### 1. Add google_maps_flutter dependency

**File**: `pubspec.yaml`

**Intent**: Add Flutter Google Maps SDK for map display.

**Contract**: `google_maps_flutter: ^latest` in `dependencies`. Run `flutter pub get`.

#### 2. API key configuration (local dev)

**File**: `android/app/build.gradle.kts` or `android/app/build.gradle` + `android/app/src/main/AndroidManifest.xml`

**Intent**: Read API key from `local.properties` (gitignored), inject into AndroidManifest.

**Contract**:
- `AndroidManifest.xml`: `<meta-data android:name="com.google.android.geo.API_KEY" android:value="${MAPS_API_KEY}"/>`
- `build.gradle`: read `local.properties` → `manifestPlaceholders["MAPS_API_KEY"]`
- `local.properties` (gitignored, per-developer): `MAPS_API_KEY=YOUR_KEY`

#### 3. Map picker dialog (new widget)

**File**: `lib/screens/map_picker_screen.dart` (new)

**Intent**: Full-screen route with `GoogleMap` widget. Shows a marker at the tapped location. "Confirm" button returns `(lat, lon)` via `Navigator.pop`. Timeout fallback after 5s — shows error + "Open in Google Maps" button that launches `https://www.google.com/maps?q=0,0` via `url_launcher`. User manually copies coordinates from Google Maps and enters them in fallback text fields.

**Contract**:
- `class MapPickerScreen extends StatefulWidget` with `static Future<LatLng?> show(BuildContext context)` convenience method
- GoogleMap with `onTap: (LatLng pos) => setState(() => _position = pos)`
- Marker at `_position` when non-null
- AppBar with "Confirm" action (disabled until position set) + "Cancel"
- Timer for 5s — if map hasn't loaded (`onMapCreated` not called), show fallback UI
- Fallback UI: text explaining the issue + "Open in Google Maps" button → `url_launcher` → user copies coordinates manually → two `TextFormField`s for manual lat/lon entry → "Confirm" returns the manual values

#### 4. Wire map picker into add-attraction dialog

**File**: `lib/screens/trip_detail_screen.dart` (_AddAttractionDialogState)

**Intent**: Replace/expand the "Add location" section. Button "Pick on map" opens `MapPickerScreen`. Coordinates flow back to state variables. Manual text fields shown only as fallback behind the toggle.

**Contract**:
- Add state: `double? _latitude, _longitude;` + `TextEditingController? _latController, _lonController;`
- After Priority dropdown: `SwitchListTile` or `CheckboxListTile` "Add location (optional)" → toggles `_showLocation`
- When expanded: shows current coordinates if set (e.g., "📍 48.8566, 2.3522"), "Pick on map" button, and a "Clear" button
- "Pick on map" → `final pos = await MapPickerScreen.show(context);` → sets `_latitude`, `_longitude`
- `_save()`: pass `latitude: _latitude, longitude: _longitude` to `dao.createAttraction()`

#### 5. Add url_launcher dependency

**File**: `pubspec.yaml`

**Intent**: Used by map picker fallback to open Google Maps app.

**Contract**: `url_launcher: ^latest` in `dependencies`.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles (confirms API key wiring works)
- `flutter test` — all existing tests pass (map picker is UI-only, no service-level impact)

#### Manual Verification:

- Tap "Add location" → full-screen map opens
- Tap on map → pin appears → Confirm → coordinates fill form
- Create trip with attraction that has coords + one without → mixed travel gaps in timeline
- Airplane mode → map picker shows fallback after 5s → "Open in Google Maps" works
- Clear location → coordinates removed, falls back to flat default

---

## Phase 5: CI configuration

### Overview

Wire the Maps API key into GitHub Actions so `flutter build apk --debug` succeeds in CI. Same pattern as `GOOGLE_SERVICES_JSON` — base64-encode the key, store as GitHub Secret, decode in workflow.

### Changes Required:

#### 1. CI workflow — pass MAPS_API_KEY

**File**: `.github/workflows/pr-check.yml`

**Intent**: Write the API key to `local.properties` before building, so the Android build can read it.

**Contract**: Add step before `flutter build`:
```yaml
- name: Configure Maps API key
  run: echo "MAPS_API_KEY=$MAPS_API_KEY" >> android/app/local.properties
  env:
    MAPS_API_KEY: ${{ secrets.MAPS_API_KEY }}
```

#### 2. CI workflow — deploy.yml (if exists)

**File**: `.github/workflows/deploy.yml` (or equivalent)

**Intent**: Same as above for the deploy workflow.

**Contract**: Same step as pr-check.yml.

### Success Criteria:

#### Automated Verification:

- PR check CI passes (confirms key wiring works in CI)

#### Manual Verification:

- PR builds green on GitHub Actions

---

## Testing Strategy

### Unit Tests:

- `geo_utils_test.dart`: Haversine known distances + null/invalid input + detour factor brackets
- `timeline_service_test.dart`: coordinate-based travel gap, missing coords fallback, same-point buffer, day boundary, reapplyOverrides with coords

### Integration Tests:

- N/A — no multi-system interaction beyond what existing `seed_integration_test.dart` covers (schema version updated to 4)

### Manual Testing Steps:

1. Create trip, add attraction with coordinates (via map picker), add second attraction without → timeline shows mixed travel gaps
2. Two attractions with coordinates (e.g., Warsaw → Krakow ~252 km × detour) → realistic travel gap displayed
3. Airplane mode → add attraction → map picker timeout → fallback works
4. Existing trips without coordinates → flat defaults unchanged (regression check)

## Performance Considerations

- `haversineKm()` is O(1) arithmetic — no performance impact
- `detourFactor()` is a simple if-else chain — O(1)
- GoogleMap widget is lazily loaded only when user explicitly opens the picker — no impact on normal timeline browsing
- Per-pair computation replaces a constant lookup — negligible overhead (the loop was already O(n) per day)

## Migration Notes

- Schema migration v3→v4 is fully backward compatible: new columns are nullable, existing rows get NULL → S-04 flat default used as fallback
- No data migration needed — existing trips and attractions are unaffected
- `reapplyOverrides()` signature change: new optional parameter `speedKmh` with default value — backward compatible, all existing callers (including tests) compile unchanged

## References

- Research: `context/changes/location-based-travel/research.md`
- Plan brief: `context/changes/location-based-travel/plan-brief.md`
- S-04 plan: `context/changes/dynamic-travel-time/plan.md`
- S-02 plan: `context/changes/timeline-generation/plan.md`
- GitHub Issue: [#19](https://github.com/kamilbemowski/traveljug/issues/19)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Schema — coordinate columns + migration v3→v4

#### Automated

- [x] 1.1 `dart run build_runner build` succeeds — 4222682
- [x] 1.2 `flutter analyze` passes — 4222682
- [x] 1.3 `flutter test` — all 48 existing tests pass — 4222682

#### Manual

- [x] 1.4 `Attractions` table has `latitude` / `longitude` RealColumns
- [x] 1.5 `schemaVersion = 4` in `app_database.dart`

### Phase 2: Geo computation — Haversine + detour factor

#### Automated

- [x] 2.1 `flutter test test/services/geo_utils_test.dart` — all Haversine + detour tests pass
- [x] 2.2 `flutter analyze` passes

#### Manual

- [x] 2.3 Haversine returns correct distances for known city pairs
- [x] 2.4 Detour factor brackets correct (1.6/1.35/1.2/1.15)

### Phase 3: Timeline integration — per-pair travel time

#### Automated

- [ ] 3.1 `flutter test` — all timeline tests pass (new + existing)
- [ ] 3.2 `flutter analyze` passes

### Phase 4: Map picker UI

#### Automated

- [ ] 4.1 `flutter analyze` passes
- [ ] 4.2 `flutter build apk --debug` compiles

#### Manual

- [ ] 4.3 Full-screen map opens, tap places pin, Confirm fills coords
- [ ] 4.4 Airplane mode → timeout fallback → "Open in Google Maps" works
- [ ] 4.5 Clear location button works
- [ ] 4.6 Mixed attractions (with/without coords) show correct travel gaps

### Phase 5: CI configuration

#### Automated

- [ ] 5.1 PR check CI passes with Maps API key wired
