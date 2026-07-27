---
date: 2026-07-23T19:30:00+02:00
researcher: Claude
git_commit: 7e2095e
branch: main
repository: traveljug
topic: "S-02 Timeline generation — data sources, business logic, unknowns, and patterns"
tags: [research, codebase, timeline, s-02, north-star]
status: complete
last_updated: 2026-07-23
last_updated_note: "Added follow-up research for algorithm design: travel time estimation, pace/intensity model, day-splitting, edge cases"
last_updated_by: Claude
---

# Research: S-02 Timeline Generation

**Date**: 2026-07-23
**Researcher**: Claude
**Git Commit**: 7e2095e
**Branch**: main
**Repository**: traveljug

## Research Question

What data, business logic, existing patterns, and unknowns does S-02 (timeline generation with overstuffing warnings) need to account for before planning begins?

## Summary

S-02 is the **north star** — the core product hypothesis. The timeline engine must take a trip's ordered attractions (with durations), the trip's pace preference, and a travel-time constant, and compute a day-by-day plan with start times and overstuffing flags. No timeline data model, computation engine, or pace-to-hours mapping exists yet — all must be built from scratch. The existing screen/data patterns (getDatabase → DAO → setState, Navigator.push, in-memory widget tests) are well-established and should be followed. Three unknowns need resolution before `/10x-plan`: default travel time, day-split algorithm, and pace window precision.

## Detailed Findings

### Data Model — What Exists

**Trips** (`lib/database/tables.dart:20-40`):
- `startDate` (nullable) and `endDate` (nullable) — define the trip's date range. If absent, timeline has no anchor days.
- `pace` — stored as `TravelPace.name` (text, default `'intensive'`). Two values: `intensive`, `relaxing`.
- No per-day override fields — pace applies to the whole trip.

**Attractions** (`lib/database/tables.dart:43-69`):
- `durationMin` (int) — visit duration in minutes. Required per FR-003.
- `priority` (int, 0/1/2, default 1) — 0=must-have, 1=nice-to-have, 2=optional. Labels confirmed in S-01 planning.
- `position` (int) — user-defined ordering within a trip.
- `tripId` (FK → Trips, cascade delete).

**DAOs** (`lib/database/daos/`):
- `AttractionDao.listAttractionsByTrip(tripId)` (line 39) — returns `List<Attraction>` ordered by `position ASC`. This is the primary input to the timeline engine.
- `TripDao.getTripById(id)` (line 32) — loads trip metadata (dates, pace).

### Data Model — What's Missing

1. **No `DayPlan` / `TimelineDay` entity.** The timeline output has no persistence model. Options: (a) compute on-the-fly each time (stateless, simpler), or (b) persist computed timeline entries in a new table (enables manual edits in S-03). The PRD says "manual edits survive recalculation" (FR-008, S-03) which implies persistence, but S-02 is stateless computation — S-03 adds persistence.

2. **No pace-to-hours mapping.** `TravelPace` enum has only two values with no associated hour data. PRD examples: `intensive` → 7am–11pm (16h), `relaxing` → 10am–8pm (10h). Must be defined in code.

3. **No travel-time field or constant.** The PRD says "derived from location distance, or a flat default if location data is unavailable." No location fields exist on Attraction (latitude/longitude were rejected during S-01 planning). Roadmap recommends a flat default, e.g., 30 minutes.

4. **No service/domain layer exists.** `lib/` has only `main.dart`, `screens/`, and `database/`. The timeline computation logic will be the first domain service.

### Business Logic Specification

From PRD §Business Logic (`context/foundation/prd.md:86-98`):

**Algorithm inputs:**
1. Traveler's ordered list of attractions with estimated visit durations
2. Travel pace preference (intensive vs relaxing)
3. Wake/sleep windows from pace (intensive: 7am-11pm/16h; relaxing: 10am-8pm/10h)
4. Travel time between consecutive stops (flat default when no location data)

**Algorithm output:**
- Day-by-day timeline with each attraction at a computed start time
- Sum of visit durations + travel gaps compared against waking window
- Overstuffed days flagged with warning
- Must-have items highlighted so traveler knows what to protect

