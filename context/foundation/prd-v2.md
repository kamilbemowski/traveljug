---
project: TravelJug
version: 2
status: draft
created: 2026-08-05
context_type: brownfield
product_type: mobile
target_scale:
  users: small
timeline_budget:
  delivery_weeks: 3
  hard_deadline: null
  after_hours_only: true
---

# PRD v2: TravelJug Post-MVP

> Generated from `context/foundation/shape-notes.md` (brownfield, 8 FRs, quality: accepted).
> This PRD describes incremental changes to an existing system.
> The original MVP PRD (`prd.md`) describes the baseline product.

## Current System Overview

TravelJug to mobilna aplikacja do planowania podróży (Flutter/Dart, Drift SQLite, offline-first). Obecnie oblicza intensywność planu podróży — timeline z podziałem na dni, travel gaps, overstuffing warnings, intensity indicator. Użytkownik tworzy tripa, dodaje atrakcje, apka wylicza czy plan jest wykonalny. Może też ręcznie zmieniać kolejność i przenosić atrakcje między dniami (override'y).

Aplikacja jest kalkulatorem intensywności, nie pełnym plannerem. Działa offline, wszystkie dane lokalnie, jeden użytkownik. 66 testów, CI (analyze + test), monitoring przez Crashlytics.

Zrealizowane slice'y MVP: F-01 (data schema), F-02 (observability), F-03 (CI/CD), S-01 (trip CRUD), S-02 (timeline generation), S-03 (manual adjustments), S-04 (travel context), S-05 (UX polish), S-06 (location-based travel).

## Problem Statement & Motivation

MVP działa — apka poprawnie wylicza timeline. Ale brakuje funkcji które realnie pomagają zaplanować podróż:

1. **Edycja i usuwanie wszystkiego** — obecnie nie da się edytować ani usunąć wielu encji z poziomu UI, mimo że warstwa danych wspiera pełny CRUD. Użytkownik nie może poprawić błędu w nazwie tripa, zmienić czasu atrakcji, ani usunąć niechcianego tripa bez sięgania do bazy.
2. **Wyszukiwanie nazw na mapie** — map picker (S-06) działa tylko przez tapnięcie na mapie. Nie można wyszukać miejsca po nazwie ("Luwr, Paryż"). Użytkownik musi znać dokładne współrzędne lub ręcznie znaleźć miejsce na mapie.

Pierwsza dostawa (v2): S-07 (edycja + usuwanie) + S-08 (wyszukiwanie na mapie) w ~3 tygodnie after-hours. Kolejne funkcje (AI suggestions, Android Auto, GPS notifications) w następnych dostawach.

Insight: to nie domysły — to experience gaps z używania apki.

## User & Persona

Ta sama persona co MVP: solo leisure traveler planujący własne wyjazdy — city break, road trip, dłuższe wakacje. Jedna osoba, jeden trip na raz, dane lokalnie na urządzeniu. Doświadczenie użytkownika zmienia się: zamiast "stworzyłem tripa i nie mogę go już edytować" → pełna kontrola nad danymi.

## Success Criteria

### Primary

**S-07 (edycja + usuwanie):** Użytkownik może edytować każdą encję z poziomu UI — nazwę, destynację, daty i tempo tripa; nazwę, czas trwania, kategorię i priorytet atrakcji — oraz usunąć dowolny trip, atrakcję lub override z potwierdzeniem.

**S-08 (wyszukiwanie na mapie):** Użytkownik wpisuje nazwę miejsca w map pickerze, dostaje listę pasujących wyników, klika wynik, mapa przesuwa się i stawia pinezkę na wybranej lokalizacji.

### Secondary

- S-07: Edycja atrakcji inline z poziomu timeline (bez otwierania osobnego dialogu).
- S-08: Wyniki wyszukiwania są zapamiętywane lokalnie — przy braku internetu użytkownik może skorzystać z wcześniej wyszukanych miejsc.

### Guardrails

- **No data loss**: wszystkie operacje usuwania mają potwierdzenie. Usunięcie tripa kaskaduje do atrakcji i override'ów (istniejące FK constraints).
- **Offline core zachowany**: wszystkie operacje CRUD działają bez internetu. Tylko wyszukiwanie na mapie wymaga połączenia (z fallbackiem do ręcznego wpisywania współrzędnych).
- **Istniejący timeline engine nietknięty**: algorytm computeTimeline() i reapplyOverrides() nie są modyfikowane.

## User Stories

# TODO: User Stories — see Open Questions

## Scope of Change

### New capabilities

- **S-07-edit-trip**: User can edit trip fields (name, destination, dates, pace, travel context) inline from the trip list. Previously: trip was read-only after creation.
- **S-07-edit-attraction**: User can edit attraction fields (name, duration, category, priority) inline from the timeline. Previously: attraction was read-only after creation.
- **S-07-delete-trip**: User can delete a trip with confirmation. Previously: no delete UI existed (only DAO-level).
- **S-07-delete-attraction**: User can delete an attraction from the timeline with confirmation. Previously: attractions could be removed from plan but not deleted from trip.
- **S-07-reset-overrides**: User can reset manual overrides for a day. Previously: overrides were permanent unless manually undone.
- **S-08-place-search**: User can search for places by name in the map picker. Previously: only tap-to-place was available.
- **S-08-search-result-pin**: User can tap a search result to move the map and drop a pin. New capability.
- **S-08-offline-fallback**: Map search degrades gracefully to manual coordinate entry when offline. Previously: map picker showed timeout fallback with manual entry.

### Modified capabilities

- **MapPickerScreen**: existing full-screen map picker gains a search field and results list. The existing tap-to-place and timeout fallback behaviors are preserved.
- **Trip list screen**: gains inline edit capability for trip fields.
- **Timeline day section**: gains inline edit capability for attraction fields.

### Removed capabilities

None. All existing functionality is preserved.

## Constraints & Compatibility

- **Existing API contracts preserved**: TripDao, AttractionDao, TimelineOverrideDao signatures unchanged. New edit/delete UI calls existing DAO methods. No new DAO methods needed.
- **Schema unchanged**: existing v4 schema supports all CRUD operations. No migration needed.
- **Backward compatible**: all existing tests (66) must continue to pass. Edit/delete UI is additive — does not change existing data flow.
- **Firebase Crashlytics monitoring continues unchanged**.
- **CI pipeline unchanged**: pr-check.yml triggers on PRs to main and develop. deploy.yml distributes to Firebase App Distribution on push.

## Business Logic Changes

No domain logic change for S-07 and S-08. These are UI/infrastructure changes:
- S-07: exposes existing CRUD capabilities in the UI. All business rules (timeline computation, pace config, travel time estimation) are unchanged.
- S-08: adds geocoding lookup — user searches, app finds matching locations. No recommendation logic; the app does not suggest or rank results.

The existing timeline engine rule ("compute whether a day's plan is feasible based on visit durations, travel gaps, and wake/sleep windows") is unchanged. AI-powered suggestions (new domain rule: "app recommends attractions based on trip context") belong to a later delivery (S-11).

## Access Control Changes

No access control changes. Local profile only — no login, no account creation. All data on-device. Same model as MVP.

## Non-Goals

- No AI suggestions in this delivery (S-11 — next slice)
- No Android Auto (S-09)
- No GPS notifications (S-10)
- No changes to timeline computation algorithm
- No new data model entities — existing schema is sufficient
- No authentication changes
- No cloud sync or multi-device support

## Open Questions

1. **User Stories**: Given/When/Then user stories for S-07 and S-08 were not captured during shaping. Are these needed, or are the FRs sufficient for implementation?
2. **Geocoding provider**: S-08 requires a geocoding service. Which provider (Google Geocoding API, OSM Nominatim, other) should be used? This is a downstream decision for `/10x-plan s-08`, not PRD-level.
3. **S-05 manual verification**: items 1.3, 1.4, 2.3, 2.4 were checked off during S-06 review but were never formally verified by the user on device.
