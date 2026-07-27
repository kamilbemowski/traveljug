# S-03: Manual Plan Adjustments — Implementation Plan

## Phase 1: timeline_overrides table and DAO

### Success Criteria:

#### Automated Verification:

- `dart run build_runner build` succeeds
- `flutter analyze` passes
- `flutter test` — existing tests still pass after schema migration

#### Manual Verification:

- `TimelineOverrides` table in `tables.dart`
- `schemaVersion = 2` in `app_database.dart`
- `timeline_override_dao.dart` exists with CRUD

## Phase 2: Reapply overrides in timeline computation

### Success Criteria:

#### Automated Verification:

- `flutter test test/services/timeline_service_test.dart` — all tests pass
- `flutter analyze` passes

#### Manual Verification:

- Test output shows >= 6 override test cases passing

## Phase 3: Interactive timeline UI

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- Reorder by drag works
- Move to next/previous day works
- Delete with confirmation dialog works
- Overrides survive after adding new attraction

## Phase 4: Widget tests

### Success Criteria:

#### Automated Verification:

- `flutter test test/screens/trip_detail_screen_test.dart` — all widget tests pass
- `flutter test` — full suite passes

#### Manual Verification:

- Widget test output shows >= 4 interactive test cases passing

## Progress

### Phase 1: timeline_overrides table and DAO

#### Automated

- [x] 1.1 `dart run build_runner build` succeeds
- [x] 1.2 `flutter analyze` passes
- [x] 1.3 `flutter test` — existing tests still pass after schema migration

#### Manual

- [x] 1.4 `TimelineOverrides` table in `tables.dart`
- [x] 1.5 `schemaVersion = 2` in `app_database.dart`
- [x] 1.6 `timeline_override_dao.dart` exists with CRUD

### Phase 2: Reapply overrides in timeline computation

#### Automated

- [x] 2.1 `flutter test test/services/timeline_service_test.dart` — all tests pass
- [x] 2.2 `flutter analyze` passes

#### Manual

- [x] 2.3 Test output shows >= 6 override test cases passing

### Phase 3: Interactive timeline UI

#### Automated

- [x] 3.1 `flutter analyze` passes
- [x] 3.2 `flutter build apk --debug` compiles

#### Manual

- [ ] 3.3 Reorder by drag works
- [ ] 3.4 Move to next/previous day works
- [ ] 3.5 Delete with confirmation dialog works
- [ ] 3.6 Overrides survive after adding new attraction

### Phase 4: Widget tests

#### Automated

- [ ] 4.1 `flutter test test/screens/trip_detail_screen_test.dart` — all widget tests pass
- [ ] 4.2 `flutter test` — full suite passes

#### Manual

- [ ] 4.3 Widget test output shows >= 4 interactive test cases passing
