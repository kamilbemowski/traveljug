---
change_id: dynamic-travel-time
title: "Dynamic travel time per trip context"
status: impl_reviewed
roadmap_ref: S-04
created: 2026-07-27
updated: 2026-08-04
---

# Dynamic Travel Time

Slice S-04 from `context/foundation/roadmap.md`. Replaces the hardcoded 30-minute travel time with a per-trip `TravelContext` enum (city tour / road trip). Each context maps to a different base travel time used by the timeline engine.

**Outcome:** User selects city tour or road trip when creating a trip, and the timeline uses an appropriate travel time instead of the flat 30-minute default.
