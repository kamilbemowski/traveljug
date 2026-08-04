---
date: 2026-08-04T18:00:00+02:00
researcher: Claude
git_commit: 5939619
branch: main
repository: traveljug
topic: "S-06: Location-based travel time — Haversine formula, Drift schema, Timeline integration"
tags: [research, s06, geo, haversine, drift, timeline, travel-time]
status: complete
last_updated: 2026-08-04
last_updated_by: Claude
---

# Research: S-06 Location-Based Travel Time

**Date**: 2026-08-04
**Researcher**: Claude
**Git Commit**: 5939619
**Branch**: main
**Repository**: traveljug

## Research Question

How to implement location-based travel time estimation for TravelJug: add optional GPS coordinates to attractions, compute straight-line distance via Haversine, and convert to travel minutes based on the trip's travel context — all offline-first, no external API dependencies.

## Summary

S-06 is feasible with **zero new package dependencies**. The implementation spans 8-9 files:
1. **Schema**: two nullable `real()` columns on `Attractions`, migration v3→v4
2. **Geo**: inline Haversine formula (~12 lines of `dart:math`) in new `lib/services/geo_utils.dart`
3. **Speed model**: 5 km/h (city/walking), 60 km/h (road trip/driving), 5 min buffer floor
4. **Timeline**: per-pair distance→time in `computeTimeline()` + `reapplyOverrides()`, with flat-default fallback
5. **Tests**: 5 test cases for Haversine, 6+ timeline edge cases (coords/no-coords/same-coords/day-boundary)

Key design decisions:
- **`real()` not `text()`** for coordinates — maps to SQLite REAL (IEEE 754 double), enables future range queries
- **`asin` variant of Haversine** is standard Dart practice (no additional `atan2` edge case handling needed for city-scale distances)
- **Multiplier applies after** distance→time conversion and after buffer floor — preserves S-04 pace semantics
- **`reapplyOverrides` must also be updated** — otherwise any user reorder regresses to flat travel time

## Detailed Findings

### 1. Haversine formula implementation

**File**: `lib/services/geo_utils.dart` (new)

Standard Haversine formula using only `dart:math`:
```
a = sin²(Δlat/2) + cos(lat1) * cos(lat2) * sin²(Δlon/2)
d = 2 * R * asin(√a)   where R = 6371 km (IUGG mean radius)
```

**No package needed.** `latlong2` (0.8 MB) is the closest lightweight option but brings `intl` dependency. `geolocator` is heavy — native Android/iOS plugins. For a single 12-line function, `dart:math` is the right call, matching `TimelineService`'s zero-dependency pure-function philosophy.

**Validation**: returns `null` if any coordinate is null or out of range (|lat| > 90, |lon| > 180). This centralizes the fallback decision in one testable function.

**Test cases** (all verified with R = 6371):
| Case | Expected | Computed |
|---|---|---|
| Paris → London (48.8566, 2.3522) → (51.5074, −0.1278) | ≈343 km | 343.6 km |
| Same point | 0 km | 0.0 km |
| Warsaw → Krakow (52.2297, 21.0122) → (50.0647, 19.9450) | ≈252 km | 252.0 km |
| Equator quarter: (0,0) → (0,90) | ≈10007 km | 10007.5 km |

Use `expect(d, closeTo(expected, 1.0))` — 1 km tolerance handles rounding in "expected" values.

**Precision caveat**: Haversine gives straight-line (great-circle) distance, ~0.5% error vs. WGS-84 ellipsoid. Actual driving distance is typically 1.2–1.4× straight-line. The speed constants already compensate for this (walking 5 km/h is deliberately conservative vs. actual walking 5 km/h on straight-line; road-trip 60 km/h is a rough effective speed for mixed roads).

### 2. Drift schema: `real()` columns + migration

**File**: `lib/database/tables.dart`

```dart
// Add to Attractions class (after position, before tripId FK):
/// GPS latitude, nullable per S-06. REAL (IEEE 754 double) in SQLite.
RealColumn get latitude => real().nullable()();
/// GPS longitude, nullable per S-06.
RealColumn get longitude => real().nullable()();
```

`real()` is the correct Drift column builder for GPS coordinates. It maps to SQLite `REAL` (8-byte IEEE 754 double). `double()` is NOT a valid Drift column builder. `text()` would store coordinates as strings, breaking numeric operations.

**Migration v3→v4** (`lib/database/app_database.dart`):
```dart
schemaVersion => 4;
// onUpgrade:
if (from < 4) {
  await m.addColumn(attractions, attractions.latitude);
  await m.addColumn(attractions, attractions.longitude);
}
```

Nullable columns → backward compatible. Existing rows get `NULL` → fallback to flat default.

**DAO** (`lib/database/daos/attraction_dao.dart`):
- `createAttraction()`: add `double? latitude, double? longitude` params → `Value(latitude)/Value(longitude)`
- `updateAttraction()`: add `double? latitude, double? longitude` → `Value.absentIfNull(latitude)` (matches existing partial-update pattern)

### 3. Speed constants

**File**: `lib/services/pace_config.dart`

```dart
const double kCitySpeedKmh = 5.0;      // Walking pace (~12 min/km)
const double kRoadTripSpeedKmh = 60.0;  // Driving pace (~1 min/km)
const double kDefaultSpeedKmh = 5.0;    // Null context → walking (conservative)
const int kMinPairTravelMin = 5;        // Minimum buffer between stops with coords

double speedKmhForContext(TravelContext? context) => switch (context) {
      TravelContext.city => kCitySpeedKmh,
      TravelContext.roadTrip => kRoadTripSpeedKmh,
      null => kDefaultSpeedKmh,
    };
```

