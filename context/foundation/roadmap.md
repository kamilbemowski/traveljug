---
project: travelapp
version: 1
status: draft
created: 2026-07-09
updated: 2026-07-09
prd_version: 1
main_goal: speed
top_blocker: time
---

# Roadmap: travelapp

> Derived from `context/foundation/prd.md` (v1) + auto-researched codebase baseline.
> Edit-in-place; archive when superseded.
> Slices below are listed in dependency order. The "At a glance" table is the index.

## Vision recap

Solo leisure travelers juggle scattered notes, tabs, and memory to plan a trip. Existing travel apps are rigid itinerary containers — they store a schedule but don't help shape one. The product wedge — the one trait that, if removed, makes the app indistinguishable from a generic to-do list — is the time-math engine: it fills in a day-by-day timeline accounting for visit durations, travel between stops, sleep/wake windows, and flags impossible schedules before they become a problem. The app is a planning companion, not a booking tool.

## North star

**S-02: Timeline generation + overstuffing warnings** — this is the validation milestone: the smallest end-to-end slice that proves the core product hypothesis (that a travel planner with time math is more valuable than a list app). Placed as early as Prerequisites allow because everything else only matters if the timeline engine works.

> "North star" / gwiazda przewodnia — pierwszy, najmniejszy kawałek produktu, którego dostarczenie dowodzi, że główna hipoteza PRD jest prawdziwa. Umieszczony najwcześniej jak pozwalają zależności.

## At a glance

| ID    | Change ID                   | Outcome (user can …)                                    | Prerequisites    | PRD refs                          | Status   |
| ----- | --------------------------- | ------------------------------------------------------- | ---------------- | --------------------------------- | -------- |
| F-01  | data-schema                 | (foundation) minimal data contract: Trip i Attraction entities + basic CRUD wired | —                | NFR: No data loss, NFR: Offline core | ready    |
| F-02  | observability-baseline      | (foundation) Crashlytics wired; all uncaught errors reported to Firebase | —                | —                                 | ready    |
| F-03  | ci-cd-pipeline              | (foundation) GitHub Actions builds APK on push to main, distributes to Firebase App Distribution | —                | NFR: Android 10+                  | ready    |
| S-01  | create-trip-and-attractions | create a trip, see it in the trip list, and add attractions with name, category, duration, and priority | F-01             | FR-001, FR-002, FR-003, FR-006    | proposed |
| S-02  | timeline-generation         | see a day-by-day plan with computed times, travel gaps, priority highlights, and overstuffing warnings | S-01, F-01       | FR-004, FR-005, US-01             | proposed |
| S-03  | manual-plan-adjustments     | reorder, remove, and add items in the plan; manual edits survive timeline recalculation | S-02             | FR-008                            | proposed |
| S-04  | dynamic-travel-time         | set travel context per trip (city tour / road trip) and see accurate travel times instead of a flat 30 min default | S-03             | FR-004                            | proposed |
| S-05  | timeline-ux-polish          | see day intensity indicator (low/medium/high), force-overstuff a day to keep attractions together, and get soft warnings for near-full days | S-02             | FR-005                            | proposed |
| S-06  | location-based-travel       | optionally set coordinates per attraction and see travel times computed from actual distances instead of flat defaults | S-04             | PRD §Business Logic               | planned  |
| S-07  | edit-delete-everything      | edit and delete every entity in the app — trips, attractions, overrides — from any view where they appear | S-03             | FR-001, FR-003, FR-008            | proposed |
| S-08  | map-search                  | search for places by name on the map (geocoding) when picking attraction locations instead of only tap-to-place | S-06             | S-06 extension                    | proposed |
| S-09  | android-auto                | Android Auto integration — view today's plan, navigate to next attraction, mark attractions as visited from car dashboard | S-02             | NFR: Android 10+                  | proposed |
| S-10  | gps-notification            | GPS-based geofencing notifications — alert when approaching a saved attraction during travel | S-06             | S-06 extension                    | proposed |
| S-11  | openrouter-ai-suggestions   | AI-powered attraction and itinerary suggestions via OpenRouter API — get personalized recommendations based on trip context, pace, and existing attractions | S-02, S-04       | Future PRD extension              | proposed |

## Streams

Navigation aid — groups items that share a Prerequisites chain. Canonical ordering still lives in the dependency graph below.

