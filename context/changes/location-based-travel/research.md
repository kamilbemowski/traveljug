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
last_updated_note: "Added follow-up research: routing API options (free + commercial) and detour factor analysis for road trip accuracy"
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

## Follow-up Research: Routing API & Detour Factor (2026-08-04)

> Triggered by the question: "Haversine to tylko linia prosta. Czy to rozwiązanie uwzględnia istniejące drogi?" and "zrobmy dalej research z routing api."

### ⭐ Recommendation: Haversine × distance-bracket detour factor for MVP

**Do NOT add a routing API now.** The detour factor approach gives acceptable accuracy for travel planning, preserves the offline-first NFR, and the `pairTravelMinutes()` choke point makes a future routing API swap cheap. Here's why:

---

### 1. Detour factor: what the data says

I measured 26 European driving routes on OSRM (live data, 2026-08-04) and cross-referenced with academic literature. The key finding across every study: **circuity (driving / straight-line) decreases with distance.**

| Distance bracket | Observed circuity | Recommended factor |
|---|---|---|
| &lt;10 km (city) | 1.16–2.03, mean 1.61 | **1.6** |
| 10–50 km (regional) | 1.07–2.11, mean 1.39 | **1.35** |
| 50–200 km (road trip) | 1.12–1.49, mean 1.21 | **1.2** |
| &gt;200 km (long haul) | 1.13–1.19, mean 1.17 | **1.15** |

**Walking (city tour context):** 1.49–1.99, recommend **1.6 factor on top of 5 km/h** (effective ~3.1 km/h true walking pace).

**Critical nuance — the 60 km/h road trip constant already bakes in some detour compensation.** 60 km/h × straight-line ≈ 44–51 km/h effective real speed in 10–200 km bands — a realistic door-to-door European average. Adding a factor on top without adjusting the speed would double-count. **The correct fix:** apply the bracket factor AND raise `kRoadTripSpeedKmh` from 60 → 75 km/h.

**Mountain/water-barrier cases cannot be fixed by any distance-only method:**
- Zakopane → Morskie Oko: straight-line 14 km, drive 28 km (1.96), then **no road access** (8 km hike)
- Interlaken → Zermatt: 2.10, and Zermatt is car-free
- A routing API only partially fixes these; the overstuffing warning + manual reorder is the real safety net

**Literature sources:** Ballou et al. 2002 (Europe inter-city ~1.46), Springer 2026 "Driving the Extra Mile" (Europe 1.15–1.76, median 1.25), Mennicken et al. 2024 (300 European cities, average ~1.34), Giacomin & Levinson 2015 (circuity decreases with distance)

---

### 2. Free routing APIs — assessment

| Provider | Free tier | Self-host RAM (Europe) | Matrix support | Dart package | Verdict for TravelJug |
|---|---|---|---|---|---|
| **OSRM** | Demo-only (~1 rps) | &gt;64 GB ❌ | `/table` (max 10k) | `osrm`, `routing_client_dart` | Best for prototyping; demo not for production; self-host too heavy for Europe |
| **GraphHopper** | 500 cr/day, non-commercial | ~8–16 GB | `/matrix` (credits per pair) | none | Good API, lightest self-host; non-commercial free tier limits prod use |
| **OpenRouteService** | **2,000 req/day + key** (~40 rps) | ~8–16 GB | `/v2/matrix` | **`open_route_service` 1.2.8** ✅ | **Best free hosted option** — real production quota, verified Dart client, nonprofit backing |
| **Valhalla** | Demo-only (~1 rps/user) | **8–16 GB run / 16–32 GB build** | **`/sources_to_targets` — best matrix** | `routing_engine` | **Best self-hosted option** — lowest RAM, Docker, one-shot N×N matrix |

**For TravelJug, if we ever add routing:**
- **Free hosted:** OpenRouteService — 2,000 routes/day, nonprofit (HeiGIT), `open_route_service` Dart package
- **Self-hosted offline:** Valhalla — 8–16 GB RAM per country extract, `/sources_to_targets` matrix in one call
- **Neither is needed for MVP** — detour factor is the right call now

### 3. Commercial routing APIs

**Key finding: MVP scale is free on EVERY provider.** 900–4,500 calls/month (100–500 trips) = 3–45% of the smallest free tier.

