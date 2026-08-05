# S-07: Edit & Delete Everything — Implementation Plan

## Overview

Expose existing DAO CRUD capabilities in the UI. Add edit dialogs for trips and attractions, delete with confirmation dialogs, and reset-overrides for a day. Pure UI — no schema changes, no new DAO methods, no algorithm changes. 5 FRs from PRD v2.

## Current State Analysis

- `TripDao.createTrip()`, `updateTrip()`, `deleteTrip()` exist and work — but only `createTrip()` is wired to UI (`CreateTripScreen`). Update and delete have no UI.
- `AttractionDao.createAttraction()`, `updateAttraction()`, `deleteAttraction()` exist — create wired to `_AddAttractionDialog`, delete wired to `_handleDelete` in timeline, update has NO UI.
- `TimelineOverrideDao.upsertOverride()`, `deleteOverride()` exist — wired to reorder/move handlers in `trip_detail_screen.dart:73-111`.
- Delete confirmation pattern already exists in `_handleDelete` at `trip_detail_screen.dart:92-101` — `showDialog<bool>` with Cancel/Remove buttons.
- Edit dialog pattern exists in `_AddAttractionDialog` (lines 413-481) — `AlertDialog` with `Form` + `TextFormField`s + `DropdownButtonFormField`s.
- Trip list screen (`trip_list_screen.dart`) shows trips as `ListTile`s — tap navigates to detail.
- Error handling pattern: try/catch + SnackBar (established in M3L5 review fixes).

### Key Discoveries:

- `lib/screens/trip_detail_screen.dart:90-112` — `_handleDelete()` is the reference delete confirmation pattern.
- `lib/screens/trip_detail_screen.dart:413-481` — `_AddAttractionDialog` is the reference edit dialog pattern.
- `lib/screens/trip_list_screen.dart` — trip list, each tile has `onTap` to detail. No edit/delete triggers.
- `lib/database/daos/trip_dao.dart:45-66` — `updateTrip()` signature: `(int id, {String? name, String? destination, DateTime? startDate, DateTime? endDate, TravelPace? pace, TravelContext? travelContext, String? imageUrl})`
- `lib/database/daos/attraction_dao.dart:47-56` — `updateAttraction()` signature: `(int id, {String? name, AttractionCategory? category, int? durationMin, int? priority, int? position, int? tripId, double? latitude, double? longitude})`

## Desired End State

User can tap a trip card → open edit dialog, change any field, save. User can long-press a trip → delete with confirmation. User can tap an attraction slot on the timeline → open edit dialog, change name/duration/category/priority, save. User can tap delete on a slot → confirmation → delete. User can reset all overrides for a day ("give me back the original plan").

## What We're NOT Doing

- No inline editing — all edits through dialogs (consistent pattern, less crowded UI).
- No undo — delete is confirmation dialog only (consistent with existing pattern).
- No bulk operations (delete multiple trips at once, reset all days at once).
- No edit history or versioning.
- No changes to the timeline computation logic.

## Implementation Approach

Three phases, dependency-ordered: trips first (the parent entity), then attractions (depend on trips), then overrides (depend on attractions). Each phase reuses the existing dialog and error-handling patterns already established in the codebase. No new dependencies, no schema changes, no DAO changes — all DAO methods already exist and are tested.

---

## Phase 1: Trip edit + delete from list and detail

### Overview

Add edit dialog for trip fields. Add delete button with confirmation to trip list (long-press) and trip detail (app bar action). Wire existing `updateTrip()` and `deleteTrip()` DAO methods.

### Changes Required:

#### 1. Edit trip dialog

**File**: `lib/screens/trip_list_screen.dart`

**Intent**: Add an `_editTrip(Trip trip)` method that shows an edit dialog matching the create-trip form pattern. On save, calls `TripDao.updateTrip()` and refreshes the list.

**Contract**:
- New `Future<void> _editTrip(Trip trip)` method in `_TripListScreenState`.
- Dialog with `TextFormField`s for name, destination; date picker row for start/end dates; `DropdownButtonFormField` for pace and travelContext.
- On save: `tripDao.updateTrip(trip.id, name: ..., destination: ..., startDate: ..., endDate: ..., pace: ..., travelContext: ...)` inside try/catch + SnackBar error handler.
- Refresh `_loadTrips()` after successful save.

