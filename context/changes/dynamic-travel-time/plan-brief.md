# S-04: Dynamic Travel Time — Plan Brief

> Full plan: `context/changes/dynamic-travel-time/plan.md`

## What & Why

Timeline uzywa sztywnego 30-minutowego czasu przejazdu miedzy atrakcjami — bez sensu dla road tripa (gdzie przejazdy to godziny) i zbyt konserwatywnie dla city tour (gdzie przejazdy to 15-20 min). S-04 dodaje per-trip "Travel context" (City tour / Road trip) ktory podmienia te 30 min na odpowiednia wartosc.

## Starting Point

`kDefaultTravelMinutes = 30` w `pace_config.dart`. `TimelineService.computeTimeline()` uzywa tej stalej pomnozonej przez pace multiplier. Trip nie ma pola travel context. Schema v2.

## Desired End State

Tworzac trip, user wybiera "City tour" (20 min) lub "Road trip" (90 min) obok "Pace". Timeline automatycznie uzywa odpowiedniego czasu przejazdu. Istniejace tripy bez kontekstu działają jak dotychczas (30 min).

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Data model | TravelContext enum + nullable field on Trip | Null = backward compat. Dwie wartości: city, roadTrip. | Plan |
| Values | City: 20 min, Road: 90 min, Default: 30 min | City = szybkie przejazdy miejskie. Road trip = długie odcinki. Default = istniejące zachowanie. | Plan |
| UI | Dropdown on CreateTripScreen | Obok Pace — naturalne miejsce przy tworzeniu tripa. | Plan |
| S-06 | Research slice for GPS-based travel time | Osobny slice na research darmowych narzędzi (Google Distance Matrix, OSRM, OpenRouteService). | User request |

## Scope

**In scope:** TravelContext enum, Trip.travelContext field, schema v2→v3 migration, DAO update, TimelineService parameterization, CreateTripScreen dropdown, unit tests.

**Out of scope:** GPS/distance-based travel time (S-06), per-attraction overrides, custom time input.

## Architecture / Approach

```
TravelContext enum: city (20min), roadTrip (90min), null (30min)
    ↓
Trip.travelContext (nullable text column)
    ↓
travelMinutesForContext(context) → base travel minutes
    ↓
TimelineService: baseTravel * pace.travelMultiplier → effectiveTravel
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Enum + DB | TravelContext enum, Trip field, schema v3, DAOs | Migration order if S-03 also bumps schema |
| 2. TimelineService | Parameterized travel time, unit tests | None — pure function change |
| 3. UI | Dropdown on CreateTripScreen | None — standard Flutter dropdown |

**Prerequisites:** S-02 (timeline-generation) ✅
**Estimated effort:** ~1 sesja — 3 fazy, wszystkie proste zmiany.
