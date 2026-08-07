# Android Auto — Implementation Plan

## Overview

Add Android Auto support to TravelJug so the user can view today's travel plan on their
car dashboard. The app shows a list of today's attractions (name, start time, travel gap,
must-have star) with a "Navigate" button opening Google Maps. Uses `flutter_carplay` —
the only maintained Flutter package for Android Auto template projection.

GPS proximity notifications are split out to S-10 — they work independently of Android Auto.

## Current State Analysis

- **Timeline engine** (`lib/services/timeline_service.dart`) produces `List<TimelineDay>`
  with `TimelineSlot`s — each has `attraction.name`, `startTime`, `travelFromPrevMin`,
  `attraction.coordinates`, `attraction.priority`.
- **Database** v5 schema: Trips, Attractions, TimelineOverrides. Full CRUD via DAOs.
- **Map picker** already opens Google Maps via `url_launcher` with `?q=lat,lng` pattern
  (`map_picker_screen.dart:122-140`) — reusable for Navigate button.
- **flutter_carplay** (v1.6.4, MIT, 304★ GitHub) is the only viable Flutter AA package.
  Supports ListTemplate, Pane, Grid, Alert. Does NOT support map or navigation templates.

### Key Discoveries:

- `TimelineDay` already has all data needed for AA display — no new computation needed.
- `_openInMaps()` in `map_picker_screen.dart:122-140` is the pattern for Navigate action.
- Android Auto renders on car host, not Flutter — templates are serialized model graphs.
- `flutter_carplay` setup requires `FlutterEngineCache`, `automotive_app_desc.xml`,
  and manifest `CarAppService` declaration (documented in package README).

## Desired End State

User starts the car → Android Auto shows today's plan as a list. Each row: ⭐ (if
must-have), attraction name, start time (HH:MM), travel gap from previous ("← 15 min"),
and a "Navigate" button. No map or turn-by-turn — just the intent to Google Maps.

Trip selection priority:
1. Active trip whose dates cover today (`isActive = true`)
2. Last-opened trip (highest `updatedAt`)
3. If none: show trip list for manual selection

Edge cases handled:
- No attractions on today → message "No attractions planned for today" + "Open app" action
- Attraction has no coordinates → Navigate button hidden
- No trip at all → message "No trips yet" + "Open app" action
- Multiple active trips on same dates → first by `updatedAt`
- Phone not connected to AA → app works normally, no AA service registered

## What We're NOT Doing

- No navigation template (NavigationTemplate) — Maps handles turn-by-turn
- No map display in AA — ListTemplate only
- No editing from AA — read-only view
- No iOS / CarPlay (flutter_carplay supports it, but out of scope)
- No Android Automotive OS (embedded car system, not phone projection)
- No GPS proximity notifications → S-10
- No offline map caching

## Critical Implementation Details

- **flutter_carplay setup**: The package README warns installation "MAY BE DIFFICULT".
  Key setup steps: (1) `FlutterEngineCache` must be populated before `CarAppService`
  starts, (2) `automotive_app_desc.xml` in `android/app/src/main/res/xml/`,
  (3) manifest `<service>` with `com.google.android.gms.car.application` category.
  The implementer must follow the package's example app exactly for these files.
- **ListTemplate row limit**: Android Auto limits template content (max ~5 templates
  on screen stack). Each attraction row + Navigate button must fit within one
  ListTemplate. If the timeline has many attractions, the list scrolls natively
  (host manages scrolling).
- **Dateless trips**: `TimelineService.computeTimeline()` throws `StateError` if the
  trip has no dates (`timeline_service.dart:19-20`). The AA callback MUST guard against
  this — check `trip.startDate == null || trip.endDate == null` before calling
  `computeTimeline()`, and show a Message template "Add trip dates in the app to see
  your plan" + "Open app" Action. Same pattern as `trip_detail_screen.dart:57-58`.

## Phase 1: Schema migration — `isActive` column

### Overview

Add `isActive` boolean column to the `Trips` table. Default `false`. Bump schema
version to v6. Update DAO to read and write the column.

### Changes Required:

#### 1. Add `isActive` column to Trips table

**File**: `lib/database/tables.dart`

**Intent**: Add a boolean column to `Trips` so the user can mark one trip as "active" —
the trip Android Auto shows by default when multiple trips overlap dates.

**Contract**:
- New column: `BoolColumn get isActive => boolean().withDefault(const Constant(false))()`
- Added to `Trips` class

#### 2. Bump schema version and add migration

**File**: `lib/database/app_database.dart`

**Intent**: Register migration from v5 to v6 that adds the `isActive` column via
`ALTER TABLE trips ADD COLUMN isActive INTEGER NOT NULL DEFAULT 0`.