| Provider | Free tier/month | Cost/1K extra | European accuracy | Flutter SDK | Best for |
|---|---|---|---|---|---|
| **Mapbox** | **100,000 Directions** | $2.00 | Good cities, weakest rural (OSM-based, over-predicts) | `mapbox_maps_flutter` (display) | **Best overall MVP fit** — largest free tier, simplest GET API |
| **TomTom** | 20,000 Routing + 2,500 Matrix | ~€0.50 | **Best European accuracy** (lowest RMSE, 58% routes ≥95% accurate) | None (REST only) | Accuracy purists |
| **HERE** | 1,000/day (~30K/mo) | Quote-based | Very strong — European company, best attribute coverage | **Official HERE SDK for Flutter** with **offline routing** | **Offline routing** — only provider with offline Flutter SDK |
| **Google** | 10,000 (Routes API Essentials) | $5.00 | Excellent — top-tier global data | `google_maps_flutter` (display only) | Ecosystem default (but classic API closed to new projects since March 2025) |

**Note:** Google closed its legacy Distance Matrix API to new projects on March 1, 2025. New apps must use the Routes API with different pricing and POST+FieldMask format.

**Verdict:** If we ever add a routing API, **Mapbox** is the pragmatic pick (free, simple, Flutter SDK). **HERE** wins if offline routing becomes a hard requirement. But for S-06 MVP, the detour factor approach (Section 1 above) is the right call.

---

## Final Decisions (2026-08-04)

All open questions resolved. S-06 spec locked:

| # | Decision | Rationale |
|---|---|---|
| **1** | Walking speed: 5 km/h × detour 1.6 = effective ~3.1 km/h. Accepted. | Realistic city walking pace with stops. 5-min buffer floor handles sub-km noise. |
| **2** | Coordinate input: **Google Maps Flutter map picker.** User taps on embedded map → coordinates auto-populate. Manual text fields as fallback behind "Add location (optional)" toggle. | $0 cost (Maps SDK unlimited free since March 2025). Better UX than manual entry. API key configured in AndroidManifest.xml. No geocoding — picker is tap-only for MVP. |
| **3** | Hints: **No longer needed** — map picker fills coordinates automatically. Manual fallback fields retain basic labels (Latitude / Longitude). The map itself is the UX. | Picker UI makes hints redundant. |
| **4** | Road trip speed: **75 km/h base + distance-bracket detour factor.** Factors: <10 km ×1.6, 10-50 km ×1.35, 50-200 km ×1.2, >200 km ×1.15. Effective speeds: 47→56→63→65 km/h as distance increases. | Matches real-world driving: short=local roads/lower effective speed, long=motorways/higher effective speed. |
| **5** | Detour factor approach accepted. No routing API for MVP. `pairTravelMinutes()` choke point makes future API swap cheap (ORS or Mapbox). | Offline-first NFR preserved. Routing API deferred to post-MVP. |

### S-06 final spec summary

| Layer | Implementation |
|---|---|
| **Coordinates** | Google Maps Flutter map picker (tap → lat/lon). `google_maps_flutter` package, Maps SDK key in AndroidManifest. |
| **Distance** | Haversine formula in `lib/services/geo_utils.dart` (pure `dart:math`, zero deps) |
| **Detour** | `pairTravelMinutes()` applies distance-bracket factor before speed conversion |
| **Road trip speed** | 75 km/h base × detour factor — effective 47–65 km/h depending on distance |
| **City/walking speed** | 5 km/h × 1.6 detour = effective ~3.1 km/h |
| **Buffer floor** | 5 min minimum between stops with coordinates (pre-multiplier) |
| **Fallback** | Missing coordinates → S-04 flat default (travelMinutesForContext) |
| **Schema** | `Attractions.latitude` / `longitude` — `real().nullable()`, migration v3→v4 |
| **UI** | Map picker in `_AddAttractionDialog` behind "Add location (optional)" toggle |
| **Timeline** | Per-pair in `computeTimeline()` + `reapplyOverrides()` |

### New dependencies

- `google_maps_flutter` — official Flutter Maps SDK (display only, $0)
- Google Cloud project with Maps SDK enabled (API key in `AndroidManifest.xml`)
