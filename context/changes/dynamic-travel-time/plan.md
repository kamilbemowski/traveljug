# S-04: Dynamic Travel Time — Implementation Plan

## Overview

Replace `kDefaultTravelMinutes = 30` with a per-trip `travelContext` field. The user picks "City tour" (20 min base) or "Road trip" (90 min base) when creating a trip. The timeline engine multiplies this base by the pace multiplier as before. No change to the timeline algorithm or UI.

## Current State Analysis

- `kDefaultTravelMinutes = 30` in `lib/services/pace_config.dart:4` — hardcoded constant used by `TimelineService.computeTimeline()`.
- Trip table has `pace` field but no travel context field.
- `CreateTripScreen` has a `TravelPace` dropdown but no travel context dropdown.
- Schema version is 2 (after S-03). S-04 will be 2 or 3 depending on merge order.

### Key Discoveries:

- `lib/services/timeline_service.dart:42` — `final effectiveTravel = (kDefaultTravelMinutes * config.travelMultiplier).round();` — this is the single line to parameterize.
- `lib/database/tables.dart:20-40` — Trips table where `travelContext` will be added.
- `lib/screens/create_trip_screen.dart` — form where the dropdown will be added.

## Desired End State

When creating a trip, the user sees a "Travel context" dropdown next to "Pace". Options: "City tour" (default, 20 min), "Road trip" (90 min). The timeline uses this value instead of 30 min. Existing trips without a context default to 30 min (backward compatible).

## What We're NOT Doing