| Stream | Theme              | Chain                          | Note                                                      |
| ------ | ------------------ | ------------------------------ | --------------------------------------------------------- |
| A      | Plan trajectory    | `F-01` → `S-01` → `S-02` → `S-03` → `S-04` → `S-05` → `S-06` | Główna ścieżka MVP — dane → core → polish → realne czasy przejazdu. |
| B      | Infrastructure     | `F-02`, `F-03`                 | Fundamenty infrastrukturalne. |
| C      | Post-MVP features  | `S-07` → `S-08`, `S-10` → `S-11`, `S-09` | Edycja/delete, map search, geofencing, AI, Android Auto — luźno powiązane, można równolegle. |
| B      | Infrastructure     | `F-02`, `F-03`                 | Fundamenty infrastrukturalne — niezależne od siebie i od Stream A. Można robić równolegle z F-01. |

## Baseline

What's already in place in the codebase as of 2026-07-09 (auto-researched + user-confirmed).
Foundations below assume these are present and do NOT re-scaffold them.

- **Frontend:** present — Flutter scaffold, `lib/main.dart` z MaterialApp, `pubspec.yaml` z deps
- **Backend / API:** absent by design — local-first mobile app, no server (per PRD)
- **Data:** absent — no sqflite/drift/hive in pubspec, no models, no schema, no repositories
- **Auth:** absent by design — local profile only, no login (per PRD)
- **Deploy / infra:** partial — `google-services.json` + Firebase Gradle plugin ✅, `firebase-tools` CLI ✅, GitHub Actions workflow ❌
- **Observability:** partial — `firebase_crashlytics` in pubspec but not imported or initialized in `lib/main.dart`

## Foundations

### F-01: Data schema & persistence

- **Outcome:** (foundation) Trip and Attraction data entities defined; minimal persistence layer wired (on-device SQLite) with basic CRUD operations for both entities.
- **Change ID:** data-schema
- **PRD refs:** NFR: No data loss, NFR: Offline core
- **Unlocks:** S-01 (create trip and attractions), S-02 (timeline reads trip + attraction data)
- **Prerequisites:** —
- **Parallel with:** F-02, F-03
- **Blockers:** —
- **Unknowns:** Which persistence library (sqflite vs drift vs hive)? — Owner: dev. Block: no (decision made in `/10x-plan`).
- **Risk:** Foundation is minimal — entity definitions + basic CRUD. Risk of over-engineering: building a full repository layer before any slice exercises it. Keep it to the contract the first slice needs.
- **Status:** ready

### F-02: Observability baseline

- **Outcome:** (foundation) Firebase Crashlytics initialized in `main.dart`; all uncaught Flutter errors and async errors forwarded to Crashlytics console.
- **Change ID:** observability-baseline
- **PRD refs:** —
- **Unlocks:** verification path for all slices (crash visibility during development and testing); enables the "no silent failures" implicit NFR
- **Prerequisites:** —
- **Parallel with:** F-01, F-03
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Minimal — 5 lines of code. Risk is forgetting to wire the `PlatformDispatcher` error handler alongside `FlutterError.onError`, leaving async errors uncaught.
- **Status:** ready

### F-03: CI/CD pipeline