**One-sentence rule** (PRD line 88): *"The app computes whether a day-by-day trip plan is realistically achievable, given the traveler's ordered stops, estimated visit durations, travel pace preference, and available waking hours — flagging impossible schedules before they become a problem."*

### PRD Inconsistency: Waking Hours

US-01 says "~13 waking hours" while Business Logic gives 16h (intensive) and 10h (relaxing). Resolution: Business Logic is more specific and authoritative. ~13h in US-01 is the approximate midpoint of the two pace examples and should be treated as illustrative, not canonical.

### Algorithm Design — Day Splitting

The PRD does not specify the exact day-split algorithm. Three approaches:

| Approach | How it works | Tradeoff |
|---|---|---|
| **A: Greedy fill** | Fill day until next attraction would overflow, split. Repeat. | Simple. May leave large gaps at end of days. |
| **B: Balanced distribution** | Compute total time needed, distribute evenly across available days. | Better UX. More complex. |
| **C: Hybrid** | Greedy fill, but if only 1 attraction overflows a day, push it to next and mark as warning. | Good balance. |

**Recommendation: Approach A (greedy fill).** Matches the PRD "user ordenuje stops, app fills in times" pattern. US-01 example (5 attractions across 3 days) is naturally handled by greedy fill. Overstuffing detection catches imbalanced days — the user adjusts.

### Screen/Pattern Conventions

Established patterns that S-02 must follow:

| Pattern | File evidence |
|---|---|
| `getDatabase()` → DAO → `setState()` | `trip_list_screen.dart:25-34`, `trip_detail_screen.dart:26-34` |
| `StatefulWidget` with `initState` → `_load*()` | All screens |
| `if (!mounted) return` guard before `setState` | `trip_list_screen.dart:29`, `trip_detail_screen.dart:30` |
| `Navigator.push` / `MaterialPageRoute` | `trip_list_screen.dart:62-68` |
| Trip passed as constructor parameter | `TripDetailScreen({required this.trip})` |
| Widget tests: `setTestDatabase` / `NativeDatabase.memory()` | `test/screens/trip_list_screen_test.dart:12-17` |

### Test Patterns

Widget tests use `setTestDatabase()` (injected from `app_database.dart:41-42`) with `NativeDatabase.memory()`. Data seeded via DAOs before pumping widgets. No mocking frameworks — real drift in-memory SQLite.

### Unknowns Requiring Resolution

| # | Unknown | Impact | Recommendation |
|---|---|---|---|
| 1 | Default travel time between stops | Medium — affects every day transition | 30 minutes (per roadmap) |
| 2 | Day-split algorithm (greedy vs balanced) | High — core algorithm shape | Greedy fill (Approach A) |
| 3 | Pace window precision | Low — PRD examples are clear | `intensive`: 7:00-23:00 (16h), `relaxing`: 10:00-20:00 (10h) |
| 4 | Timeline persistence (stateless vs DB table) | Medium — affects S-03 integration | Stateless computation in S-02; S-03 adds persistence for manual edits |

## Code References

- `lib/database/tables.dart:13-17` — TravelPace enum (no hour mapping yet)
- `lib/database/tables.dart:20-40` — Trips table (dates, pace)
- `lib/database/tables.dart:43-69` — Attractions table (durationMin, priority, position, tripId FK)
- `lib/database/daos/attraction_dao.dart:39-44` — `listAttractionsByTrip()` — primary data input
- `lib/database/daos/trip_dao.dart:32-35` — `getTripById()` — loads trip metadata
- `lib/database/app_database.dart:34-44` — `getDatabase()` + `setTestDatabase()` for tests
- `lib/screens/trip_detail_screen.dart:26-34` — data loading pattern template
- `lib/screens/trip_list_screen.dart:62-68` — navigation pattern template
- `test/screens/trip_list_screen_test.dart:12-17` — widget test pattern template
- `context/foundation/prd.md:86-98` — Business Logic specification (authoritative)
- `context/foundation/roadmap.md:117-129` — S-02 entry with unknowns and risk

## Architecture Insights

