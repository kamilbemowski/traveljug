---
project: "TBD"
version: 1
status: draft
created: 2026-06-08
context_type: greenfield
product_type: mobile
target_scale:
  users: small
  qps: "# TODO: target_scale.qps — see Open Questions"
  data_volume: "# TODO: target_scale.data_volume — see Open Questions"
timeline_budget:
  mvp_weeks: 3
  hard_deadline: null
  after_hours_only: true
---

## Vision & Problem Statement

Solo leisure travelers planning a trip are stuck juggling scattered notes, browser tabs, bookmarks, and their own memory to assemble and reference a travel plan. There is no single place that holds all the trip information — attractions, hints, routes, practical notes — and surfaces it when the traveler actually needs it, whether during planning or on the ground.

Existing travel apps are rigid itinerary containers. They expect a fixed schedule and offer no help shaping the plan itself — no discovery, no structure beyond a list of times and places. The traveler does the real work of deciding what matters, collecting useful information, and keeping it all organized. The app that replaces this should be a planning companion first, not a booking tool or a calendar.

## User & Persona

**Primary persona**: A solo leisure traveler — someone planning a road trip, a short city break, or a longer vacation for themselves (possibly with friends or family, but planning alone). They research across multiple sources, collect ideas, and want to assemble the best version of their trip. They need the plan accessible both during planning and in the moment — quick look-up of what's next, where it is, and why they picked it.

## Success Criteria

### Primary

- A traveler can create a trip (name, destination, dates), add attractions, and receive a day-by-day plan that accounts for: time per attraction, sleep/wake-up windows, travel between stops, and a realism check that warns when a day is overstuffed. The traveler can review and adjust the plan.

### Secondary

- Attraction categorization by type (e.g., museum, restaurant, nature, landmark) — the traveler can filter or scan the plan by category.

### Guardrails

- **No data loss**: trip data persists reliably. If the app crashes or the phone restarts, all saved trips, attractions, and plans are intact.
- **Overstuffing always flagged**: if a day's planned activities exceed the available waking hours, the app must warn the user — silently accepting an impossible schedule is a regression.
- **Prioritization visible**: the traveler can mark attractions by priority tier, and the plan reflects the distinction — must-have items are never silently dropped from an overstuffed day.

## User Stories

### US-01: Traveler builds a day-by-day plan from attractions

- **Given** a traveler has created a trip "Rome City Break" for June 10–12 and ordered 5 attractions (Colosseum, Vatican, Trastevere walk, Pantheon, dinner in Testaccio), each with a category and estimated visit time
- **When** the app fills in the timeline
- **Then** the plan is divided across 3 days, with wake-up ~8am and sleep ~11pm, each attraction placed in the user's specified order with travel time between stops accounted for, and a warning displayed if any day exceeds ~13 waking hours

## Functional Requirements

### Trip Management

- FR-001: User can create a trip with name, destination, and optionally a date range. Priority: must-have
  > Socrates: Counter-argument considered: "requiring a date range blocks aspirational/someday planning." Resolution: date range made optional.
- FR-002: User can view a list of all saved trips, sorted by date (upcoming first), with search. Priority: must-have
  > Socrates: Counter-argument considered: "a flat list doesn't scale past ~5 trips." Resolution: sort by date + search added.

### Attractions & Plan Building

- FR-003: User can add an attraction to a trip (name, type/category, estimated visit duration). Priority: must-have
  > Socrates: Counter-argument considered: "requiring the user to estimate duration for every attraction is tedious; provide smart defaults." Resolution: kept user-provided — duration is the core scheduling input and must be accurate.
- FR-004: App fills in a day-by-day timeline based on the user's ordered list of stops — assigning start times, accounting for visit durations, wake-up/sleep windows, and travel between stops. Priority: must-have
  > Socrates: Counter-argument considered: "auto-sequencing without location data or opening hours produces bad plans." Resolution: the user orders the stops; the app fills in times — no automatic reordering.