#### 2. Delete trip from list

**File**: `lib/screens/trip_list_screen.dart`

**Intent**: Long-press on a trip tile shows delete confirmation dialog. Confirmed → `tripDao.deleteTrip()` → refresh list.

**Contract**:
- Wrap each `ListTile` with `onLongPress` handler.
- Confirmation dialog reuses the `showDialog<bool>` pattern from `trip_detail_screen.dart:92-101`.
- On confirm: `tripDao.deleteTrip(trip.id)` inside try/catch + SnackBar, then `_loadTrips()`.

#### 3. Edit trip button on detail screen

**File**: `lib/screens/trip_detail_screen.dart`

**Intent**: Add an edit icon in the AppBar that opens the same edit dialog. Reuses the edit dialog pattern from Change 1.

**Contract**:
- Add `IconButton(icon: Icon(Icons.edit))` to AppBar actions.
- Open the same edit dialog (consider extracting to a shared `_EditTripDialog` widget or duplicating inline — both acceptable for MVP; duplication is cheaper given this is 2 call sites).

#### 4. Delete trip button on detail screen

**File**: `lib/screens/trip_detail_screen.dart`

**Intent**: Add a delete icon in the AppBar that shows confirmation and deletes the trip, navigating back to list.

**Contract**:
- Add `IconButton(icon: Icon(Icons.delete, color: Colors.red))` to AppBar actions.
- Confirmation dialog, then `tripDao.deleteTrip(trip.id)`.
- On success: `Navigator.pop(context, true)` to return to trip list, which reloads on pop.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter test` — all 66 existing tests pass (no DAO changes, backward compatible)
- New widget tests: delete from list triggers confirmation dialog

#### Manual Verification:

- Tap trip card → edit dialog opens → change name → save → list updates
- Long-press trip → delete confirmation → confirm → trip removed from list
- Open trip detail → tap edit icon → change pace → save → detail updates
- Delete confirmation: Cancel → trip stays. Confirm → trip deleted, back to list.

---

## Phase 2: Attraction edit + delete from timeline

### Overview

Add edit dialog for attraction fields (tap slot → edit dialog). Delete is already wired (`_handleDelete`) — phase only needs to wire the edit trigger. Tap on a slot → either move-day (arrow buttons) OR edit (tap on the content area). The slot already has arrow buttons for move-day and close button for delete — add an edit icon or make the ListTile content area tappable for edit.

### Changes Required:

#### 1. Edit attraction dialog

**File**: `lib/screens/trip_detail_screen.dart` (_SlotTile or _DaySection)

**Intent**: Add an edit trigger on each timeline slot. Tap opens a dialog matching the add-attraction form, pre-filled with current values. On save, calls `AttractionDao.updateAttraction()` and reloads timeline.

**Contract**:
- Add `void Function(int slotIndex) onEdit` callback to `_DaySection` and `_SlotTile`.
- `_SlotTile.ListTile.onTap` → `() => onEdit(slotIndex)`.
- New `_handleEdit(int dayIndex, int slotIndex)` method in `_TripDetailScreenState`:
  - Get `slot = _timeline[dayIndex].slots[slotIndex]`.
  - Show edit dialog with pre-filled name, duration, category dropdown, priority dropdown.
  - On save: `attractionDao.updateAttraction(slot.attraction.id, name: ..., durationMin: ..., category: ..., priority: ...)` inside try/catch + SnackBar.
  - Reload timeline on success.
- Edit icon on `_SlotTile` trailing (alongside existing arrow and close buttons): `IconButton(icon: Icon(Icons.edit, size: 18), onPressed: () => onEdit(slotIndex))`.

#### 2. Delete attraction confirmation

**File**: `lib/screens/trip_detail_screen.dart` (_handleDelete, lines 90-112)

**Intent**: No change needed — `_handleDelete` already has confirmation dialog, try/catch, SnackBar, and timeline reload. This FR is already met.

**Contract**: (no change — existing implementation satisfies FR-004)

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter test` — all existing tests pass
- New widget tests: edit dialog opens with pre-filled values, save updates timeline

