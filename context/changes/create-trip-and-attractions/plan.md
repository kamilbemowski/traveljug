# S-01: Create Trip and Add Attractions — Implementation Plan

## Overview

Build the first user-visible screens: a trip list, a create-trip form, and a trip detail view where the user adds attractions. Uses existing TripDao and AttractionDao from F-01. Follows standard Flutter patterns: Material Design, Navigator.push, Form validation, direct getDatabase() access.

## Current State Analysis

- `lib/database/` — TripDao + AttractionDao with full CRUD, ready to use.
- `lib/main.dart` — `getDatabase()` singleton warms up the database before `runApp()`.
- `lib/` has no screens, no widgets, no navigation — just `main.dart` with "Hello World".
- `test/database/` — existing DAO tests pass. No widget test infrastructure.

### Key Discoveries:

- `lib/main.dart:14-18` — `getDatabase()` returns `Future<AppDatabase>` singleton. Widgets call `final db = await getDatabase(); final tripDao = TripDao(db);`.
- Priority values are integers in DB (0=must-have, 1=nice-to-have, 2=optional). UI maps these to strings.
- `AttractionCategory` enum (museum, restaurant, nature, landmark, other) is defined in `tables.dart`.

## Desired End State

The app opens to a trip list (sorted newest first). A FAB opens a create-trip form (name, destination, dates, pace). Tapping a trip shows its detail with the attraction list. An "Add attraction" button opens a dialog/form to add an attraction to that trip. All data persists via drift/SQLite.

### Verification:

- App launches showing trip list (empty state: "No trips yet").
- Create trip → appears in list.
- Tap trip → see detail with "Add attraction" button.
- Add attraction → appears in trip's attraction list.
- `flutter analyze` passes, `flutter test` passes.

## What We're NOT Doing