**Why null → 5 km/h (walking pace)?** At 5 km/h, 30 min (the flat default) = 2.5 km — a realistic city-center leg. The null-context speed and the null-context flat default stay roughly consistent.

**Why buffer floor (5 min)?** Same-coordinates pair produces 0 km distance. Without the floor, travel time would be 0 min (impossible — even adjacent buildings take time to walk between). The floor applies pre-multiplier so pace still scales: intensive = 4 min, relaxing = 8 min.

### 4. Timeline integration

**File**: `lib/services/timeline_service.dart`

**`computeTimeline()`** change: the loop currently uses a single flat `effectiveTravel` for all pairs. S-06 makes it per-pair by tracking `previousAttr`:

```dart
final speedKmh = speedKmhForContext(parseTravelContext(trip.travelContext));
var previousAttr = attractions.first; // init before loop

for (final attr in attractions) {
  // ... day-boundary logic unchanged ...
  final travelCost = isFirstInDay ? 0 : pairTravelMinutes(
    previousAttr, attr, speedKmh: speedKmh, fallback: flatTravel, multiplier: config.travelMultiplier,
  );
  // ... rest unchanged; use travelCost for travelFromPrevMin ...
  previousAttr = attr;
}
```

`pairTravelMinutes()` — new private helper:
```dart
int pairTravelMinutes(Attraction prev, Attraction current,
    {required double speedKmh, required int fallback, required double multiplier}) {
  final km = haversineKm(prev.latitude, prev.longitude,
                         current.latitude, current.longitude);
  if (km == null) return fallback;  // missing/invalid coords
  final base = (km / speedKmh * 60).round();
  final buffered = base < kMinPairTravelMin ? kMinPairTravelMin : base;
  return (buffered * multiplier).round();
}
```

**`reapplyOverrides()` must also change** — it recomputes travel gaps flat. Add `double speedKmh` parameter (alongside existing `pace`/`baseTravel`), compute per-pair from `rawSlots[i-1].attraction` / `rawSlots[i].attraction`. Caller (`trip_detail_screen.dart:67-71`) passes `speedKmhForContext(...)`.

### 5. UI: coordinate fields in add-attraction dialog

**File**: `lib/screens/trip_detail_screen.dart` (`_AddAttractionDialogState`)

Add state:
- `bool _showLocation = false;`
- `TextEditingController _latController`, `_lonController` (dispose them)
- After Priority dropdown: `CheckboxListTile` or `ExpansionTile` labeled "Add location (optional)"
- When expanded: two `TextFormField`s with `keyboardType: TextInputType.numberWithOptions(decimal: true, signed: true)`
- Validators: `double.tryParse` + range check (−90…90 for lat, −180…180 for lon)
- `_save()`: parse and pass `latitude:`/`longitude:` to `dao.createAttraction()`

### 6. No model changes needed

`TimelineDay`/`TimelineSlot` models are unchanged — `travelFromPrevMin` (nullable, per-slot) already exists and the UI already renders it (`trip_detail_screen.dart:385`). The distance-based time flows transparently through the existing slot structure.

## Code References

| File | Purpose |
|---|---|
| `lib/database/tables.dart:42-79` | `Attractions` table — add `latitude`/`longitude` columns |
| `lib/database/app_database.dart:13-27` | Schema version + migration — bump to 4, add columns |
| `lib/database/daos/attraction_dao.dart:14-30` | `createAttraction()` — add optional coords |
| `lib/database/daos/attraction_dao.dart:47-66` | `updateAttraction()` — add optional coords |
| `lib/services/pace_config.dart:7` | `kDefaultTravelMinutes` — speed constants go here |
| `lib/services/timeline_service.dart:23-27` | `computeTimeline()` travel time setup — replace flat with per-pair |
| `lib/services/timeline_service.dart:147-148` | `reapplyOverrides()` — also needs per-pair |
| `lib/screens/trip_detail_screen.dart:422-481` | `_AddAttractionDialog` — add coordinate fields |
| `lib/services/geo_utils.dart` (new) | Haversine formula |

## Architecture Insights

- **Pure-function pattern**: all new code (Haversine, speed lookup, pair travel time) follows the existing `TimelineService` pattern — stateless, pure functions, no side effects, testable in isolation.
- **Offline-first**: no geocoding API, no Google Maps. Coordinates are manually entered. This matches the PRD NFR "Offline core" and the S-04/S-05 approach of keeping computation local.
- **Fallback chain**: per-pair → Haversine (with validation) → null if missing coords → flat default from S-04. Each layer degrades gracefully.
- **Single threshold source**: multiplier applies in one place (`pairTravelMinutes`), buffer floor in one place, speed lookup in one place.

## Related Research

- `context/changes/dynamic-travel-time/plan.md` — S-04 travel context (prerequisite)
- `context/changes/dynamic-travel-time/reviews/impl-review.md` — S-04 review findings

## Open Questions

1. **Walking speed (5 km/h) confirmation** — 5 km/h is a standard average walking speed. Should we offer "brisk walk" / "leisurely stroll" variants, or is one walking speed enough for MVP?
2. **Coordinate input UX** — manual text entry of lat/lon is workable but tedious. Should we _require_ decimal degrees format or also accept DMS (degrees-minutes-seconds)?
3. **Negative coordinates** — the validator should clearly indicate that south/west coordinates are negative (e.g., Buenos Aires: −34.6, −58.4). Add hint text?