- No GPS-based travel time estimation (that's S-06 research).
- No per-attraction travel time overrides.
- No "custom" travel time input (only two presets + default).
- No changes to the timeline UI — it already displays travel gaps.

## Implementation Approach

Add a `TravelContext` enum to `tables.dart`, a nullable `travelContext` field to the `Trips` table, bump schema version, regenerate drift code. Add a `travelContext` parameter to `TripDao.createTrip()` and `updateTrip()`. In `TimelineService`, read the trip's context, map to base minutes, and pass to the computation. Add a dropdown to `CreateTripScreen`.

---

## Phase 1: TravelContext enum + DB field + migration

### Overview

Add enum, table field, regenerate drift, update DAOs. No logic changes yet.

### Changes Required:

#### 1. TravelContext enum

**File**: `lib/database/tables.dart`

**Intent**: New enum with two values mapping to base travel minutes. Null means "use default" (backward compatible).

**Contract**:
- `enum TravelContext { city, roadTrip }`.
- Extension `TravelContextMinutes` on `TravelContext?`: returns `20` (city), `90` (roadTrip), `30` (null/default).

#### 2. Trip table field

**File**: `lib/database/tables.dart` (Trips class)

**Intent**: New nullable column storing the travel context.

**Contract**: `DateTimeColumn get travelContext => text().nullable()()` — stores `TravelContext.name`.

#### 3. Schema migration

**File**: `lib/database/app_database.dart`

**Intent**: Bump schema, add migration from previous version.

**Contract**:
- Bump `schemaVersion` to the next available version (3 if before S-03, 4 if after S-03).
- `onUpgrade` from previous version: `m.addColumn(trips.travelContext)`. Adjust `from` value to match whichever version is current when this slice runs.
- `onCreate` unchanged (already creates all columns).

#### 4. Update DAOs

**File**: `lib/database/daos/trip_dao.dart`

**Intent**: Accept optional `TravelContext?` in create and update.

**Contract**:
- `createTrip()`: add `TravelContext? travelContext` parameter, store in `TripsCompanion.insert()`.
- `updateTrip()`: add `TravelContext? travelContext` parameter, `Value.absentIfNull(travelContext?.name)`.

#### 5. Regenerate drift code

**File**: generated `.g.dart` files

**Contract**: `dart run build_runner build` succeeds.

### Success Criteria:

#### Automated Verification:

- `dart run build_runner build` succeeds
- `flutter analyze` passes
- `flutter test` — existing tests pass (backward compatible — null context = default)

#### Manual Verification:

- `lib/database/tables.dart` has `TravelContext` enum
- `lib/database/app_database.dart` has `schemaVersion = 3`

---

## Phase 2: Use travel context in TimelineService

### Overview

Replace the hardcoded `kDefaultTravelMinutes` constant with a lookup based on the trip's `travelContext` field.

### Changes Required:

#### 1. Parameterize travel time

**File**: `lib/services/pace_config.dart`

**Intent**: Keep `kDefaultTravelMinutes` for backward compat, but add a lookup function.

**Contract**: Add `int travelMinutesForContext(TravelContext? context)` — returns 20 (city), 90 (roadTrip), 30 (null/default).

#### 2. Update computeTimeline

**File**: `lib/services/timeline_service.dart`

**Intent**: Read the trip's travel context and use it instead of the global constant.

**Contract**: Before `final effectiveTravel = ...`, add `final baseTravel = travelMinutesForContext(trip.travelContext);` and use `baseTravel` instead of `kDefaultTravelMinutes` in the multiplier.

#### 3. Update unit tests

**File**: `test/services/timeline_service_test.dart`

**Intent**: Add tests for city and road trip contexts.

**Contract**:
- `test('city context uses 20 min base')` — verify effective travel = `20 * multiplier`.
- `test('road trip context uses 90 min base')` — verify effective travel = `90 * multiplier`.
- `test('null context uses 30 min base')` — backward compatibility.

### Success Criteria:

#### Automated Verification:

- `flutter test` — all tests pass, including new context tests
- `flutter analyze` passes

#### Manual Verification:

- Timeline shows different travel gaps for city vs road trip context

---

## Phase 3: Travel context dropdown in UI

### Overview

Add a "Travel context" dropdown to `CreateTripScreen` next to the "Pace" dropdown. Pass the value through to `TripDao.createTrip()`.

### Changes Required:

#### 1. CreateTripScreen

**File**: `lib/screens/create_trip_screen.dart`

**Intent**: New dropdown for travel context in the trip creation form.

**Contract**:
- Add `TravelContext? _travelContext;` state variable (defaults to null).
- Add `DropdownButtonFormField<TravelContext?>` below the Pace dropdown with items: "Default (30 min)" = null, "City tour (20 min)" = city, "Road trip (90 min)" = roadTrip.
- Pass `_travelContext` to `tripDao.createTrip(travelContext: _travelContext)`.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- Create a trip with "City tour" → timeline uses shorter travel gaps.
- Create a trip with "Road trip" → timeline uses longer travel gaps.
- Existing trips without context still work (30 min default).

---

## Testing Strategy

### Unit Tests:

- `travelMinutesForContext`: verify 20/90/30 for city/roadTrip/null.
- TimelineService: city and road trip context produce different effective travel times.

### Manual Testing Steps:

1. Create trip with "City tour" — verify travel gaps ~14-21 min (intensive) or ~30 min (relaxing).
2. Create trip with "Road trip" — verify travel gaps ~63 min (intensive) or ~135 min (relaxing).
3. Create trip without context — verify default 30 min.

## Performance Considerations

- `travelMinutesForContext()` is a simple switch/map lookup — O(1), negligible overhead.

## References

- Roadmap: `context/foundation/roadmap.md` — S-04
- PRD: `context/foundation/prd.md` — FR-004
- GitHub Issue: [#12](https://github.com/kamilbemowski/traveljug/issues/12)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: TravelContext enum + DB field + migration

#### Automated

- [x] 1.1 `dart run build_runner build` succeeds
- [x] 1.2 `flutter analyze` passes
- [x] 1.3 `flutter test` — existing tests pass (backward compat)

#### Manual

- [x] 1.4 `TravelContext` enum in `tables.dart`
- [x] 1.5 `schemaVersion = 3` in `app_database.dart`

### Phase 2: Use travel context in TimelineService

#### Automated

- [ ] 2.1 `flutter test` — all tests pass with new context tests
- [ ] 2.2 `flutter analyze` passes

#### Manual

- [ ] 2.3 Different travel gaps for city vs road trip

### Phase 3: Travel context dropdown in UI

#### Automated

- [ ] 3.1 `flutter analyze` passes
- [ ] 3.2 `flutter build apk --debug` compiles

#### Manual

- [ ] 3.3 City tour context shows shorter travel gaps in timeline
- [ ] 3.4 Road trip context shows longer travel gaps in timeline
- [ ] 3.5 Existing trips without context default to 30 min
