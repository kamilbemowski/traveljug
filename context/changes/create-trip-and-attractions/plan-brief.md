# S-01: Create Trip and Add Attractions — Plan Brief

> Full plan: `context/changes/create-trip-and-attractions/plan.md`

## What & Why

Uzytkownik nie moze jeszcze nic zrobic — apka pokazuje "Hello World". S-01 to pierwszy widoczny feature: tworzenie tripa, lista tripow, dodawanie atrakcji. Bez tego S-02 (timeline) nie ma na czym operowac. To setup slice — najwazniejszy jest scope-discipline: tylko pola ktorych potrzebuje S-02.

## Starting Point

TripDao + AttractionDao z pelnym CRUD (F-01). `getDatabase()` singleton w main.dart. `lib/main.dart` z Hello World — zero ekranow, zero widgetow, zero nawigacji.

## Desired End State

Apka otwiera sie na liscie tripow (najnowsze pierwsze). FAB otwiera formularz tworzenia tripa. Po zapisaniu trip pojawia sie na liscie. Tap na trip → ekran detailu z lista atrakcji. Przycisk "Add attraction" otwiera dialog do dodania atrakcji.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| State management | Direct getDatabase() calls | Juz dziala, zero dodatkowych zaleznosci. MVP nie potrzebuje Provider. | Plan |
| Navigation | Navigator.push | Proste, zero boilerplate, wystarczajace dla 3 ekranow. | Plan |
| Screens | TripList + CreateTrip + TripDetail | Naturalny split — lista, tworzenie, detail. | Plan |
| Priority labels | Must-have / Nice-to-have / Optional | Mapa na DB: 0/1/2. Mozna zmieniac etykiety bez migracji. | Plan |
| Validation | Form + GlobalKey<FormState> | Standardowe Flutter form validation — name i destination wymagane. | Plan |
| Testing | Widget tests | TripListScreen testowany z in-memory drift DB. | Plan |
| Scope | Full S-01 (trips + attractions) | Atrakcje sa integralna czescia tripa — nie ma sensu rozdzielac. | Plan |

## Scope

**In scope:** TripListScreen, CreateTripScreen (form z walidacja), TripDetailScreen, AddAttractionDialog, widget test TripListScreen, wire into main.dart.

**Out of scope:** Trip editing/deletion, attraction editing, search in trip list, timeline generation (S-02), state management library.

## Architecture / Approach

```
lib/screens/
  trip_list_screen.dart      → TripListScreen (home)
  create_trip_screen.dart    → CreateTripScreen (form)
  trip_detail_screen.dart    → TripDetailScreen + _AddAttractionDialog

Kazdy ekran: StatefulWidget → getDatabase() → DAO → setState()
Nawigacja: Navigator.push / Navigator.pop(true)
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Trip list | TripListScreen + empty state + FAB, wired in MainApp | None — standard ListView |
| 2. Create trip | Formularz z walidacja, zapis do DB, refresh listy | Form state management across async gap |
| 3. Detail + attraction | TripDetailScreen + AddAttractionDialog | Position calculation for new attractions |
| 4. Widget tests | Widget test dla TripListScreen na in-memory DB | In-memory DB setup for widget tests |

**Prerequisites:** F-01 (data-schema) implemented ✅
**Estimated effort:** ~2-3 sesje — 4 fazy, pierwsze UI w projekcie.
