# F-01: Data Schema & Persistence — Implementation Plan

## Overview

Define the minimal data contract for the travel planner: Trip and Attraction entities, their SQLite tables via drift, basic CRUD operations, and unit tests on an in-memory database. This foundation unblocks S-01 (create trips and attractions) and S-02 (timeline generation).

## Current State Analysis

- **lib/**: single file `main.dart` — Firebase init + "Hello World" scaffold. No models, no data layer.
- **pubspec.yaml**: three Firebase deps only. No persistence library, no build_runner.
- **test/**: does not exist. No test infrastructure.
- **build.yaml**: does not exist. No code generation configured.
- **Project**: blank Flutter scaffold, ready for the first architectural layer.

### Key Discoveries:

- `lib/main.dart:5-6` — `WidgetsFlutterBinding.ensureInitialized()` + `await Firebase.initializeApp()` already set the async init pattern. Database init will follow the same pattern before `runApp()`.
- No existing state management or dependency injection — the database instance will be the first shared dependency the app needs to pass to screens/DAOs.

## Desired End State

A drift `AppDatabase` class backed by on-device SQLite. Two tables — `trips` and `attractions` — with a foreign-key relationship. Two DAOs (`TripDao`, `AttractionDao`) expose typed CRUD operations. The database opens on app start (in `main.dart`) with foreign keys enforced. Unit tests verify every CRUD operation and the FK constraint on an in-memory database — no emulator needed.

### Verification:

- `dart run build_runner build` succeeds — drift generates `.g.dart` files without errors.
- `flutter test` passes — all CRUD and FK tests green.
- `flutter build apk --debug` succeeds — the app compiles with the database layer wired.

## What We're NOT Doing

- No UI for trip creation / attraction adding (that's S-01).
- No business logic for timeline generation or overstuffing detection (S-02).
- No repository abstraction layer — DAOs are the public API for now.
- No migration path beyond schema v1 (first migration is creating tables).
- FR-007's expanded categorization (predefined list + free-text tag) — parked.
- No state management integration (Provider/Riverpod/Bloc) — DAOs are called directly.

## Implementation Approach

Drift with its Dart DSL for table definitions, `drift_flutter` for cross-platform database opening, and `NativeDatabase.memory()` for tests. The `AppDatabase` constructor accepts a `QueryExecutor` so tests can inject an in-memory connection. DAOs are `@DriftAccessor` classes on `AppDatabase` — they get compiled to typed SQL by `drift_dev`.

**Two key design choices driven by the interview:**

1. **DAOs as the public API, not repositories.** For two entities at MVP scale, a repository layer is overengineering. S-01 and S-02 import DAOs directly. If this grows unwieldy later, wrap DAOs in repositories — but not in F-01.
2. **Testable from day one.** The `AppDatabase(QueryExecutor e)` constructor costs one extra line and makes every DAO testable without an emulator. This pays for itself immediately in Phase 5.

## Critical Implementation Details

- **Foreign keys are OFF by default in SQLite.** Every connection — including the in-memory test one — must run `PRAGMA foreign_keys = ON`. Add it in `beforeOpen` in `MigrationStrategy` for production, and as a raw statement after opening the test connection.

---

## Phase 1: Setup drift — dependencies and code generation

### Overview

Add drift, drift_flutter, drift_dev, build_runner, path_provider, and path to the project. Configure `build.yaml` for drift code generation. Run `flutter pub get` and verify `build_runner` can execute.

### Changes Required:

#### 1. pubspec.yaml — Add drift dependencies

**File**: `pubspec.yaml`

**Intent**: Add the drift ecosystem as project dependencies.

**Contract**:
- `dependencies`: add `drift: ^2.34.2`, `drift_flutter: ^0.3.1`, `path_provider: ^2.1.5`, `path: ^1.9.0`
- `dev_dependencies`: add `drift_dev: ^2.34.4`, `build_runner: ^2.15.1`

#### 2. build.yaml — Configure drift code generation

**File**: `build.yaml` (new file at project root)

**Intent**: Tell build_runner which drift options to use for `.g.dart` generation.

**Contract**: Standard drift build.yaml — target `drift_dev` with default options, output in the same directory as the source.

### Success Criteria:

#### Automated Verification:

- `flutter pub get` completes without errors
- `dart run build_runner build` runs and reports success (no-op at this phase — no drift files yet, but the toolchain is verified)
- `flutter build apk --debug` compiles with the new dependencies

#### Manual Verification:

- `pubspec.yaml` contains all 6 new packages
- `build.yaml` exists at project root

---

## Phase 2: Entity and table definitions

### Overview

Define the `Trip` and `Attraction` Dart tables using drift DSL, plus the `AttractionCategory` and `TravelPace` enums. Register both tables in the `AppDatabase`. Create the database class wired to open a SQLite file on the device with foreign keys enabled.

### Changes Required:

#### 1. Category and Pace enums

**File**: `lib/database/tables.dart` (new)

**Intent**: Type-safe enums for attraction category and trip pace. Stored as text in SQLite via drift's `text()` columns.

**Contract**:
- `AttractionCategory` enum: `museum`, `restaurant`, `nature`, `landmark`, `other`
- `TravelPace` enum: `intensive`, `relaxing`
- Both enums use `.name` / `values.byName` for text serialization

#### 2. Trip table

**File**: `lib/database/tables.dart`

**Intent**: Define the `trips` SQLite table.

**Contract**:
- `id`: `integer().autoIncrement()()` — primary key
- `name`: `text().withLength(min: 1, max: 200)()` — required
- `destination`: `text().withLength(min: 1, max: 200)()` — required
- `startDate`: `dateTime().nullable()` — optional per FR-001
- `endDate`: `dateTime().nullable()` — optional per FR-001
- `pace`: `text()` — stores `TravelPace.name`, default `'intensive'`
- `createdAt`: `dateTime().withDefault(currentDateAndTime)()` — auto-set
- `updatedAt`: `dateTime().withDefault(currentDateAndTime)()` — auto-set
- `imageUrl`: `text().nullable()` — optional, no FR reference

**Note**: `createdAt` and `updatedAt` are convenience fields not required by any FR. The implementer should update `updatedAt` manually on writes (drift's `currentDateAndTime` default only fires on insert).

#### 3. Attraction table

**File**: `lib/database/tables.dart`

**Intent**: Define the `attractions` SQLite table with FK to `trips`.

**Contract**:
- `id`: `integer().autoIncrement()()` — primary key
- `name`: `text().withLength(min: 1, max: 200)()` — required
- `category`: `text()` — stores `AttractionCategory.name`, default `'other'`
- `durationMin`: `integer()` — visit duration in minutes, required per FR-003
- `priority`: `integer().withDefault(const Constant(1))()` — three-tier: 0 (must-have), 1 (nice-to-have), 2 (optional). Default = 1.
- `position`: `integer().withDefault(const Constant(0))()` — ordering within a trip per FR-004
- `tripId`: `integer().references(Trips, #id, onDelete: KeyAction.cascade)()` — FK to trips

**Note on `priority` values**: The exact three-tier labels are still an open PRD question. Using integer values (0/1/2) makes re-labeling trivial — just change the UI display string, not the schema.

#### 4. AppDatabase class

**File**: `lib/database/app_database.dart` (new)

**Intent**: The drift `@DriftDatabase` entry point. Accepts a `QueryExecutor` for testability. Opens SQLite file in production via `drift_flutter`.

**Contract**:
- `@DriftDatabase(tables: [Trips, Attractions])`
- Constructor: `AppDatabase(QueryExecutor e) : super(e);`
- Static factory or top-level function `openAppDatabase()` that calls `driftDatabase(name: 'travelapp_db')` — this is what `main.dart` calls in production
- `schemaVersion = 1`
- `MigrationStrategy` with `onCreate` → `m.createAll()`, `beforeOpen` → `PRAGMA foreign_keys = ON`

### Success Criteria:

#### Automated Verification:

- `dart run build_runner build` succeeds and generates `tables.g.dart` + `app_database.g.dart`
- `flutter build apk --debug` compiles — tables and database class are valid drift code

#### Manual Verification:

- `lib/database/tables.dart` defines both table classes with all columns listed above
- `lib/database/app_database.dart` registers both tables and has `schemaVersion = 1`
- Generated `.g.dart` files exist and contain table companions + data classes

---

## Phase 3: DAO/CRUD operations

### Overview

Create `TripDao` and `AttractionDao` as `@DriftAccessor` classes. Each DAO provides typed methods: create, getById, list (with appropriate ordering), update, and delete. AttractionDao additionally provides `listByTrip` sorted by position.

### Changes Required:

#### 1. TripDao

**File**: `lib/database/daos/trip_dao.dart` (new)

**Intent**: Typed CRUD for the `trips` table. DAOs are the public API slice consumers import.

**Contract**:
- `Future<int> createTrip(...)` — insert with required fields, return new row id
- `Future<Trip?> getTripById(int id)` — single lookup, null if missing
- `Future<List<Trip>> listAllTrips()` — all trips, newest first (by `createdAt` desc)
- `Future<bool> updateTrip(int id, {...})` — partial update via `TripsCompanion` with `Value(...)` for changed fields; updates `updatedAt` to `DateTime.now()`
- `Future<int> deleteTrip(int id)` — deletes trip; cascades to its attractions per FK

#### 2. AttractionDao

**File**: `lib/database/daos/attraction_dao.dart` (new)

**Intent**: Typed CRUD for the `attractions` table, with trip-scoped listing by position.

**Contract**:
- `Future<int> createAttraction(...)` — insert, return new row id. Accepts: name, category, durationMin, priority, position, tripId
- `Future<Attraction?> getAttractionById(int id)` — single lookup
- `Future<List<Attraction>> listAttractionsByTrip(int tripId)` — all attractions for a trip, ordered by `position ASC`
- `Future<void> updateAttraction(int id, {...})` — partial update via `AttractionsCompanion`
- `Future<int> deleteAttraction(int id)` — single delete

### Success Criteria:

#### Automated Verification:

- `dart run build_runner build` succeeds and generates `trip_dao.g.dart` + `attraction_dao.g.dart`
- `flutter build apk --debug` compiles with DAOs importable

#### Manual Verification:

- Both DAO files exist with all 5 method signatures each
- Generated `.g.dart` files exist

---

## Phase 4: Wire database initialization into main.dart

### Overview

Open the production database before `runApp()` in `main.dart`, using the `drift_flutter` helper. Store the `AppDatabase` instance for downstream consumers. This is the minimal wiring — no DI container; slices import the database instance directly or via a simple getter.

### Changes Required:

#### 1. Database initialization in main.dart

**File**: `lib/main.dart`

**Intent**: Open the database during app startup, after Firebase init, before `runApp()`. Make the database instance available to the rest of the app.

**Contract**:
- After `await Firebase.initializeApp();`, add `final database = await openAppDatabase();`
- Store `database` in a way accessible to future screens/DAOs. For now: a top-level variable or a simple static accessor. The implementer picks the simplest approach — the plan does not prescribe Provider/Riverpod/InheritedWidget at this stage.
- Before opening: ensure `WidgetsFlutterBinding.ensureInitialized()` is already called (it is, line 5).

**Implementation note**: Since no state management or widget tree exists yet beyond `MainApp`, the simplest contract is a top-level `AppDatabase? _database` with an async `getDatabase()` getter that returns it once initialized. Slice consumers (S-01) call `final db = await getDatabase(); final tripDao = TripDao(db);` from their widgets or a future builder. The plan does not prescribe a specific DI pattern — the implementer picks the simplest thing that works for two DAOs.

### Success Criteria:

#### Automated Verification:

- `flutter build apk --debug` compiles with `openAppDatabase()` call in `main()`

#### Manual Verification:

- App launches without crashes (database file created in app documents directory)
- `lib/main.dart` imports `database/app_database.dart` and calls `openAppDatabase()`

---

## Phase 5: Unit tests

### Overview

Write unit tests for both DAOs on an in-memory drift database. Tests run on the Dart VM — no emulator or Flutter framework needed. Cover: create, read, update, delete for both entities, FK cascade delete, and list ordering.

### Changes Required:

#### 1. Test infrastructure and TripDao tests

**File**: `test/database/trip_dao_test.dart` (new)

**Intent**: Verify every CRUD operation on `TripDao` against an in-memory SQLite database. Each test gets a fresh database in `setUp` and closes it in `tearDown`.

**Contract**:
- `setUp`: create `AppDatabase` with `DatabaseConnection(NativeDatabase.memory())` and `closeStreamsSynchronously: true`, run `PRAGMA foreign_keys = ON`
- Test cases (one per `test()` block):
  - **create and read**: insert a trip, verify returned id > 0, fetch by id, assert all fields match
  - **list all — newest first**: insert 3 trips, verify `listAllTrips()` returns them in `createdAt DESC` order
  - **update**: insert, update name and destination, fetch, assert new values + `updatedAt` changed
  - **delete**: insert, delete, verify `getTripById` returns null
  - **cascade delete**: insert trip, insert 2 attractions linked to it, delete trip, verify attractions are gone via `listAttractionsByTrip`

#### 2. AttractionDao tests

**File**: `test/database/attraction_dao_test.dart` (new)

**Intent**: Verify CRUD on `AttractionDao`, including trip-scoped listing with position ordering.

**Contract**:
- Same `setUp`/`tearDown` as trip tests
- Test cases:
  - **create and read**: insert attraction linked to a trip, verify all fields
  - **list by trip — position order**: insert 3 attractions with positions 2, 0, 1, verify `listAttractionsByTrip` returns [pos0, pos1, pos2]
  - **update**: change name and durationMin, verify
  - **delete**: delete one of several attractions, verify count decreases
  - **FK integrity**: attempt to insert attraction with non-existent `tripId`, expect SQLite constraint error thrown

### Success Criteria:

#### Automated Verification:

- `flutter test` runs all `test/database/*.dart` files
- Every test case passes
- `flutter test --coverage` shows coverage on `lib/database/`

#### Manual Verification:

- `test/database/` directory exists with 2 test files
- Test output shows ≥ 10 test cases passing

---

## Testing Strategy

### Unit Tests:

- **TripDao**: create + read roundtrip, list ordering (newest first), update fields + `updatedAt`, delete, cascade delete of attractions
- **AttractionDao**: create + read roundtrip, list by trip with position ordering, update, delete, FK integrity violation

### Integration Tests:

- None at F-01 stage. Integration with the real Android SQLite is tested implicitly when the app launches in debug mode. Full integration tests belong in S-01 when UI exercises the DAOs through real user flows.

### Manual Testing Steps:

1. After Phase 4: launch app on device/emulator, verify no crash on startup — the database file is created silently
2. After Phase 5: run `flutter test` and confirm all tests green
3. Verify FK cascade: delete a trip in a test, confirm child attractions deleted

## Performance Considerations

- `PRAGMA foreign_keys = ON` runs once on connection open — negligible overhead
- `NativeDatabase.memory()` for tests creates a fresh in-memory DB per test — fast, no disk I/O
- No indexes needed at this stage — tables have ≤ 3-digit row counts at MVP scale

## References

- Roadmap: `context/foundation/roadmap.md` — F-01
- PRD: `context/foundation/prd.md` — FR-001 through FR-006, Business Logic section
- GitHub Issue: [#1](https://github.com/kamilbemowski/traveljug/issues/1)
- drift docs: https://drift.simonbinder.eu/

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Setup drift — dependencies and code generation

#### Automated

- [x] 1.1 `flutter pub get` completes without errors
- [x] 1.2 `dart run build_runner build` runs and exits clean
- [x] 1.3 `flutter build apk --debug` compiles with new dependencies

#### Manual

- [ ] 1.4 `pubspec.yaml` contains all 6 new packages
- [ ] 1.5 `build.yaml` exists at project root

### Phase 2: Entity and table definitions

#### Automated

- [x] 2.1 `dart run build_runner build` generates `tables.g.dart` and `app_database.g.dart` — ede225a
- [x] 2.2 `flutter build apk --debug` compiles — ede225a

#### Manual

- [x] 2.3 `lib/database/tables.dart` defines `Trips` and `Attractions` table classes with all columns — ede225a
- [x] 2.4 `lib/database/app_database.dart` registers both tables, `schemaVersion = 1` — ede225a
- [x] 2.5 Generated `.g.dart` files exist in `lib/database/` — ede225a

### Phase 3: DAO/CRUD operations

#### Automated

- [x] 3.1 `dart run build_runner build` generates `trip_dao.g.dart` and `attraction_dao.g.dart` — fa55323
- [x] 3.2 `flutter build apk --debug` compiles with DAOs importable — fa55323

#### Manual

- [x] 3.3 `lib/database/daos/trip_dao.dart` has 5 CRUD methods — fa55323
- [x] 3.4 `lib/database/daos/attraction_dao.dart` has 5 CRUD methods — fa55323

### Phase 4: Wire database initialization into main.dart

#### Automated

- [x] 4.1 `flutter build apk --debug` compiles with database init in `main()` — 418ae9d

#### Manual

- [x] 4.2 App launches without crashes on device/emulator — 418ae9d
- [x] 4.3 `main.dart` imports `app_database.dart` and calls `openAppDatabase()` — 418ae9d

### Phase 5: Unit tests

#### Automated

- [x] 5.1 `flutter test` runs all database tests and every test case passes — f4517ba
- [x] 5.2 `flutter test --coverage` shows coverage on `lib/database/` — f4517ba

#### Manual

- [x] 5.3 `test/database/` directory exists with `trip_dao_test.dart` and `attraction_dao_test.dart`
- [x] 5.4 Test output shows ≥ 10 test cases passing
