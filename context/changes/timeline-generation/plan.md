# S-02: Timeline Generation — Implementation Plan

## Overview

Build the timeline computation engine and replace TripDetailScreen's flat attraction list with a day-by-day plan view. Core business logic: greedy-fill algorithm that partitions ordered attractions across trip dates using pace-dependent waking windows, with overstuffing warnings and priority highlights. This is the north star — the product hypothesis lives or dies here.

## Current State Analysis

- `TripDetailScreen` (`lib/screens/trip_detail_screen.dart`) shows a flat `ListView` of attractions with "Add" button. No day grouping, no time computation.
- `TravelPace` enum (`lib/database/tables.dart:14`) has two values but no associated hour/config data.
- `AttractionDao.listAttractionsByTrip()` returns attractions sorted by `position` — ready for timeline input.
- `TripDao.getTripById()` returns trip with `startDate`, `endDate`, `pace` — ready for timeline input.
- No domain layer exists — `lib/` has only `screens/` and `database/`. This plan introduces the first domain code.

## Desired End State

User opens a trip → TripDetailScreen shows a day-by-day timeline:
- Each day: date header, list of attractions with computed start times and travel gaps.
- Intensive pace: 7:00–23:00 (16h/day). Relaxing: 10:00–20:00 (10h/day).
- Travel time: 30 min default per transition (0 min before first attraction of a day).
- Overstuffed days show a warning banner. Must-have attractions (priority=0) are highlighted.
- Empty state (no attractions): "Add attractions to see your plan."

## What We're NOT Doing

- No timeline persistence in DB — computed statelessly each time. S-03 adds persistence.
- No dynamic travel time per trip context — flat `kDefaultTravelMinutes = 30`. S-04 replaces this.
- No manual reordering within the timeline — S-03.
- No meal time surcharge or time-of-day awareness.
- No timeline editing — read-only view.

## Implementation Approach

The timeline is a **pure function**: `computeTimeline(Trip, List<Attraction>) → List<TimelineDay>`. No side effects, no DB writes. A `TimelineService` class in `lib/services/` holds this function. `TripDetailScreen` calls it in `initState` and renders the result. Pace config is a Dart extension on `TravelPace` returning a `PaceConfig` value object.

---

## Phase 1: Pace configuration and TimelineDay model

### Overview

Define the `PaceConfig` value object (wake/sleep hours, waking budget, multipliers) as an extension on `TravelPace`. Define `TimelineDay` and `TimelineSlot` model classes. Constants: `kDefaultTravelMinutes = 30`. No computation yet — just types and configs.

### Changes Required:

#### 1. PaceConfig extension

**File**: `lib/services/pace_config.dart` (new)

**Intent**: Map each `TravelPace` value to concrete hour/budget parameters. Stored as an extension, not in the DB — these are app constants.

**Contract**:
- `PaceConfig` class with: `wakeHour` (int), `sleepHour` (int), `wakingMinutes` (int → computed as `(sleepHour - wakeHour) * 60`), `travelMultiplier` (double), `maxAttractionsPerDay` (int).
- Extension on `TravelPace`: `TravelPace get config` returns:
  - `intensive` → wake=7, sleep=23 (960 min), travelMultiplier=0.7, max=6
  - `relaxing` → wake=10, sleep=20 (600 min), travelMultiplier=1.5, max=3
- Top-level const: `kDefaultTravelMinutes = 30`.

#### 2. TimelineDay and TimelineSlot models

**File**: `lib/models/timeline_day.dart` (new)

**Intent**: Value objects representing the timeline output. `TimelineDay` holds one day's plan; `TimelineSlot` is one attraction with its computed start time.

**Contract**:
- `TimelineSlot`: `attraction` (Attraction), `startMin` (int — minutes from midnight), `travelFromPrevMin` (int?, null for first slot in day).
- `TimelineDay`: `date` (DateTime), `slots` (List<TimelineSlot>), `totalMin` (int), `overstuffed` (bool).
- `startTime` getter on `TimelineSlot`: formats `startMin` as "HH:MM" string.
- `mustHave` getter on `TimelineSlot`: true when `attraction.priority == 0`.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- `lib/services/pace_config.dart` exists with both pace configs
- `lib/models/timeline_day.dart` exists with both model classes

---

## Phase 2: Timeline computation engine

### Overview

Implement `TimelineService.computeTimeline(Trip trip, List<Attraction> attractions)` — the pure-function greedy-fill algorithm from research. Unit-test the algorithm exhaustively before any UI work.

### Changes Required:

#### 1. TimelineService

**File**: `lib/services/timeline_service.dart` (new)

**Intent**: Pure function computing a day-by-day timeline from a trip's attractions. Stateless — recomputes from scratch every call.

**Contract**:
- `static List<TimelineDay> computeTimeline(Trip trip, List<Attraction> attractions)`:
  - If `trip.startDate` or `trip.endDate` is null → throws `StateError('Trip has no dates')` (caller should handle this gracefully in UI).
  - If `attractions` is empty → returns empty list.
  - Gets `PaceConfig` from `trip.pace`, safe-parsed via helper that catches `ArgumentError` and defaults to `TravelPace.intensive` if the stored pace string is invalid (malformed data, future enum value).
  - Generates date range: `startDate` through `endDate` (inclusive).
  - Greedy fill: for each attraction (sorted by `position`):
    - Compute slot cost = `attraction.durationMin + (isFirstInDay ? 0 : effectiveTravelMinutes)` where `effectiveTravelMinutes = (kDefaultTravelMinutes * config.travelMultiplier).round()`.
    - If fits current day: add slot, increment `totalMin`.
    - Else if more days remain: finalize current day, move to next, add slot (no travel cost for first slot of new day).
    - Else (last day): add slot anyway, set `overstuffed = true`.
  - Return list of `TimelineDay` objects.