- **No domain layer exists.** `lib/` has only `screens/` and `database/`. S-02 should introduce `lib/services/timeline_service.dart` or `lib/models/timeline_day.dart` — the first domain code in the project.
- **Stateless vs persisted timeline.** For MVP, stateless computation is simpler and sufficient. Each time the user opens the trip detail, the timeline recomputes from scratch. S-03 adds persistence for manual edits.
- **Pace-to-hours mapping** should live as a Dart extension on `TravelPace` or in a separate config constant. Not in a DB table — these are app constants, not user data.
- **Unit tests for the timeline algorithm** are critical. The PRD's Business Logic section is detailed enough to write tests before code: single attraction, exact overflow at waking-hour boundary, empty trip, trip with no dates.

## Historical Context (from prior changes)

- `context/changes/data-schema/plan.md` — F-01 defined the Trip and Attraction schema used by S-02.
- `context/changes/create-trip-and-attractions/plan.md` — S-01 built the screens that feed data into S-02 (pace selection, attraction ordering, priority).

## Open Questions

1. Should the timeline be displayed on the TripDetailScreen (replacing the current flat attraction list) or on a new dedicated screen accessed via a button?
2. Should the timeline computation happen eagerly (when the screen loads) or lazily (when the user taps "View plan")?
3. Default travel time between stops: 30 min confirmed?

## Follow-up Research: Algorithm Design — Travel Time & Intensity Estimation

**Date**: 2026-07-23
**Query**: "jak zbudowac dobry algorytm szacowania czasu i intensywnosci podrozy"

### Algorithm Recommendation: Simplified Greedy Fill for MVP

After reviewing academic models (DailyTRIP interchangeable fill, TUM pace coefficients, VoyaPace vibe mapping), the **recommendation for MVP is a simplified greedy fill**. The academic gold standard (interchangeable balanced fill with geographic seed selection) requires coordinates we don't have. Greedy fill is simpler, correct for the common case (≤5 attractions across ≤3 days), and overstuffing detection catches imbalance.

### Pace Configuration (TravelJug-specific)

```dart
const paceConfigs = {
  TravelPace.intensive: (wake: 7, sleep: 23, wakingHours: 16,
      travelMultiplier: 0.7, maxAttractions: 6),
  TravelPace.relaxing: (wake: 10, sleep: 20, wakingHours: 10,
      travelMultiplier: 1.5, maxAttractions: 3),
};
```

**Why only 2 paces?** The PRD specifies exactly 2. PRD examples: intensive 7-23/16h, relaxing 10-20/10h. No need to add "moderate."

### Travel Time: Flat Default (30 min)

Given **no location data** (coordinates rejected in S-01), MVP uses a single flat constant. External research confirms category-based time estimation is unreliable without GPS — it produces false precision. Per-transition padding is handled by the pace multiplier (0.7× vs 1.5×).

### Meal Time & Other Enhancements — Deferred

- **Meal surcharge**: skip for MVP — user's `durationMin` is trusted. Add time-of-day meal detection later.
- **Free time buffer**: handled by wakingHours limit, not a separate buffer constant.
- **Max attractions per day**: soft limit; exceeding it triggers overstuffing, not hard rejection.

### Day-Splitting: Simple Greedy Fill

```
function computeTimeline(trip, attractions):
    if no dates: return "Add dates to see plan"
    config = paceConfigs[trip.pace]
    dailyBudget = config.wakingHours * 60
    TRAVEL = (30 * config.travelMultiplier).round()
    
    for each attraction (sorted by position):
        cost = attraction.durationMin + (firstInDay ? 0 : TRAVEL)
        if fits current day: add to day
        else if more days exist: start new day, add attraction
        else: add to current day, mark overstuffed = true
    
    return timeline
```

**No travel time before the first attraction of a day** — the user "starts" at their first stop. Travel time only between consecutive stops within a day.

### Edge Cases

| Case | Handling |
|---|---|
| No dates on trip | Return state "Add trip dates to see plan" |
| Empty attractions | Empty timeline |
| Single attraction | Day 1; overstuff only if duration > dailyBudget |
| Duration exceeds budget | Mark day overstuffed immediately |
| More days than attractions | Later days stay empty |

### Overstuffing Detection

```dart
day.overstuffed = day.totalMin > config.wakingHours * 60;
```

Must-have attractions (priority == 0) are visually highlighted per PRD guardrail: *"must-have items are never silently dropped from an overstuffed day."*
