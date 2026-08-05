---
project: TravelJug
version: 2
status: draft
created: 2026-08-05
updated: 2026-08-05
prd_version: 2
main_goal: speed
top_blocker: decisions
---

# Roadmap: TravelJug Post-MVP

> Derived from `context/foundation/prd-v2.md` (v2) + existing codebase.
> Slices below are listed by priority (speed-first). The "At a glance" table is the index.

## Vision recap

TravelJug jest dziś kalkulatorem intensywności podróży — oblicza timeline, ale nie pomaga go zbudować. Post-MVP v2 dodaje dwie brakujące podstawy: pełną kontrolę nad danymi (edycja i usuwanie wszystkiego z UI) oraz wyszukiwanie miejsc na mapie (geocoding). Oba feature'y zamykają experience gaps z używania apki — użytkownik nie musi już akceptować "read-only" tripa ani ręcznie szukać współrzędnych.

## North star

**S-08: Map Search** — użytkownik wpisuje nazwę miejsca, apka znajduje je i ustawia pinezkę. To jest ten moment, w którym apka po raz pierwszy robi coś, czego nie da się zastąpić notatnikiem — aktywna pomoc w planowaniu. Umieszczony najwcześniej bo S-07 i S-08 są niezależne, a S-08 ma większy "wow factor".

> "Gwiazda przewodnia" — pierwszy, najmniejszy kawałek produktu, którego dostarczenie dowodzi, że apka wyszła z fazy kalkulatora i stała się narzędziem planowania.

## At a glance

| ID    | Change ID        | Outcome (user can …)                                          | Prerequisites | PRD refs                       | Status   |
| ----- | ---------------- | ------------------------------------------------------------- | ------------- | ------------------------------ | -------- |
| S-08  | map-search       | search for places by name in the map picker and pin results   | S-06          | FR-006, FR-007, FR-008         | blocked  |
| S-07  | edit-delete-everything | edit and delete every entity — trips, attractions, overrides — from the UI | —             | FR-001, FR-002, FR-003, FR-004, FR-005 | ready    |

## Streams

| Stream | Theme                | Chain                    | Note                                                      |
| ------ | -------------------- | ------------------------ | --------------------------------------------------------- |
| A      | Plan building tools  | `S-08`                   | Gwiazda przewodnia — wyszukiwanie na mapie, zależne od S-06. |
| B      | Data control         | `S-07`                   | Pełny CRUD w UI — niezależny od S-08, gotowy do startu.   |

## Baseline

What's already in place in the codebase as of 2026-08-05 (znane z projektu).

- **Frontend:** present — Flutter/Dart, MaterialApp, 4 ekrany, map picker (google_maps_flutter)
- **Backend / API:** absent by design — local-first mobile app, no server
- **Data:** present — Drift SQLite v4, 3 tabele, pełny CRUD w DAO, migracje v1→v4
- **Auth:** absent by design — local profile only, no login
- **Deploy / infra:** present — GitHub Actions (pr-check, deploy), Firebase App Distribution
- **Observability:** present — Firebase Crashlytics

## Foundations

(Brak — wszystkie warstwy są obecne. Nowe slice'y nie potrzebują dodatkowej infrastruktury.)

## Slices

### S-08: Map Search (geocoding)

- **Outcome:** user can type a place name in the map picker, see matching results, tap one to move the map and drop a pin. Falls back to manual coordinate entry when offline.
- **Change ID:** map-search
- **PRD refs:** FR-006, FR-007, FR-008
- **Prerequisites:** S-06 (map picker must exist — ✅ done)
- **Parallel with:** S-07 (edit-delete-everything)
- **Blockers:** —
- **Unknowns:**
  - Geocoding provider: Google Geocoding API ($5/1k po 10k free) vs OSM Nominatim (free, 1 req/s)? — Owner: dev. Block: yes.
  - Cache strategy for geocoding results? — Owner: dev. Block: no (nice-to-have, can be added post-MVP).
- **Risk:** Niski — map picker już istnieje, geocoding to dodatkowa warstwa. Jedynym ryzykiem jest wybór providera — trzeba rozstrzygnąć przed `/10x-plan`.
- **Status:** blocked (do czasu wyboru geocoding providera)

### S-07: Edit & Delete Everything

- **Outcome:** user can edit trip fields inline from the trip list, edit attraction fields inline from the timeline, delete trips and attractions with confirmation dialogs, and reset manual overrides for a day.
- **Change ID:** edit-delete-everything
- **PRD refs:** FR-001, FR-002, FR-003, FR-004, FR-005
- **Prerequisites:** — (DAO already supports all CRUD operations)
- **Parallel with:** S-08 (map-search)
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Niski — czysta warstwa UI nad istniejącym DAO. Żadnych nowych zależności, żadnych zmian w schemie, żaden wpływ na timeline engine.
- **Status:** ready

## Backlog Handoff

| Roadmap ID | Change ID              | Suggested issue title                | Ready for `/10x-plan` | Notes |
| ---------- | ---------------------- | ------------------------------------ | --------------------- | ----- |
| S-08       | map-search             | Map search with geocoding            | no                    | Blocked: wybierz geocoding provider |
| S-07       | edit-delete-everything | Edit and delete all entities from UI | yes                   | Run `/10x-plan edit-delete-everything` |

## Open Roadmap Questions

1. **Geocoding provider** — Google Geocoding API czy OSM Nominatim? — Owner: dev. Block: S-08.
2. **User Stories dla S-07 i S-08** — PRD v2 nie ma Given/When/Then. Czy FR-y wystarczą do planowania? — Owner: dev. Block: no (można planować z FR-ów).
3. **S-05 manual verification** — itemy 1.3, 1.4, 2.3, 2.4 nigdy nie były formalnie zweryfikowane na urządzeniu. — Owner: dev. Block: no.

## Parked

- **S-09 (Android Auto)** — Why parked: poza scope v2. Wróci w następnej dostawie.
- **S-10 (GPS notifications)** — Why parked: poza scope v2.
- **S-11 (OpenRouter AI suggestions)** — Why parked: poza scope v2. Wymaga osobnego researchu API.
- **Cloud sync / multi-device** — Why parked: per PRD §Non-Goals.

## Done

- **S-01—S-06: MVP TravelJug** — Zarchiwizowane w oryginalnym roadmap.md (archiwum: `context/foundation/archive/2026-08-05-roadmap-mvp.md`). 9 slice'ów, 66 testów, wszystkie zrealizowane.
