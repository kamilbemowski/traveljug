---
project: TravelJug
context_type: brownfield
product_type: mobile
target_scale:
  users: small
timeline_budget:
  delivery_weeks: null
  hard_deadline: null
  after_hours_only: true
created: 2026-08-05
updated: 2026-08-05
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  frs_drafted: 8
  quality_check_status: accepted
---

# Shape Notes: TravelJug Post-MVP

## Current System

TravelJug to mobilna aplikacja do planowania podróży (Flutter/Dart, Drift SQLite, offline-first). Obecnie oblicza intensywność planu podróży — timeline z podziałem na dni, travel gaps, overstuffing warnings, intensity indicator. Użytkownik tworzy tripa, dodaje atrakcje, apka wylicza czy plan jest wykonalny. Może też ręcznie zmieniać kolejność i przenosić atrakcje między dniami (override'y).

Aplikacja jest **kalkulatorem intensywności**, nie pełnym plannerem. Działa offline, wszystkie dane lokalnie, jeden użytkownik.

Użytkownicy: solo leisure travelers (ta sama persona co MVP).

## Vision & Problem Statement

MVP działa — apka poprawnie wylicza timeline. Ale brakuje funkcji które realnie **pomagają zaplanować podróż**:

1. **Edycja i usuwanie wszystkiego** — obecnie nie da się edytować/usunąć wielu encji z UI mimo że DAO wspiera pełny CRUD
2. **Wyszukiwanie nazw na mapie** — map picker działa tylko przez tap, nie można wyszukać "Luwr, Paryż"
3. **Android Auto** — dostęp do planu z poziomu deski rozdzielczej samochodu
4. **GPS notifications** — geofencing alerty gdy użytkownik jest blisko zapisanej atrakcji
5. **AI suggestions** — rekomendacje atrakcji przez OpenRouter API na podstawie kontekstu podróży

Change type: nowe moduły (każdy feature jako osobny slice). Rdzeń aplikacji (timeline engine, CRUD, offline-first) pozostaje bez zmian.

Insight: to nie domysły — to experience gaps z używania apki. Użytkownik wie czego brakuje bo sam planuje podróże.

## User & Persona

Ta sama persona co MVP: solo leisure traveler planujący własne wyjazdy — city break, road trip, dłuższe wakacje. Jedna osoba, jeden trip na raz, dane lokalnie na urządzeniu.

## Access Control

Bez zmian — local profile only, no login, no account creation. Wszystkie dane na urządzeniu. AI API użyje klucza OpenRouter per-instancja (nie per-user).

## Success Criteria

### Primary

**S-07 (edycja + usuwanie):** Użytkownik może edytować każdą encję z poziomu UI — nazwę/destynację/daty tripa, nazwę/czas/kategorię atrakcji — oraz usunąć dowolny trip, atrakcję lub override z potwierdzeniem.

**S-08 (wyszukiwanie na mapie):** Użytkownik wpisuje nazwę miejsca w map pickerze → dostaje listę wyników → klika → mapa przesuwa się i stawia pinezkę.

**S-11 (AI suggestions — następny slice):** Użytkownik klika "Suggest attractions" dla tripa → apka wysyła kontekst do OpenRouter → dostaje rekomendacje → może dodać wybrane do planu.

### Secondary

- S-07: Edycja atrakcji inline z poziomu timeline (bez otwierania osobnego dialogu)
- S-08: Cache wyników geocodingu lokalnie (offline fallback)

### Guardrails

- **No data loss**: wszystkie operacje delete muszą mieć potwierdzenie. FK cascade działa jak w MVP.
- **Offline core zachowany**: edycja/dodawanie działa bez internetu. Tylko map search i AI wymagają połączenia.
- **Istniejący timeline engine nietknięty**: żaden z nowych feature'ów nie zmienia algorytmu computeTimeline.

## Functional Requirements

### S-07: Edycja i usuwanie

- FR-001: User can edit trip name, destination, dates, pace, and travel context inline from the trip list. Priority: must-have. Change: new
  > Socrates: Counter-argument considered: "editing from detail screen adds visual noise." Resolution: inline edit on trip list — faster access, no extra navigation.
- FR-002: User can edit attraction name, duration, category, and priority inline from the timeline. Priority: must-have. Change: new
  > Socrates: Counter-argument considered: "timeline is already interactive (reorder, move, delete) — adding edit makes it crowded." Resolution: kept; edit is the missing piece, and timeline already has the interaction pattern.
- FR-003: User can delete a trip with a confirmation dialog. Deleting a trip cascades to all its attractions and overrides. Priority: must-have. Change: new
  > Socrates: Counter-argument considered: "SnackBar with Undo is faster UX than confirmation dialog." Resolution: kept confirmation dialog — simpler, consistent with existing delete patterns. Undo can be added later.
- FR-004: User can delete an attraction from the timeline with a confirmation dialog. Priority: must-have. Change: new
  > Socrates: Same as FR-003 — confirmation dialog for consistency.
- FR-005: User can reset manual overrides for a day (remove all locks/reorders). Priority: nice-to-have. Change: new
  > Socrates: Counter-argument considered: "resetting overrides is rare — user can undo manually." Resolution: kept as nice-to-have; useful for 'give me back the original plan' scenario.

### S-08: Wyszukiwanie na mapie

- FR-006: User can type a place name in the map picker and see a list of matching results. Priority: must-have. Change: new
  > Socrates: Counter-argument considered: "geocoding requires API key + internet, violating offline-first." Resolution: kept; geocoding is opt-in, offline fallback exists (FR-008).
- FR-007: User can tap a search result to move the map to that location and drop a pin. Priority: must-have. Change: new
  > Socrates: Counter-argument considered: none. Standard map picker UX.
- FR-008: Map search falls back to manual coordinate entry when offline. Priority: must-have. Change: new
  > Socrates: Counter-argument considered: "offline fallback is just S-06 manual entry." Resolution: kept; the fallback path already exists — no new UX, just graceful degradation.

## Business Logic

No domain logic change for S-07 and S-08. These are UI/infrastructure changes:
- S-07: exposes existing CRUD capabilities in the UI — DAO already supports all operations
- S-08: adds geocoding lookup (standard search, not recommendations) — user searches, app finds locations

The existing timeline engine rule ("compute whether a day's plan is feasible") is unchanged. AI-powered suggestions (new domain rule: "app recommends attractions based on trip context") belong to S-11 (OpenRouter).

## Non-Functional Requirements

- **Responsive UI**: edit/delete operations produce visible feedback within 200ms. Geocoding results appear within 2s or show progress indicator.
- **Offline core preserved**: all CRUD operations work offline. Only map search requires internet (with manual fallback per FR-008).
- **No data loss**: delete operations cascade correctly (existing FK constraints). Confirmation dialogs on all destructive actions.
- **Existing timeline engine untouched**: computeTimeline() and reapplyOverrides() are not modified.

## Constraints & Preserved Behavior

- Existing API contracts preserved: TripDao, AttractionDao, TimelineOverrideDao signatures unchanged. New parameters are additive only.
- Schema backward-compatible: no migration needed for S-07/S-08 (existing v4 schema supports all CRUD operations).
- Firebase Crashlytics monitoring continues unchanged.
- CI pipeline (pr-check.yml, deploy.yml) triggers on both main and develop as before.

## Non-Goals

- No AI suggestions in this delivery (S-11 — next slice)
- No Android Auto (S-09)
- No GPS notifications (S-10)
- No changes to timeline computation algorithm
- No new data model entities — existing Trips/Attractions/TimelineOverrides are sufficient
- No authentication changes — local profile only, same as MVP

## First Delivery Scope

S-07 + S-08 w ~3 tygodnie (after-hours). S-11 jako następny slice.
