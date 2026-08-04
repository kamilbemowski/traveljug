# S-06: Location-Based Travel Time — Plan Brief

> Full plan: `context/changes/location-based-travel/plan.md`
> Research: `context/changes/location-based-travel/research.md`

## What & Why

Zastępujemy sztywny flat default czasu przejazdu realnymi odległościami między atrakcjami. User opcjonalnie klika lokalizację na mapie Google dla każdej atrakcji. Timeline liczy dystans Haversine, aplikuje distance-bracket detour factor, konwertuje na minuty przez prędkość (walking 5 km/h × 1.6, driving 75 km/h × factor), i spada do S-04 flat default gdy współrzędnych brak. PRD §Business Logic: "travel time between consecutive stops — derived from location distance, or a flat default."

## Starting Point

S-04 dostarcza `TravelContext` (city/roadTrip) i `travelMinutesForContext()` (20/90/30 min). S-06 dodaje na to warstwę: gdy atrakcje mają współrzędne, realny dystans zastępuje bazową wartość minutażu per para. `Attractions` nie ma kolumn lat/lon. `TimelineService.computeTimeline()` używa jednego `effectiveTravel` dla wszystkich par atrakcji.

## Desired End State

User klika "Add location (optional)" → pełnoekranowa mapa Google → tap na miejsce → współrzędne auto-wypełnione. Timeline między dwiema atrakcjami z koordynatami pokazuje realistyczny czas przejazdu (Haversine × detour × prędkość) zamiast sztywnego defaultu. Atrakcje bez współrzędnych spadają do S-04 flat default. Działa offline z timeout fallbackiem (5s → prompt do Google Maps app).

## Key Decisions Made

| Decision | Choice | Why | Source |
|---|---|---|---|
| Dystans | Haversine (dart:math, zero paczek) | Offline-first, 12 linii kodu, ~0.5% error vs WGS-84 | Research |
| Detour factor | Distance-bracket: <10 km ×1.6, 10-50 ×1.35, 50-200 ×1.2, >200 ×1.15 | Dane empiryczne z 26 europejskich tras OSRM + literatura | Research |
| Road trip speed | 75 km/h (podniesione z 60) + detour factor | 60 km/h już kompensowało detour implicite — podnosimy jawnie | Research |
| Walking speed | 5 km/h × 1.6 = efektywne ~3.1 km/h | Realistyczne tempo z przystankami; 5-min buffer na sub-km szum | Research |
| Map picker | Google Maps Flutter, pełnoekranowy dialog | $0 (Maps SDK unlimited free), lepszy UX niż OSM | Plan |
| API key | AndroidManifest placeholder + local.properties, GH Secrets dla CI | Pattern GOOGLE_SERVICES_JSON już istnieje | Plan |
| Fallback | Timeout 5s → prompt do Google Maps app | User zawsze może dostać współrzędne | Plan |
| Routing API | NIE na MVP | Detour factor wystarcza; `pairTravelMinutes()` choke point pozwala swap w przyszłości | Research |

## Scope

**In scope:** Attractions.latitude/longitude (real, nullable), schema v3→v4, Haversine + detour w geo_utils.dart, speed constants w pace_config.dart, pairTravelMinutes() w TimelineService, per-pair w computeTimeline + reapplyOverrides, google_maps_flutter, pełnoekranowy map picker, timeout fallback, CI wiring

**Out of scope:** Geocoding API, routing API, iOS konfiguracja, reverse geocoding, GPS auto-location, per-attraction travel time override

## Architecture / Approach

```
User taps "Pick on map"
  → MapPickerScreen (full-screen GoogleMap)
    → LatLng returned
      → _latitude, _longitude stored
        → createAttraction(latitude:, longitude:)
          → DB stores nullable REALs

Timeline computation:
  for each consecutive pair (prevAttr, attr):
    haversineKm(prev, attr) → straight-line km
    detourFactor(km) → bracket multiplier
    × speed (5 or 75 km/h) → minutes
    × pace multiplier (0.7 or 1.5) → final travel gap
    fallback: travelMinutesForContext(context) if any coord missing
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Schema | lat/lon RealColumns, migration v4, DAO update | Migration order (v3→v4 additive, no risk) |
| 2. Geo | Haversine + detour + speed constants, unit-tested | Precision edge cases (antipodes, same-point) |
| 3. Timeline | Per-pair travel time in computeTimeline + reapplyOverrides | reapplyOverrides regression (must pass speedKmh) |
| 4. UI | google_maps_flutter dependency, map picker dialog, fallback | API key wiring in AndroidManifest |
| 5. CI | GH Secrets for Maps API key in workflows | Must not break existing PR checks |

**Prerequisites:** S-04 (dynamic-travel-time) ✅, Google Cloud project with Maps SDK enabled
**Estimated effort:** ~2-3 sesje, 5 faz

## Open Risks & Assumptions

- Google Cloud project musi mieć włączony Maps SDK for Android — wymaga konta Google i podpięcia billing (ale $0 przy unlimited free tier)
- iOS nie jest w scope tego slica — Android-only
- url_launcher do otwierania Google Maps app może potrzebować dodatkowej konfiguracji na iOS (poza scope)

## Success Criteria (Summary)

- User może dodać współrzędne przez tap na mapie Google
- Timeline pokazuje realistyczny czas przejazdu gdy obie atrakcje mają współrzędne
- Atrakcje bez współrzędnych spadają do S-04 flat default (backward compatible)
- CI przechodzi z nowym Maps API key