- FR-005: App flags when a day's plan is overstuffed (exceeds available waking hours). Priority: must-have
  > Socrates: Counter-argument considered: "flagging without suggesting a fix leaves the user stuck." Resolution: kept flag-only for MVP — the user knows their own priorities.

### Organization & Review

- FR-006: User can mark an attraction with a three-tier priority level. Priority: must-have
  > Socrates: Counter-argument considered: "binary must-have/optional is too coarse — travelers have shades of priority." Resolution: expanded to three-tier priority.
- FR-007: User can categorize attractions by type, using a predefined list plus a free-text tag. Priority: nice-to-have
  > Socrates: Counter-argument considered: "hardcoded categories might not match how travelers think (e.g., 'rainy day', 'free entry')." Resolution: predefined list + free-text tag for flexibility.
- FR-008: User can review the full plan, day by day, and manually adjust (reorder, remove, add items). Manual edits survive timeline recalculation. Priority: must-have
  > Socrates: Counter-argument considered: "manual edits could be wiped when the plan recalculates after adding or removing an attraction." Resolution: manual edits must survive recalculation — user changes are preserved unless explicitly reset.

## Non-Functional Requirements

- **Responsive UI**: any user tap produces visible feedback within 200ms. Any operation lasting longer than 2 seconds shows continuous progress.
- **On-device data**: all trip data stays on-device by default. No analytics, no telemetry, no network calls that expose trip content without the user's explicit action.
- **Android 10+**: the app runs on Android 10 (API 29) and above, covering the vast majority of active Android devices.
- **Offline core**: core trip planning (creating a trip, adding attractions, viewing/editing the plan) works fully without a network connection. Online content features are bonus and degrade gracefully when offline.

## Business Logic

The app computes whether a day-by-day trip plan is realistically achievable, given the traveler's ordered stops, estimated visit durations, travel pace preference, and available waking hours — flagging impossible schedules before they become a problem.

**Inputs** (user-facing):
- The traveler's ordered list of attractions with estimated visit durations
- A travel pace preference set at trip creation: intensive (longer days, tighter margins) or relaxing (shorter days, more buffer)
- Default sleep and wake windows, adjusted by the pace preference (e.g., intensive: 7am–11pm / 16h; relaxing: 10am–8pm / 10h)
- Estimated travel time between consecutive stops (derived from location distance, or a flat default if location data is unavailable)

**Output**: A day-by-day timeline with each attraction placed at a computed start time. Days where the sum of visit durations + travel gaps exceeds the waking window are flagged as overstuffed. Flagged days display a warning; must-have items are highlighted so the traveler knows which items to protect when adjusting.

**How the user encounters it**: The traveler creates a trip, sets the pace, orders their attractions, and the app fills in the timeline. Overstuffed days show a visible warning. The traveler can then adjust — reorder, remove optional items, move items to another day, or switch the pace. Manual edits are preserved through recalculation.

## Access Control

Local profile only — no login, no account creation. All trip data lives on-device. Single user, no role separation. MVP does not include cloud sync or multi-device support; those may be added in a future version.

## Non-Goals

- **No booking integration**: the app does not book flights, hotels, or tickets. It may link out to booking sites, but there is no transaction flow, no payment, no reservation management.
- **No social or sharing features**: no sharing plans with friends, no collaborative planning, no public profiles, no export to social media. This is a solo planning tool.
- **No cloud sync or multi-device support**: data stays on a single device. No cloud backup, no sync across phone and tablet, no web access. This may be revisited in a future version.
- **No AI-generated trip plans**: the MVP does not include an AI assistant that generates or suggests attractions or itineraries. The traveler builds the plan manually; the app does the time math.

## Open Questions

1. **Project name** — TBD by user. The working directory is "travelapp" but the product-facing name has not been chosen.
2. **Three-tier priority labels** — what are the exact three levels? (e.g., must-have / nice-to-have / optional, or high / medium / low). TBD by user before implementation.
3. **target_scale.qps** — what is the expected queries-per-second? For a local-only mobile app with no backend, this may be N/A. TBD by user.
4. **target_scale.data_volume** — what is the expected data volume per user? TBD by user.