#### Manual Verification:

- Tap attraction slot → edit dialog opens → change duration → save → timeline updates
- Edit dialog Cancel → no change
- Delete attraction → confirmation dialog → Confirm → removed from timeline
- Verify FK cascade: delete trip → all attractions gone

---

## Phase 3: Reset overrides (nice-to-have)

### Overview

Add a "Reset day" button that removes all TimelineOverrides for a given day. User gets back the original computed plan for that day.

### Changes Required:

#### 1. Reset overrides button

**File**: `lib/screens/trip_detail_screen.dart` (_DaySection)

**Intent**: Add a "Reset" icon button in the day header row (next to the lock toggle). Calls `overrideDao.deleteOverride()` for each attraction in the day's slots, then reloads timeline.

**Contract**:
- Add `void Function() onReset` callback to `_DaySection`.
- `IconButton(icon: Icon(Icons.restore, size: 18), tooltip: 'Reset day', onPressed: _confirmReset)` in the day header row.
- Confirmation dialog before reset.
- `_handleResetDay(int dayIndex)` in `_TripDetailScreenState`:
  - For each slot in `_timeline[dayIndex].slots`, call `overrideDao.deleteOverride(slot.attraction.id)`.
  - Wrap in try/catch + SnackBar.
  - Reload timeline.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter test` — all existing tests pass

#### Manual Verification:

- Override some attractions (reorder) → tap Reset day → confirmation → plan returns to original
- Reset confirmation: Cancel → overrides stay

---

## Testing Strategy

### Unit Tests:

N/A — no new pure functions. All logic is UI integration over existing DAO.

### Widget Tests:

- Trip edit dialog: opens with pre-filled values, save calls updateTrip, list refreshes
- Trip delete from list: long-press shows confirmation, confirm calls deleteTrip
- Attraction edit dialog: pre-filled, save calls updateAttraction, timeline reloads
- Reset overrides: confirmation dialog shown, deleteOverride called per slot

### Manual Testing Steps:

1. Create trip → close app → reopen → edit trip name → verify persistence
2. Add 3 attractions → edit middle one → verify timeline unchanged for others
3. Delete trip with attractions → verify cascade (no orphan rows via app behavior)
4. Edit attraction with coordinates → verify coords preserved
5. Reset overrides after manual reorder → verify plan returns to computed state

## Performance Considerations

- Edit dialogs are lightweight AlertDialogs — no performance impact.
- `updateTrip()`/`updateAttraction()` are single-row SQLite updates — O(1).
- Timeline reload after edit is the same `_loadTimeline()` call already used after reorder/delete — no additional overhead.

## Migration Notes

No migration needed. Schema unchanged at v4. All DAO methods already exist and are tested.

## References

- PRD: `context/foundation/prd-v2.md` — S-07, FR-001–FR-005
- Roadmap: `context/foundation/roadmap.md` — S-07
- Shape notes: `context/foundation/shape-notes.md`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Trip edit + delete from list and detail

#### Automated

- [x] 1.1 `flutter analyze` passes — 35402e4
- [x] 1.2 `flutter test` — all existing tests pass — 35402e4
- [x] 1.3 Widget test: delete from list triggers confirmation dialog — 35402e4

#### Manual

- [ ] 1.4 Edit trip dialog opens, saves, list updates
- [ ] 1.5 Long-press delete with confirmation
- [ ] 1.6 Edit + delete from detail screen

### Phase 2: Attraction edit + delete from timeline

#### Automated

- [x] 2.1 `flutter analyze` passes
- [x] 2.2 `flutter test` — all existing tests pass
- [x] 2.3 Widget test: edit dialog opens with pre-filled values

#### Manual

- [ ] 2.4 Tap slot → edit dialog → save → timeline updates
- [ ] 2.5 Delete attraction with confirmation

### Phase 3: Reset overrides

#### Automated

- [x] 3.1 `flutter analyze` passes — 9ed9be1
- [x] 3.2 `flutter test` — all existing tests pass — 9ed9be1

#### Manual

- [ ] 3.3 Reset day removes overrides, plan returns to original
