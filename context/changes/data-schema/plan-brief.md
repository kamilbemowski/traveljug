# F-01: Data Schema & Persistence — Plan Brief

> Full plan: `context/changes/data-schema/plan.md`

## What & Why

Travelapp nie ma warstwy danych — zero modeli, zero persystencji. F-01 to fundament: definiuje encje Trip i Attraction w drift (SQLite), podłącza podstawowe CRUD, i dostarcza testowalny kontrakt dla S-01 (tworzenie tripów) i S-02 (timeline). Bez tego każdy kolejny slice zaczynałby od wymyślania schematu na nowo.

## Starting Point

Projekt to czysta karta — `lib/main.dart` z "Hello World" i trzema zależnościami Firebase w `pubspec.yaml`. Brak `test/`, brak `build.yaml`, brak jakiejkolwiek warstwy danych. To pierwsza warstwa architektoniczna w projekcie.

## Desired End State

`lib/database/` zawiera encje Trip i Attraction jako tabele drift, DAO z typed CRUD, i `AppDatabase` otwierającą SQLite na urządzeniu. `flutter test` odpala >10 testów jednostkowych na in-memory bazie — wszystkie zielone. `main.dart` inicjalizuje bazę po Firebase, przed `runApp()`.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Persistence library | drift (v2.34.2) | Type-safe, reactive streams, wbudowane migracje — najlepsze dopasowanie do timeline'a z S-02. | Plan |
| Scope F-01 | Encje + tabele + CRUD | Minimalny kontrakt — S-01 dostaje gotowe DAO bez pisania SQL. | Plan |
| Relacja Trip→Attraction | FK + position | Proste, naturalne, drift wspiera FK z cascade delete. | Plan |
| Pola Attraction | name, category, durationMin, priority, position, tripId | Dokładnie to czego wymagają FR-003 i FR-006. | Plan |
| Pola Trip | name, destination, startDate?, endDate?, pace, createdAt, updatedAt, imageUrl | FR-001 + Business Logic + rozszerzone o timestampy i imageUrl. | Plan |
| Testy | Unit testy na in-memory drift DB | Szybkie, bez emulatora, łapią błędy schematu i CRUD. | Plan |
| API shape | DAO jako public API | Dla 2 encji repozytorium to overengineering. DAO są wystarczające. | Plan |
| DI strategy | Top-level getter | Żadnego Provider/Riverpod — to MVP, nie enterprise app. | Plan |

## Scope

**In scope:** drift setup (deps + build_runner), Trip i Attraction tabele z FK, TripDao i AttractionDao (create/getById/list*/update/delete), init bazy w main.dart, testy jednostkowe.

**Out of scope:** UI dla S-01, logika timeline'a (S-02), repozytorium abstrakcyjne, migracje poza v1, FR-007 rozszerzona kategoryzacja.

## Architecture / Approach

```
lib/database/
  tables.dart          ← Trips, Attractions table classes + enums
  app_database.dart    ← @DriftDatabase, openAppDatabase()
  daos/
    trip_dao.dart      ← TripDao: CRUD dla trips
    attraction_dao.dart ← AttractionDao: CRUD dla attractions

test/database/
  trip_dao_test.dart
  attraction_dao_test.dart
```

`AppDatabase(QueryExecutor e)` — konstruktor z parametrem umożliwia testy na `NativeDatabase.memory()`. Produkcja używa `driftDatabase(name: 'travelapp_db')` z `drift_flutter`. DAO są `@DriftAccessor` — drift generuje dla nich typed SQL.

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Setup | drift + build_runner w pubspec.yaml, build.yaml | Nic — standardowy boilerplate |
| 2. Encje | Trips i Attractions tabele, AppDatabase | Zły schemat = migracja w S-01 |
| 3. CRUD | TripDao + AttractionDao z 5 metodami każdy | Nic — drift generuje metody z adnotacji |
| 4. Wiring | Baza otwiera się w main.dart przed runApp() | Nic — 3 linijki kodu |
| 5. Testy | ≥10 testów jednostkowych, wszystkie zielone | Nic — in-memory DB, bez emulatora |

**Prerequisites:** żadne — F-01 nie ma zależności.
**Estimated effort:** ~1 sesja (wszystkie 5 faz to drift boilerplate + testy).

## Open Risks & Assumptions

- **Category jako enum, nie tabela.** `AttractionCategory` to Dart enum z 5 wartościami (`museum`, `restaurant`, `nature`, `landmark`, `other`). Jeśli FR-007 wróci z parkingu i będzie wymagać dynamicznych kategorii, trzeba będzie zmienić na tabelę. Ryzyko: niskie — migracja z enuma na tabelę jest prosta.
- **Priority jako int (0/1/2).** Etykiety (high/medium/low czy must-have/nice-to-have/optional) nie są jeszcze ustalone w PRD. Int w schemacie pozwala zmienić etykiety bez migracji.
- **DI przez top-level getter.** Przy 2 DAO to wystarcza. Jeśli S-01/S-02 będą potrzebować więcej, można dodać Provider/Riverpod. To nie jest decyzja architektoniczna, tylko pragmatyczny wybór na MVP.

## Success Criteria (Summary)

- `dart run build_runner build` generuje `.g.dart` bez błędów
- `flutter test` — wszystkie testy zielone
- `flutter build apk --debug` — apka się kompiluje i odpala bez crasha