#### 2. Unit tests

**File**: `test/services/timeline_service_test.dart` (new)

**Intent**: Verify the greedy-fill algorithm exhaustively. No database needed — pure function tests.

**Contract**: Test cases (one per `test()` block):
- **empty attractions** → returns empty list
- **trip without dates** → throws `StateError`
- **single attraction** → one day, one slot, no travel time, no overstuffing
- **two attractions fit in one day** → both in day 1, correct start times
- **three attractions forcing day split** → day 1 gets first 2, day 2 gets third
- **exact boundary** — attraction fills remaining budget exactly → no overstuffing
- **exact boundary + 1** → overstuffing triggered
- **intensive vs relaxing** — same attractions, different pace → relaxing overstuffs earlier
- **travel time counted between slots** — verify `travelFromPrevMin` populated, start times account for travel
- **first slot has no travel time** — `travelFromPrevMin` is null for first slot of each day

### Success Criteria:

#### Automated Verification:

- `flutter test test/services/timeline_service_test.dart` — all tests pass
- `flutter analyze` passes

#### Manual Verification:

- Test output shows ≥ 8 test cases passing

---

## Phase 3: Timeline UI — replace TripDetailScreen flat list

### Overview

Replace the flat `ListView` of attractions in `TripDetailScreen` with a day-by-day timeline view. Each day is a section with a date header, attraction cards with times, travel gaps, and an overstuffing warning where applicable. The timeline computes eagerly on screen load.

### Changes Required:

#### 1. TripDetailScreen rewrite

**File**: `lib/screens/trip_detail_screen.dart`

**Intent**: Replace the flat attraction list with a timeline view. The screen now loads the trip, loads attractions, computes the timeline, and renders day sections.

**Contract**:
- `_loadTimeline()` calls `getDatabase()`, loads trip + attractions, calls `TimelineService.computeTimeline()`.
- Trip without dates → show placeholder: "Add trip dates to see your plan."
- No attractions → show placeholder: "Add attractions to see your plan."
- Timeline rendered as `ListView.builder` where each item is a day section:
  - **Day header**: "Day 1 — 24.7.2026" with total time badge.
  - **Attraction cards** (ListTile or custom card): name, category, duration, computed start time (HH:MM), travel gap from previous (e.g., "30 min travel").
  - **Overstuffing banner**: red/orange banner on the day section if `day.overstuffed` is true, with text "This day is overstuffed" and must-have items highlighted.
- "Add Attraction" button stays — still opens `_AddAttractionDialog`. After adding, recomputes timeline.
- Must-have attractions (priority=0) get a visual indicator (e.g., a star icon or bold text).

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- Open a trip with attractions → see day-by-day plan with times
- Travel gaps shown between consecutive attractions in a day
- Overstuffing warning appears when total time exceeds daily budget
- Must-have items visually highlighted (priority=0)
- Trip without dates shows appropriate placeholder
- Empty attraction list shows appropriate placeholder

---

## Testing Strategy

### Unit Tests:

- TimelineService: empty, single attraction, multi-attraction, day split, exact boundary, overstuffing, pace differences, travel time accounting — ≥8 tests.

### Widget Tests:

- None at S-02 stage. The timeline UI is tested manually. Widget tests for the timeline view can be added when S-03 (manual adjustments) introduces interactivity.

### Manual Testing Steps:

1. Create a trip with 5 attractions, various durations, intensive pace → verify timeline splits correctly.
2. Switch to relaxing pace → verify overstuffing appears earlier (at 10h instead of 16h).
3. Trip without dates → verify placeholder message.
4. Empty trip → verify "Add attractions" message.

## Performance Considerations

- `computeTimeline` runs in O(n) where n = number of attractions. At MVP scale (≤50 attractions), this is instantaneous. No caching needed.
- Timeline is recomputed from scratch on every `_loadTimeline()` call — this is fine for MVP because the screen reloads infrequently.

## References

- Research: `context/changes/timeline-generation/research.md`
- Roadmap: `context/foundation/roadmap.md` — S-02
- PRD: `context/foundation/prd.md` — FR-004, FR-005, US-01, Business Logic
- GitHub Issue: [#5](https://github.com/kamilbemowski/traveljug/issues/5)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Pace configuration and TimelineDay model

#### Automated

- [x] 1.1 `flutter analyze` passes
- [x] 1.2 `flutter build apk --debug` compiles

#### Manual

- [ ] 1.3 `lib/services/pace_config.dart` exists with both pace configs
- [ ] 1.4 `lib/models/timeline_day.dart` exists with both model classes

### Phase 2: Timeline computation engine

#### Automated

- [x] 2.1 `flutter test test/services/timeline_service_test.dart` — all tests pass
- [x] 2.2 `flutter analyze` passes

#### Manual

- [ ] 2.3 Test output shows ≥ 8 test cases passing

### Phase 3: Timeline UI — replace TripDetailScreen flat list

#### Automated

- [x] 3.1 `flutter analyze` passes
- [x] 3.2 `flutter build apk --debug` compiles

#### Manual

- [ ] 3.3 Day-by-day plan visible with times and travel gaps
- [ ] 3.4 Overstuffing warning shown when day exceeds budget
- [ ] 3.5 Must-have items highlighted (priority=0)
- [ ] 3.6 Placeholder shown when trip has no dates
- [ ] 3.7 Placeholder shown when no attractions exist