**Contract**:
- Schema version: 5 → 6
- Migration callback: `if (from < 6) { await m.addColumn(db.trips, db.trips.isActive); }`
  (Drift's `addColumn` helper generates the correct ALTER TABLE)

#### 3. Update TripDao

**File**: `lib/database/daos/trip_dao.dart`

**Intent**: Add `isActive` parameter to `createTrip()` and `updateTrip()` so the
column can be written.

**Contract**:
- `createTrip()`: add `{bool isActive = false}` parameter; pass to `TripsCompanion.insert`
- `updateTrip()`: add `{bool? isActive}` parameter; pass `Value.absentIfNull(isActive)` to `TripsCompanion`
- DAO generation: run `dart run build_runner build` after schema change

#### 4. Add listTripsCoveringDate query method

**File**: `lib/database/daos/trip_dao.dart`

**Intent**: Add a new query method so `TripSelectionService` can efficiently find
trips whose date range covers a given day, optionally filtered by `isActive`.

**Contract**:
- `Future<List<Trip>> listTripsCoveringDate(DateTime date, {bool? isActive})`
- Uses Drift `where` expression: `t.startDate.isNotBiggerThanValue(date) & t.endDate.isNotSmallerThanValue(date)`, with optional `t.isActive.equals(isActive)`
- Results ordered by `updatedAt DESC`
- Fallback: if no Drift expression works for date comparison, load `listAllTrips()` and filter in Dart (acceptable at current scale of <50 trips)

#### 5. Regenerate generated files

**File**: `lib/database/app_database.g.dart`, `lib/database/daos/trip_dao.g.dart`

**Intent**: Re-run build_runner to regenerate Drift code from updated schema.

**Contract**: `dart run build_runner build`

### Success Criteria:

#### Automated Verification:

- `dart run build_runner build` succeeds
- `flutter analyze` passes
- `flutter test` — all 77 existing tests pass (migration applies cleanly in test DBs)
- New DAO test: `createTrip(isActive: true)` → read back → `isActive == true`
- New DAO test: `updateTrip(isActive: true)` → read back → `isActive == true`
- New DAO test: `listTripsCoveringDate` with date filter + isActive filter → correct results
- Migration test: v4 DB (without isActive) → open → column exists with default `false`

#### Manual Verification:

- App opens without migration error on existing install
- New trip created → isActive defaults to false
- Edit trip → can toggle isActive

---

## Phase 2: Trip selection logic

### Overview

Create a `TripSelectionService` that resolves which trip Android Auto should display.
The logic: active trip covering today → last-opened trip → null (trigger trip list).

### Changes Required:

#### 1. TripSelectionService

**File**: `lib/services/trip_selection_service.dart` (new)

**Intent**: Encapsulate the 3-level trip selection logic so it's testable independently
of Android Auto.

**Contract**:
- `static Future<Trip?> resolveForAndroidAuto(TripDao tripDao)` — returns the trip to display
  1. Query trips where `startDate <= today <= endDate` and `isActive = true`, order by `updatedAt DESC`, take first
  2. If none, query all trips ordered by `updatedAt DESC`, take first
  3. If still none, return null
- `static Future<List<Trip>> listForSelection(TripDao tripDao)` — returns all trips for the fallback list screen

#### 2. Unit tests

**File**: `test/services/trip_selection_service_test.dart` (new)

**Intent**: Verify the 3-level fallback logic with different DB states.

**Contract**:
- Test: active trip with today's dates → returned first
- Test: no active trip, fallback to last-opened (updatedAt)
- Test: no trips at all → returns null
- Test: multiple active trips → first by updatedAt
- Test: active trip but dates don't cover today → skipped, fallback to last-opened
- Test: trip without dates → not considered for "today" check, falls to last-opened

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter test test/services/trip_selection_service_test.dart` — 6 new tests pass
- All existing 77 tests still pass

#### Manual Verification:

- Set up 3 trips: one active covering today, one active covering other dates, one inactive
- Verify the right trip is selected

---

## Phase 3: Android Auto integration

### Overview

Add `flutter_carplay` dependency, register the `CarAppService`, and build a `ListTemplate`
screen that displays today's timeline attractions.

### Changes Required:

#### 1. Add flutter_carplay dependency

**File**: `pubspec.yaml`

**Intent**: Add the only maintained Flutter Android Auto package.

**Contract**:
```yaml
dependencies:
  flutter_carplay: ^1.6.4
```

#### 2. Configure Android manifest and resources

**File**: `android/app/src/main/AndroidManifest.xml`

**Intent**: Register the CarAppService so Android Auto discovers the app.

**Contract**:
- Add `<uses-permission android:name="com.google.android.gms.permission.CAR_SPEED"/>` (if needed by template)
- Add `<meta-data android:name="com.google.android.gms.car.application" android:resource="@xml/automotive_app_desc"/>` inside `<application>`
- Add `<service>` for `CarAppService` with `com.google.android.gms.car.application` category intent filter

#### 3. Create automotive_app_desc.xml

**File**: `android/app/src/main/res/xml/automotive_app_desc.xml` (new)

**Intent**: Declare Android Auto capabilities (template types used).

**Contract**: Standard flutter_carplay descriptor listing supported templates (List, Pane, Alert).

#### 4. Create AndroidAutoScreen (Flutter side)

**File**: `lib/services/android_auto_service.dart` (new)

**Intent**: Build the ListTemplate from today's timeline data and push it to the
Android Auto host via flutter_carplay.

**Contract**:
- `static Future<void> showTodayPlan(TimelineDay today)` — builds a ListTemplate with one row per attraction
- Each row: `⭐` (if must-have) + name + ` · ` + `startTime` + ` · ← N min` (if travelFromPrevMin)
  + "Navigate" `Action` (opens Google Maps via `url_launcher` with `?q=lat,lng`)
- Row without coordinates: hide Navigate button
- If `today` is null or has no slots: show Pane/Message template with "No attractions planned for today" + Action "Open app"
- Reuse `_openInMaps()` pattern from `map_picker_screen.dart:122-140`

#### 5. Wire CarAppService initialization

**File**: `lib/main.dart`

**Intent**: Initialize `FlutterEngineCache` and register the Android Auto entry point
before `runApp()`, so the host can find the Flutter engine when AA connects.

**Contract**:
- Call `FlutterEngineCache` setup per flutter_carplay README instructions
- Register the AA callback that calls `TripSelectionService.resolveForAndroidAuto()` →
  guard against null dates (see Critical Implementation Details) →
  `TimelineService.computeTimeline()` → filter today → `showTodayPlan()`

#### 6. Trip list fallback screen

**File**: `lib/services/android_auto_service.dart`

**Intent**: When no trip is selected (no active trip for today, no last-opened trip),
show a list of all trips so the user can pick one from the car dashboard.
Implements the third fallback level from `TripSelectionService`.

**Contract**:
- `static Future<void> showTripList(List<Trip> trips)` — builds a ListTemplate with one row per trip (trip name + destination + dates)
- Each row is tappable → loads that trip's today plan via `showTodayPlan()`
- If `trips` is empty: show Message template "No trips yet" + Action "Open app"

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter pub get` + `flutter build apk --debug` succeeds
- Unit tests for `showTodayPlan` template building (mock data → verify template structure)
- Unit tests for `showTripList` template building (mock data → verify rows, tap action)
- All existing 77 tests still pass (AA is opt-in, doesn't break existing flows)

#### Manual Verification:

- [Requires Android 9+ phone with Android Auto + DHU or real car]
- Connect phone to car/DHU → TravelJug appears in Android Auto launcher
- Active trip with today's date → plan shows as list
- Navigate button → opens Google Maps with coordinates
- Attraction without coordinates → Navigate button hidden
- No trip → "No trips yet" message with "Open app" action
- Phone disconnected from AA → app works normally

---

## Phase 4: `isActive` toggle in phone UI

### Overview

Add a toggle in the trip detail screen (and optionally the edit dialog) to mark a
trip as active. This gives the user explicit control over which trip Android Auto shows.

### Changes Required:

#### 1. isActive toggle in TripDetailScreen

**File**: `lib/screens/trip_detail_screen.dart`

**Intent**: Add a switch/toggle in the trip detail header or AppBar that sets
`isActive` on the current trip.

**Contract**:
- In `_TripDetailScreenState`: add a Switch or Checkbox widget in the info card
  (next to destination/date display) with label "Active trip" or "Show in car"
- `onChanged`: `TripDao(db).updateTrip(trip.id, isActive: value)` + `_loadTimeline()`
- Toggle visible only when trip has dates (inactive trip without dates is meaningless
  for AA)

#### 2. isActive toggle in edit trip dialog

**File**: `lib/widgets/edit_trip_dialog.dart`

**Intent**: Add isActive as a field in the edit dialog so it can be changed during
trip editing.

**Contract**:
- Add `bool isActive` to `EditTripResult`
- Add `CheckboxListTile` or `SwitchListTile` in the dialog form
- Wire through `updateTrip(isActive: result.isActive)` in callers

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- All existing tests pass
- New widget test: toggling isActive calls updateTrip with correct value

#### Manual Verification:

- Open trip detail → toggle isActive on → verify in DB
- Edit trip dialog → toggle isActive → save → verify
- Only one trip active at a time (or multiple — per current logic, latest updatedAt wins)

---

## Testing Strategy

### Unit Tests:

- `TripSelectionService`: 6 tests covering all fallback scenarios
- `AndroidAutoService`: template building with mock TimelineDay → verify row count, text content, Navigate action presence/absence
- DAO: createTrip/updateTrip with isActive

### Widget Tests:

- isActive toggle in TripDetailScreen: toggle calls DAO correctly

### Integration Tests:

- Full pipeline: create trip with attractions → compute timeline → build AA template → verify structure

### Manual Testing Steps:

1. Install app on Android 9+ phone → connect to DHU → verify AA launcher shows TravelJug
2. Create trip with today's date + 3 attractions (one with coordinates, one without, one must-have)
3. Start car → verify list shows: ⭐, Navigate button on first, no button on second
4. Click Navigate → verify Google Maps opens with correct pin
5. No trip for today → verify "No attractions planned" message
6. No trips at all → verify "No trips yet" message
7. Disconnect phone → verify app works normally

## Performance Considerations

- Timeline computation is O(n) — no impact (already runs on phone)
- flutter_carplay template serialization is lightweight (model objects → Binder)
- No network calls — all data from local SQLite
- No background services — AA only active when phone connected to car

## Migration Notes

- Schema v5 → v6: `ALTER TABLE trips ADD COLUMN isActive INTEGER NOT NULL DEFAULT 0`
  is backward-compatible — existing apps upgrade without data loss
- `flutter_carplay` is a new dependency — `flutter pub get` required
- Android manifest changes are additive — no impact on existing non-AA usage
- First AA install requires Internal App Sharing or Play Store review (Android Auto
  apps can't be sideloaded for production use)

## References

- flutter_carplay: https://pub.dev/packages/flutter_carplay
- flutter_carplay GitHub: https://github.com/oguzhnatly/flutter_carplay
- Android for Cars App Library: https://developer.android.com/training/cars/apps/library
- Desktop Head Unit: https://developer.android.com/training/cars/testing/dhu
- Existing intent pattern: `lib/screens/map_picker_screen.dart:122-140`
- PRD: `context/foundation/prd-v2.md`
- Roadmap: `context/foundation/roadmap.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Schema migration — isActive column

#### Automated

- [x] 1.1 `dart run build_runner build` succeeds — 4b8fd99
- [x] 1.2 `flutter analyze` passes — 4b8fd99
- [x] 1.3 `flutter test` — all existing tests pass — 4b8fd99
- [x] 1.4 New DAO test: createTrip(isActive: true) roundtrip — 4b8fd99
- [x] 1.5 New DAO test: updateTrip(isActive: true) roundtrip — 4b8fd99
- [x] 1.6 New DAO test: listTripsCoveringDate filters correctly — 4b8fd99

#### Manual

- [x] 1.7 App opens without migration error on existing install — 4b8fd99

### Phase 2: Trip selection logic

#### Automated

- [x] 2.1 `flutter analyze` passes — d7b9426
- [x] 2.2 6 unit tests for TripSelectionService pass — d7b9426
- [x] 2.3 All existing tests still pass — d7b9426

#### Manual

- [x] 2.4 Verify trip selection with 3 trips (active, inactive, other dates) — d7b9426

### Phase 3: Android Auto integration

#### Automated

- [x] 3.1 `flutter pub get` + `flutter build apk --debug` succeeds
- [x] 3.2 `flutter analyze` passes
- [x] 3.3 Unit tests for showTodayPlan template building pass
- [x] 3.4 Unit tests for showTripList template building pass
- [x] 3.5 All existing tests still pass

#### Manual

- [ ] 3.6 App appears in Android Auto launcher (phone + car/DHU)
- [ ] 3.7 Today's plan shows as list with name + time + travel gap
- [ ] 3.8 Trip list fallback shows all trips when no active trip
- [ ] 3.9 Navigate button opens Google Maps with coordinates
- [ ] 3.10 Attraction without coordinates — Navigate hidden
- [ ] 3.11 No trip / no attractions — message + Open app action
- [ ] 3.12 Phone disconnected — app works normally

### Phase 4: isActive toggle in UI

#### Automated

- [x] 4.1 `flutter analyze` passes — efbc5c3
- [x] 4.2 Widget test: toggle calls updateTrip — efbc5c3
- [x] 4.3 All existing tests still pass — efbc5c3

#### Manual

- [x] 4.4 Toggle in trip detail → saves correctly — efbc5c3
- [x] 4.5 Toggle in edit dialog → saves correctly — efbc5c3