- No trip editing or deletion in this slice (can add later).
- No attraction editing — only create and list.
- No timeline generation or overstuffing detection (that's S-02).
- No search in trip list (FR-002 mentions it, but MVP can defer).
- No state management library — direct DAO access.
- No widget tests for every screen — only the trip list screen.

## Implementation Approach

Flat Flutter without additional state management libraries. Each screen calls `getDatabase()` to obtain the singleton and creates DAOs. Screens are `StatefulWidget` because they load async data. Navigation via `Navigator.push`. Forms use `GlobalKey<FormState>` with `TextFormField.validator`. Priority labels: Must-have (0), Nice-to-have (1), Optional (2).

---

## Phase 1: Trip list screen

### Overview

Replace the "Hello World" in `MainApp` with a `TripListScreen` that shows all trips sorted newest first. Empty state shows a placeholder message. FAB navigates to the create-trip screen (stubbed in Phase 2).

### Changes Required:

#### 1. TripListScreen widget

**File**: `lib/screens/trip_list_screen.dart` (new)

**Intent**: Display all trips from the database, sorted newest first. Show empty state when no trips exist.

**Contract**:
- `TripListScreen` is a `StatefulWidget`.
- `_loadTrips()` async method calls `TripDao(db).listAllTrips()` and calls `setState`.
- `initState` calls `_loadTrips()`.
- Display as `ListView.builder` with `ListTile` per trip: name, destination, dates.
- Empty state: centered text "No trips yet. Tap + to create your first trip."
- FAB with `Icons.add` navigates to `CreateTripScreen` via `Navigator.push(...).then((_) => _loadTrips())` — refreshes list on return.
- Tapping a trip navigates to `TripDetailScreen`.

#### 2. Wire TripListScreen into MainApp

**File**: `lib/main.dart`

**Intent**: Replace the Scaffold with `Hello World` by `TripListScreen`.

**Contract**:
- In `MainApp.build`, `home:` becomes `const TripListScreen()`.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- App launches showing empty state
- FAB is visible

---

## Phase 2: Create trip screen

### Overview

A form screen with fields: name (required), destination (required), start date (optional), end date (optional), pace (dropdown: intensive/relaxing). On save, creates the trip via TripDao and pops back to the list.

### Changes Required:

#### 1. CreateTripScreen widget

**File**: `lib/screens/create_trip_screen.dart` (new)

**Intent**: Collect trip data through a validated form and persist via TripDao.

**Contract**:
- `StatefulWidget` with `GlobalKey<FormState>`.
- Fields: `TextFormField` for name (required, max 200), destination (required, max 200), start date, end date (both optional `DatePicker`), pace (DropdownButtonFormField: intensive/relaxing).
- Name and destination validators: must not be empty.
- Save button calls `TripDao(db).createTrip(...)`, then `Navigator.pop(context, true)` to signal the list to refresh.
- After dates are picked, the form fields display the selected dates.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- Tap FAB → form opens
- Fill fields, tap Save → form closes, trip appears in list
- Leave name empty, tap Save → validation error shown

---

## Phase 3: Trip detail and add attraction

### Overview

Tapping a trip in the list opens `TripDetailScreen` showing trip info and its attractions (sorted by position). An "Add Attraction" button opens a dialog/form to add an attraction to this trip.

### Changes Required:

#### 1. TripDetailScreen widget

**File**: `lib/screens/trip_detail_screen.dart` (new)

**Intent**: Show trip metadata and its list of attractions. Provide a way to add attractions.

**Contract**:
- Receives a `Trip` object (passed via constructor from list).
- Displays trip name, destination, dates, pace.
- Lists attractions via `AttractionDao(db).listAttractionsByTrip(trip.id)`.
- "Add Attraction" button opens `_AddAttractionDialog`.
- After adding, refreshes the attraction list.

#### 2. AddAttractionDialog

**File**: `lib/screens/trip_detail_screen.dart` (inline or separate file)

**Intent**: Simple form to add an attraction to the current trip.

**Contract**:
- Fields: name (required), category (dropdown: `AttractionCategory` values), duration in minutes (text/number), priority (dropdown: Must-have/Nice-to-have/Optional).
- On save: calls `AttractionDao(db).createAttraction(...)` with `tripId`, `position` = `existingAttractions.length` (append to end of the list).
- Refreshes the attraction list via `_loadAttractions()` after save.
- Validates: name not empty, duration > 0.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- Tap a trip → detail screen shows trip info
- "Add Attraction" → form opens
- Fill and save → attraction appears in list
- Back to trip list → trip is still there

---

## Phase 4: Widget tests

### Overview

Add a widget test for the trip list screen (empty state and with trips) using an in-memory database.

### Changes Required:

#### 1. Widget test for TripListScreen

**File**: `test/screens/trip_list_screen_test.dart` (new)

**Intent**: Verify the trip list renders empty state and populated state correctly.

**Contract**:
- Test setup: create `AppDatabase(NativeDatabase.memory())`, run migrations, insert DAOs.
- `testWidgets('shows empty state when no trips', ...)` — renders `TripListScreen`, expects "No trips yet" text.
- `testWidgets('shows trips in list', ...)` — inserts 2 trips, renders screen, expects `ListTile` widgets with trip names.
- Use `WidgetTester` with `pumpWidget(MaterialApp(home: TripListScreen(...)))`.

### Success Criteria:

#### Automated Verification:

- `flutter test` passes (including new widget tests)
- `flutter analyze` passes

#### Manual Verification:

- Widget test output shows tests for TripListScreen
- Coverage includes `lib/screens/trip_list_screen.dart`

---

## Testing Strategy

### Widget Tests:

- **TripListScreen**: empty state, populated state, FAB exists.

### Manual Testing Steps:

1. Launch app — empty trip list shown.
2. Tap FAB → fill create-trip form → Save → trip appears.
3. Tap trip → detail screen shows info.
4. Add attraction → appears in list.
5. Back to list → trip is still there, sorted newest first.

## Performance Considerations

- Trip list loads all trips at once — fine for MVP (≤100 trips).
- Attraction list per trip loaded fully — fine for MVP (≤50 attractions per trip).
- No pagination or lazy loading needed at this scale.

## References

- Roadmap: `context/foundation/roadmap.md` — S-01
- PRD: `context/foundation/prd.md` — FR-001, FR-002, FR-003, FR-006
- GitHub Issue: [#4](https://github.com/kamilbemowski/traveljug/issues/4)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Trip list screen

#### Automated

- [x] 1.1 `flutter analyze` passes
- [x] 1.2 `flutter build apk --debug` compiles

#### Manual

- [x] 1.3 App launches showing empty state
- [x] 1.4 FAB is visible

### Phase 2: Create trip screen

#### Automated

- [x] 2.1 `flutter analyze` passes
- [x] 2.2 `flutter build apk --debug` compiles

#### Manual

- [x] 2.3 Tap FAB → form opens, fill and save → trip appears in list
- [x] 2.4 Empty name validation shows error

### Phase 3: Trip detail and add attraction

#### Automated

- [x] 3.1 `flutter analyze` passes
- [x] 3.2 `flutter build apk --debug` compiles

#### Manual

- [x] 3.3 Tap trip → detail shows info and attractions
- [x] 3.4 Add attraction → appears in list

### Phase 4: Widget tests

#### Automated

- [x] 4.1 `flutter test` passes with widget tests
- [x] 4.2 `flutter analyze` passes

#### Manual

- [x] 4.3 Coverage includes `lib/screens/trip_list_screen.dart`
