# S-06: Location-Based Travel Time — Plan Brief

## Overview

Replace or augment the flat `kDefaultTravelMinutes` with actual distances between attractions. Each attraction gets optional coordinates; the travel time between consecutive attractions is computed from the straight-line distance and the trip's travel context.

## Current state

- `kDefaultTravelMinutes = 30` in `lib/services/pace_config.dart:4` — used by `TimelineService.computeTimeline()`
- S-04 (dynamic-travel-time) will add `TravelContext` enum with base minutes (City tour=20, Road trip=90) — S-06 builds on top of this
- `Attractions` table has no coordinate columns
- Timeline algorithm accepts `effectiveTravel` as a parameter — swapping the constant for a computed value is a one-line change

## What to build

### Phase 1: Coordinate fields on Attraction
- Add nullable `latitude` / `longitude` (real/float) to `Attractions` table
- Bump schema version, regenerate drift code
- Add optional coordinate fields to `AttractionDao.createAttraction()` and `updateAttraction()`
- Add coordinate text fields to `_AddAttractionDialog` (optional, collapsed by default)

### Phase 2: Haversine distance calculation
- New pure function `haversineKm(lat1, lon1, lat2, lon2)` in a new file (e.g. `lib/services/geo_utils.dart`)
- Unit tests for known city pairs (Paris-London ≈ 343 km, zero distance for same point)

### Phase 3: Wire into timeline
- In `TimelineService.computeTimeline()`, when two consecutive attractions both have coordinates, compute distance and convert to travel minutes using the trip's travel context speed (city ≈ walking 5 km/h, road trip ≈ driving 60 km/h)
- Fall back to flat default when any attraction in the pair lacks coordinates
- Existing behavior unchanged for trips without coordinates

## Risks

| Risk | Mitigation |
|---|---|
| Coordinates are tedious to enter manually | Make fields optional, collapsed behind "Add location (optional)" in dialog. Users who don't care get flat defaults. |
| Straight-line distance ≠ actual travel time | Haversine × multiplier is a reasonable approximation. Full routing is out of scope. |
| Schema migration (v3 → v4) | Nullable columns — backward compatible. Existing attractions get `null` coordinates, fall back to flat defaults. |

## Dependencies

- S-04 (dynamic-travel-time) should be done first — travel context determines the speed used to convert distance → time
- S-02 (timeline engine) — no changes needed, accepts `effectiveTravel` as parameter

## Test strategy

- Unit tests: `haversineKm()` for known distances
- Timeline tests: mixed attractions (with/without coordinates) — verify per-pair fallback
