---
change_id: map-search
title: "Map search with geocoding — find places by name and pin on map"
status: impl_reviewed
roadmap_ref: S-08
created: 2026-08-05
updated: 2026-08-05
---

# Map Search (S-08)

Post-MVP slice from `context/foundation/roadmap.md`. Adds Place autocomplete to the existing map picker — user types a place name, gets autocomplete predictions with names and addresses, taps one to move the map and drop a pin. Returns both coordinates and the place name to the caller.

**Outcome:** User can search for places by name in the map picker and pin results. Falls back to manual coordinate entry when offline.

**Unlocks:** —

## Implementation Status (2026-08-05)

**All code merged to `develop`.** Automated gates pass (74 tests, analyze clean). Manual verification pending — blocked on Android device/emulator availability.

### What was built
- Search bar with 300ms debounce on `MapPickerScreen`
- Autocomplete via `flutter_places_sdk` (native Google Places SDK)
- Predictions overlay with place name + address
- Tap prediction → fetch Place Details → animate map + drop pin
- Session cache (LinkedHashMap, 50 entries, LRU)
- `MapPickerResult` carries both coordinates and place name
- `searchQuery` pre-fill for add/edit attraction flows
- ProGuard rules for release builds
- Error states: no results, missing API key, connection failure, unavailable SDK

### Commits
- `137f2af` feat(map-search): native Places SDK + place names + crash fixes
- `72ec976` fix(build): add ProGuard rules for flutter_places_sdk release build (#30)
