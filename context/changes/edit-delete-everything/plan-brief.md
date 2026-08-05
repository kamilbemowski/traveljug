# S-07: Edit & Delete Everything — Plan Brief

> Full plan: `context/changes/edit-delete-everything/plan.md`

## What & Why

DAO wspiera pełny CRUD od MVP, ale UI nigdy nie wystawiło edycji i usuwania tripa/atrakcji. S-07 zamyka tę lukę: dialogi edycji dla tripa i atrakcji (tap → edit → save), potwierdzenie usuwania (dialog), reset override'ów dla dnia. Zero nowych zależności, zero zmian w schemie — czysty UI.

## Starting Point

`TripDao.updateTrip()` i `AttractionDao.updateAttraction()` istnieją ale nie są nigdzie wołane z UI. `TripDao.deleteTrip()` też nie. Wzorce dialogów edycji (`_AddAttractionDialog`) i potwierdzenia usuwania (`_handleDelete`) już istnieją. Try/catch + SnackBar dla błędów też.

## Desired End State

User klika na trip → dialog edycji → zmienia nazwę/daty/pace → save. User klika na atrakcję → dialog edycji → zmienia czas/kategorię → save. User długo przytrzymuje trip/liste → delete z potwierdzeniem. User resetuje dzień → wraca do oryginalnego planu.

## Key Decisions Made

| Decision | Choice | Why | Source |
|---|---|---|---|
| Edit trip | Dialog, nie osobny ekran | Prościej, spójne z _AddAttractionDialog | Plan |
| Edit attraction | Dialog z tap na slot | Timeline już ma interakcje — edit to brakujący kawałek | Plan |
| Delete UX | Dialog potwierdzenia, nie SnackBar | Spójne z istniejącym _handleDelete | Plan |
| Pattern | Reuse try/catch + SnackBar | Pattern z M3L5 review fixes już w kodzie | Plan |

## Scope

**In scope:** Trip edit (name, destination, dates, pace, travelContext), trip delete, attraction edit (name, duration, category, priority), attraction delete, reset overrides

**Out of scope:** Inline editing, undo, bulk operations, new data model, schema changes

## Architecture / Approach

```
TripListScreen         → edit dialog (UpdateTripDialog) → TripDao.updateTrip()
  long-press           → confirm dialog → TripDao.deleteTrip()

TripDetailScreen       → AppBar edit icon → same dialog → updateTrip()
  AppBar delete icon   → confirm → deleteTrip() → pop to list

_DaySection / _SlotTile → tap slot → edit dialog → AttractionDao.updateAttraction()
  delete button        → confirm (existing) → AttractionDao.deleteAttraction()
  reset button         → confirm → deleteOverride() per slot → reload
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Trip edit + delete | Edit dialog, delete from list/detail, wire updateTrip/deleteTrip | None — pure UI |
| 2. Attraction edit | Edit dialog on timeline slot, wire updateAttraction | None — existing patterns |
| 3. Reset overrides | Reset day button, wire deleteOverride per slot | None — nice-to-have |

**Prerequisites:** None (DAO already complete)
**Estimated effort:** ~1-2 evenings, 3 phases
