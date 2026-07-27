# S-02: Timeline Generation — Plan Brief

> Full plan: `context/changes/timeline-generation/plan.md`
> Research: `context/changes/timeline-generation/research.md`

## What & Why

TripDetailScreen pokazuje teraz płaską listę atrakcji — bez dat, bez godzin, bez ostrzeżeń o przepełnieniu. S-02 to gwiazda przewodnia: zamienia tę listę w day-by-day plan z wyliczonymi czasami, przerwami na przejazd, ostrzeżeniami o przepełnieniu i wyróżnieniem atrakcji "must-have". To jest core product hypothesis — bez tego apka to po prostu lista rzeczy do zrobienia.

## Starting Point

TripDetailScreen już ładuje atrakcje przez `AttractionDao.listAttractionsByTrip()`. Trip ma `startDate`, `endDate`, `pace`. Atrakcje mają `durationMin`, `priority`, `position`. Brakuje: silnika obliczeniowego timeline'a, konfiguracji pace→godziny, modelu TimelineDay, i UI dnia.

## Desired End State

Użytkownik otwiera trip → widzi plan dnia po dniu: każdy dzień z nagłówkiem daty, atrakcje z wyliczonymi godzinami startu (HH:MM), czasem przejazdu między atrakcjami, i ostrzeżeniem jeśli dzień jest przepełniony. Atrakcje must-have (priority=0) są wyróżnione. Intensywny pace = 7-23 (16h), relaksujący = 10-20 (10h).

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Algorithm | Greedy fill | Prosty, zgodny z PRD "user ordenuje, app wypełnia". Overstuffing detection łapie problemy. | Research |
| Travel time | Flat 30 min × pace multiplier | Brak danych GPS — kategoryzacja bez lokalizacji to false precision. S-04 doda dynamiczny travel time. | Research + Plan |
| Pace config | Extension on TravelPace | App constants, nie dane użytkownika — nie powinny być w DB. | Research |
| Timeline persistence | Stateless computation | S-02 tylko wyświetla. S-03 doda persystencję dla manualnych edycji. | Research |
| UI placement | Replace flat list on TripDetailScreen | Ten sam ekran, inna zawartość — nie trzeba nowej nawigacji. | Plan |
| Computation timing | Eager on screen load | Użytkownik widzi plan od razu, bez dodatkowego kliknięcia. | Plan |
| Model | Typed TimelineDay + TimelineSlot | Type-safe, testowalne — lepsze niż Map<String,dynamic>. | Plan |

## Scope

**In scope:** PaceConfig extension, TimelineDay/TimelineSlot models, TimelineService.computeTimeline(), unit tests (≥8), TripDetailScreen rewrite to timeline view, overstuffing warnings, must-have highlights.

**Out of scope:** Timeline persistence (S-03), dynamic travel time per trip context (S-04), manual reordering (S-03), meal time surcharge, timeline editing.

## Architecture / Approach

```
lib/services/pace_config.dart     ← PaceConfig class + TravelPace extension
lib/models/timeline_day.dart      ← TimelineDay + TimelineSlot value objects
lib/services/timeline_service.dart ← computeTimeline() pure function

TripDetailScreen:
  _loadTimeline() → TimelineService.computeTimeline(trip, attractions)
  → List<TimelineDay> → day-by-day ListView
```

Timeline to pure function — zero side effects, zero DB writes. Recomputes from scratch przy każdym `_loadTimeline()`. To celowe — S-03 doda persystencję gdy będzie potrzebna.

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Pace config + models | PaceConfig, TimelineDay, TimelineSlot, kDefaultTravelMinutes | None — pure data classes |
| 2. Timeline engine | computeTimeline() + ≥8 unit tests | Algorithm bugs (wrong day splits, overflow) |
| 3. Timeline UI | TripDetailScreen rewritten with day-by-day view, overstuffing warnings, must-have highlights | UI complexity — first timeline rendering |

**Prerequisites:** S-01 (create-trip-and-attractions) ✅, F-01 (data-schema) ✅
**Estimated effort:** ~2-3 sesje — 3 fazy, core business logic + UI.

## Open Risks & Assumptions

- **TravelPace.byName(trip.pace) może rzucić ArgumentError** — plan przewiduje safe-parsing z fallbackiem do `intensive`.
- **Trip bez dat** — plan pokazuje placeholder "Add trip dates to see your plan". Jeśli user stworzył trip bez dat (FR-001 pozwala), timeline nie ma na czym operować.
- **Brak testów widgetowych** — świadoma decyzja. Timeline UI jest read-only; widget testy mają sens dopiero gdy S-03 doda interaktywność.

## Success Criteria (Summary)

- `flutter test test/services/timeline_service_test.dart` — ≥8 testów, wszystkie zielone.
- TripDetailScreen pokazuje day-by-day plan z czasami, przerwami na przejazd, ostrzeżeniami i wyróżnieniem must-have.
- Overstuffing warning pojawia się gdy suma czasów > daily budget.
