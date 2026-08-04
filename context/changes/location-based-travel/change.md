---
change_id: location-based-travel
title: "Location-based travel time estimation"
status: plan_reviewed
roadmap_ref: S-06
created: 2026-08-04
updated: 2026-08-04
---

## Why

PRD §Business Logic: *"Estimated travel time between consecutive stops (derived from location distance, or a flat default if location data is unavailable)."*

Currently only the flat default exists (`kDefaultTravelMinutes = 30`). Adding location-based estimation makes travel times accurate for the specific trip — a 90 min flat default for road trips is better than 30 min, but still doesn't reflect that the Eiffel Tower is 15 min from the Louvre while Versailles is 45 min away.

## What changes

- Optional `latitude` / `longitude` columns on the `Attractions` table
- Haversine distance calculation between consecutive attractions
- Distance → travel time conversion based on travel context (walking vs driving pace)
- Flat default fallback when coordinates are missing (backward compatible)

## What we're NOT doing

- No geocoding API (user enters coordinates or looks them up manually)
- No Google Maps / Mapbox integration
- No routing or transit modes — straight-line distance only
- No per-attraction travel time override

## Approach decision

**Offline-first, coordinate-based with Haversine formula.**
- Works without internet (matches PRD NFR: Offline core)
- No API costs or rate limits
- Simple: two float columns + one math function
- Meaningful improvement over flat defaults for any trip where attractions have coordinates