- **Outcome:** (foundation) GitHub Actions workflow triggers on push to main: builds debug APK, uploads to Firebase App Distribution with release notes from the commit message.
- **Change ID:** ci-cd-pipeline
- **PRD refs:** NFR: Android 10+
- **Unlocks:** deployment path for all slices (every slice's APK reaches testers without manual steps)
- **Prerequisites:** Firebase project must exist + service account JSON available as GitHub Secret
- **Parallel with:** F-01, F-02
- **Blockers:** —
- **Unknowns:**
  - Keystore for release signing — Owner: dev. Block: no (debug APK with debug keystore works for Firebase App Distribution MVP distribution).
- **Risk:** `firebase_app_distribution_android` plugin has a known compileSdk=30 bug requiring a manual patch in pub cache. If `flutter pub get` resets the patch, CI builds break silently. Mitigation: document the patch in the workflow or in AGENTS.md.
- **Status:** ready

## Slices

### S-01: Create trip and add attractions

- **Outcome:** user can create a trip (name, destination, optional date range, travel pace), see all trips sorted by date, and add attractions to a trip with name, category, estimated visit duration, and three-tier priority.
- **Change ID:** create-trip-and-attractions
- **PRD refs:** FR-001, FR-002, FR-003, FR-006
- **Prerequisites:** F-01 (data schema)
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - Exact three-tier priority labels (high/medium/low vs must-have/nice-to-have/optional) — Owner: user. Block: no (use placeholders; confirm before S-02 where priority affects timeline display).
- **Risk:** This is the setup slice — without it, the timeline has no data. Sequenced first because every downstream slice depends on trips and attractions existing. The risk is building too much CRUD UI before proving the core hypothesis (S-02); scope-discipline: only the fields S-02 needs.
- **Status:** proposed

### S-02: Timeline generation with overstuffing warnings

- **Outcome:** user opens a trip and sees a day-by-day plan: attractions placed on the correct day with computed start times, travel gaps between stops shown, must-have priority items highlighted. Days where total time exceeds the waking window show a visible overstuffing warning.
- **Change ID:** timeline-generation
- **PRD refs:** FR-004, FR-005, US-01
- **Prerequisites:** S-01 (trips + attractions exist), F-01 (data schema)
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - Travel time estimation: distance-based (requires location data per attraction) or flat default? — Owner: dev. Block: no (PRD says "derived from location distance, or a flat default if location data is unavailable" — start with flat default, add location-based in S-03 or later).
  - Default travel time between stops when location data unavailable — Owner: dev. Block: no (use a sensible constant, e.g., 30 min transit between stops).
- **Risk:** This IS the core business logic and the north star. If the time-math engine produces nonsensical plans (attraction overflow into negative time, wrong day splits), the entire product hypothesis fails. Mitigation: the PRD's Business Logic section is detailed — implement the algorithm exactly as specified, with unit tests for edge cases (single attraction, many attractions on one day, exact boundary at waking-hours limit).
- **Status:** proposed

### S-03: Manual plan adjustments

- **Outcome:** user can manually reorder attractions within a day, move an attraction to a different day, remove an attraction from the plan, or add a new attraction directly to the plan. Any manual edit survives timeline recalculation — the app preserves user changes unless the user explicitly resets.
- **Change ID:** manual-plan-adjustments
- **PRD refs:** FR-008
- **Prerequisites:** S-02 (timeline must exist to adjust)
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - How to represent "manual edit" in the data model — Owner: dev. Block: no (design decision for `/10x-plan`; likely a flag or position override on the attraction-trip join).
- **Risk:** "Manual edits survive recalculation" is the trickiest correctness guarantee in the roadmap. If the recalculation engine (S-02) and the adjustment layer (S-03) have conflicting views of ordering, the plan silently corrupts. Mitigation: define the edit-preservation contract before coding — which fields are user-owned vs engine-owned.
- **Status:** proposed

### S-04: Dynamic travel time

- **Outcome:** user can set a travel context per trip (city tour or road trip), and the timeline reflects accurate travel times between stops instead of a flat 30-minute default.
- **Change ID:** dynamic-travel-time
- **PRD refs:** FR-004
- **Prerequisites:** S-03 (manual adjustments exist, so travel time changes don't conflict with user edits)
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - How to model "travel context" — a new field on Trip, or a per-trip setting? — Owner: dev. Block: no (design decision for `/10x-plan`).
  - What values for each context (city: 15-20 min, road trip: 60-90 min)? — Owner: dev. Block: no (research during `/10x-plan`).
- **Risk:** Low. This replaces a hardcoded constant with a configurable value. The algorithm in S-02 is designed to accept a travel-time parameter, so the change is additive — not a rewrite.
- **Status:** proposed

### S-05: Timeline UX polish — intensity indicator + force overstuff

- **Outcome:** user sees a day intensity indicator (low/medium/high based on % of waking budget used), can force-overstuff a day to keep attractions together on the same day, and sees soft warnings when a day is near capacity.
- **Change ID:** timeline-ux-polish
- **PRD refs:** FR-005
- **Prerequisites:** S-02 (timeline must exist to polish)
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - Intensity formula: what thresholds for low/medium/high? — Owner: dev. Block: no (design in `/10x-plan`; likely <50% / 50-80% / >80%).
  - Force overstuff state: persisted or UI-only? — Owner: dev. Block: no (start with UI-only toggle; persist if needed).
- **Risk:** Low. Additive changes on top of an already-working timeline. Does not modify the core algorithm.
- **Status:** proposed

### S-06: Location-based travel time estimation

- **Outcome:** user can optionally set coordinates (lat/lon) per attraction, and the timeline computes actual straight-line distances between consecutive stops, converting them to travel minutes based on the trip's travel context (walking pace for city tour, driving pace for road trip). Attractions without coordinates fall back to the flat default — backward compatible.
- **Change ID:** location-based-travel
- **PRD refs:** PRD §Business Logic ("derived from location distance, or a flat default if location data is unavailable")
- **Prerequisites:** S-04 (dynamic-travel-time — provides travel context needed for speed selection)
- **Parallel with:** S-05 (pure UI polish, no dependency conflict)
- **Blockers:** —
- **Unknowns:**
  - Walking vs driving speed constants — Owner: dev. Block: no (use 5 km/h walking, 60 km/h driving as sensible defaults).
  - How users enter coordinates (manual input vs map picker) — Owner: dev. Block: no (start with manual text fields; map picker is a separate UX slice).
- **Risk:** Low. Pure additive — nullable columns, no change to existing behavior. Risk is that entering coordinates manually is tedious and users won't bother; mitigation: make fields optional and keep the flat-default fallback.
- **Status:** planned

### S-07: Edit & Delete Everything

- **Outcome:** user can edit and delete every entity from every view — trip name/destination/dates/pace from trip detail, attraction name/duration/category/priority from the timeline, and individual overrides. Delete confirmation dialogs on all destructive actions. No more "create-only" workflows — full CRUD surface exposed in UI.
- **Change ID:** edit-delete-everything
- **PRD refs:** FR-001, FR-003, FR-008
- **Prerequisites:** S-03 (manual adjustments established the UX patterns for inline edits)
- **Parallel with:** S-08, S-10 (independent UI concerns)
- **Blockers:** —
- **Unknowns:**
  - Edit trip fields inline on trip detail screen or separate edit screen? — Owner: dev. Block: no (design in `/10x-plan`).
  - Override deletion — per-attraction or bulk "reset plan"? — Owner: dev. Block: no.
- **Risk:** Low. DAOs already support full CRUD — this is pure UI wiring. Risk is scope creep: "edit everything" can balloon. Mitigation: define exact set of editable fields per entity before starting.
- **Status:** proposed

### S-08: Map Search (Geocoding)

- **Outcome:** user can search for a place by name ("Luwr, Paryż") in the map picker and get a list of matching locations. Tapping a result moves the map to that location and drops a pin. Falls back gracefully when offline (manual coordinates still available).
- **Change ID:** map-search
- **PRD refs:** S-06 extension
- **Prerequisites:** S-06 (location-based-travel — map picker must exist)
- **Parallel with:** S-07, S-11
- **Blockers:** —
- **Unknowns:**
  - Geocoding provider: Google Geocoding API ($5/1000 after 10K free) vs OSM Nominatim (free, 1 req/s)? — Owner: dev. Block: no (research in `/10x-plan`).
  - Cache geocoding results locally? — Owner: dev. Block: no.
- **Risk:** Medium. Breaks offline-first NFR if not implemented with cache/fallback. API cost at scale (but MVP usage is negligible). Mitigation: cache results in local DB, fall back to manual entry.
- **Status:** proposed

### S-09: Android Auto Integration

- **Outcome:** user connects phone to car, Android Auto displays today's plan on the dashboard. Shows current/next attraction with navigation shortcut, mark-as-visited button, and timeline overview. Read-only while driving — all edits happen on the phone when parked.
- **Change ID:** android-auto
- **PRD refs:** NFR: Android 10+
- **Prerequisites:** S-02 (timeline must exist), S-06 (coordinates needed for navigation)
- **Parallel with:** S-10
- **Blockers:** —
- **Unknowns:**
  - Android Auto app structure — media app template vs custom DHU? — Owner: dev. Block: no (research in `/10x-plan`).
  - Google Play approval for Android Auto category? — Owner: dev. Block: no (submit after implementation).
  - Navigation integration: Google Maps intents or embedded? — Owner: dev. Block: no (intents are simpler for MVP).
- **Risk:** High. Android Auto testing requires car or emulator (DHU). Limited Flutter support — may need platform channel + native Android code. Mitigation: start with DHU emulator, keep scope minimal (read-only plan view + navigation intents).
- **Status:** proposed

### S-10: GPS Geofencing Notifications

- **Outcome:** user optionally enables GPS notifications per trip. When approaching a saved attraction (within configurable radius, default 500m), the phone shows a notification: "You're near [Attraction Name] — [duration] min visit, [category]". User taps notification to open the attraction details in the app.
- **Change ID:** gps-notification
- **PRD refs:** S-06 extension
- **Prerequisites:** S-06 (coordinates needed for geofencing)
- **Parallel with:** S-09
- **Blockers:** —
- **Unknowns:**
  - Background location permissions on Android 10+ — foreground service required? — Owner: dev. Block: no (research in `/10x-plan`).
  - Battery impact of continuous GPS monitoring? — Owner: dev. Block: no (use geofencing API instead of continuous polling).
  - Configurable radius per trip vs global setting? — Owner: dev. Block: no (start with global 500m).
- **Risk:** Medium. Android background location restrictions are strict (Android 10+). Geofencing API (`GeofencingClient`) requires Google Play Services. Mitigation: make feature opt-in per trip, use platform geofencing API (not continuous GPS), test on Android 10+.
- **Status:** proposed

### S-11: OpenRouter AI Suggestions

- **Outcome:** user can request AI-powered attraction suggestions for a trip. The app sends trip context (destination, pace, dates, existing attractions, travel context) to OpenRouter API, which returns personalized recommendations. User can browse suggestions and add selected ones to the trip. Suggestions respect the trip's existing plan — no duplicates, fits within remaining day budget.
- **Change ID:** openrouter-ai-suggestions
- **PRD refs:** Future PRD extension
- **Prerequisites:** S-02 (timeline), S-04 (travel context)
- **Parallel with:** S-08
- **Blockers:** —
- **Unknowns:**
  - OpenRouter model selection — which model for travel recommendations? — Owner: dev. Block: no (research in `/10x-plan`; likely Claude or GPT-4o-mini).
  - Prompt engineering — how to format trip context for the model? — Owner: dev. Block: no (design in `/10x-plan`).
  - Cost — per-request pricing? Cache suggestions per destination? — Owner: dev. Block: no (estimate in `/10x-plan`).
  - Offline fallback? — No. AI suggestions require internet by definition.
- **Risk:** Medium. External API dependency breaks offline-first for this feature. API costs at scale. Quality depends on prompt quality. Mitigation: feature is opt-in, clearly labeled "requires internet", cache results per destination, set budget limit.
- **Status:** proposed

## Backlog Handoff

| Roadmap ID | Change ID                   | Suggested issue title                          | Ready for `/10x-plan` | Notes |
| ---------- | --------------------------- | ---------------------------------------------- | --------------------- | ----- |
| F-01       | data-schema                 | Data schema: Trip + Attraction entities + CRUD | yes                   | Run `/10x-plan data-schema` |
| F-02       | observability-baseline      | Wire Firebase Crashlytics                      | yes                   | Run `/10x-plan observability-baseline` |
| F-03       | ci-cd-pipeline              | GitHub Actions: build APK + Firebase distribute | yes                   | Requires `FIREBASE_SERVICE_ACCOUNT_JSON` secret in repo |
| S-01       | create-trip-and-attractions | Create trip and add attractions                | no                    | Blocked by F-01 |
| S-02       | timeline-generation         | Timeline generation with overstuffing warnings | no                    | Blocked by S-01 |
| S-03       | manual-plan-adjustments     | Manual plan adjustments with edit survival     | no                    | Blocked by S-02 |
| S-04       | dynamic-travel-time         | Dynamic travel time per trip context           | no                    | Blocked by S-03 |
| S-05       | timeline-ux-polish          | Timeline UX polish: intensity + force stuff    | no                    | Blocked by S-02 |
| S-06       | location-based-travel       | Location-based travel time from coordinates    | no                    | Blocked by S-04 |
| S-07       | edit-delete-everything      | Edit and delete all entities from UI           | no                    | Blocked by S-03 |
| S-08       | map-search                  | Geocoding search in map picker                 | no                    | Blocked by S-06 |
| S-09       | android-auto                | Android Auto dashboard integration             | no                    | Blocked by S-02, S-06 |
| S-10       | gps-notification            | GPS geofencing notifications                  | no                    | Blocked by S-06 |
| S-11       | openrouter-ai-suggestions   | AI attraction suggestions via OpenRouter       | no                    | Blocked by S-02, S-04 |

## Open Roadmap Questions

1. **Project name** — the working directory is "travelapp" but the product-facing name has not been chosen. Owner: user. Block: roadmap-wide (affects app display name, package name — currently `pl.bemowski.trekjot` is the Android package but may not be the final product name).
2. **Three-tier priority labels** — what are the exact three levels? (e.g., high/medium/low, or must-have/nice-to-have/optional). Owner: user. Block: S-01 (UI labels), S-02 (priority display in timeline).

## Parked

- **FR-007: Attraction categorization with predefined list + free-text tag** — Why parked: nice-to-have per PRD. Basic category field included in FR-003 (S-01); expanded categorization deferred per speed main_goal.
- **No booking integration** — per PRD §Non-Goals.
- **No social or sharing features** — per PRD §Non-Goals.
- **No cloud sync or multi-device support** — per PRD §Non-Goals.
- **No AI-generated trip plans** — per PRD §Non-Goals.

## Done

(Empty on first generation. `/10x-archive` appends an entry here when a change whose Change ID matches the item is archived.)
