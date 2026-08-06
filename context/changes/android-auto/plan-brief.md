# Android Auto — Plan Brief

> Full plan: `context/changes/android-auto/plan.md`

## What & Why

Użytkownik wsiada do auta, odpala Android Auto, i widzi dzisiejszy plan podróży — listę
atrakcji z godzinami i czasem przejazdu. Może kliknąć "Naviguj" przy dowolnej atrakcji
aby otworzyć Google Maps z koordynatami. Nie musi odpalać telefonu podczas jazdy.

To jest pierwszy krok w kierunku "apka pomaga w podróży, nie tylko przed nią".
GPS proximity notifications (S-10) są planowane jako osobny slice — powiadomienia
"jesteś blisko atrakcji" działające niezależnie od Android Auto.

## Starting Point

- Apka ma w pełni działający timeline engine, Drift SQLite, model `TimelineDay`/`TimelineSlot`
- Wszystkie dane do wyświetlenia są lokalnie w bazie — apka jest local-first
- `flutter_carplay` (MIT, 304★, aktywny 2026) jest jedynym utrzymywanym pakietem Flutter
  do Android Auto — wspiera ListTemplate, Grid, Pane, Alert (bez map/nawigacji)
- Android Auto renderuje UI na głownej jednostce samochodu — apka wysyła szablony (modele),
  host je wyświetla. Flutter nie może rysować bezpośrednio na ekranie auta

## Desired End State

Użytkownik wsiada do auta, na ekranie Android Auto widzi listę dzisiejszych atrakcji
(posortowaną wg timeline), z nazwą, godziną startu, czasem przejazdu i gwiazdką ⭐ dla
must-have. Przy każdej atrakcji jest przycisk "Naviguj" otwierający Google Maps.
Jeśli nie ma atrakcji na dziś, pokazuje komunikat z przyciskiem otwarcia apki.

Dodatkowo: w apce na telefonie użytkownik może oznaczyć trip jako "aktywny" (flaga `isActive`)
— to rozwiązuje wybór tripu gdy kilka tripów pokrywa się datami.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Architektura | flutter_carplay (tylko Flutter) | Najszybszy start, wystarcza dla listy + Action; zero kodu natywnego | Plan |
| Scope AA | Lista atrakcji na dziś + Naviguj | Minimalny, distraction-safe use-case dla kierowcy | Plan |
| Nawigacja | Intent do Google Maps z koordynatami | Identyczny pattern jak `_openInMaps()` w map_picker_screen | Plan |
| Wybór tripu | Aktywny trip → ostatni otwierany → lista | Jawne (isActive) + fallbacki bez dodatkowej interakcji w aucie | Plan |
| Flaga aktywności | Nowa kolumna `isActive` w tabeli Trips | Użytkownik jawnie kontroluje; migracja v4→v5 | Plan |
| Lista UI | Nazwa + godzina + czas przejazdu + ⭐ must-have | Pełna informacja mieszcząca się w ListTemplate | Plan |
| Offline | Dane lokalne, przycisk Naviguj szarzeje bez sieci | Apka już jest local-first — nic nowego | Plan |
| GPS notifications | Wydzielone do S-10 | Niezależna funkcja działająca poza autem | Plan |
| Testowanie | Testy jednostkowe logiki + manualne w aucie | DHU wymaga fizycznego telefonu; testujemy logikę w CI | Plan |
| Opcjonalność | AA to dodatkowy feature, nie wymóg | Apka działa normalnie bez AA; CarAppService tylko gdy połączono | Plan |

## Scope

**In scope:**
- Migracja schemy: kolumna `isActive` w `Trips`
- Trip selection logic z 3 poziomami fallbacku
- Android Auto CarAppService przez flutter_carplay
- ListTemplate z dzisiejszym planem dnia
- Przycisk "Naviguj" otwierający Google Maps z koordynatami
- Edge case: komunikat gdy brak atrakcji na dziś
- Toggle "Active trip" w UI apki (trip detail)

**Out of scope:**
- GPS proximity notifications → S-10
- Nawigacja turn-by-turn / NavigationTemplate
- Mapy w Android Auto
- Android Automotive OS (wbudowany system auta, nie projekcja)
- iOS / CarPlay (flutter_carplay wspiera, ale nie w scope tego slice'a)
- Offline mapy
- Edycja danych przez Android Auto (tylko odczyt)

## Architecture / Approach

```
┌──────────────────────────────────────────────────┐
│ Phone App (Flutter)                              │
│ ┌──────────────┐  ┌────────────────────────────┐ │
│ │ TripDetail   │  │ AndroidAutoService (nowy)  │ │
│ │ + isActive   │  │ - resolveTrip()            │ │
│ │   toggle     │  │ - buildTodayListTemplate()  │ │
│ └──────┬───────┘  └──────────┬─────────────────┘ │
│        │                     │                    │
│ ┌──────┴─────────────────────┴──────────────────┐ │
│ │  TripDao / AttractionDao / TimelineService    │ │
│ │  (istniejące — bez zmian)                     │ │
│ └───────────────────────┬───────────────────────┘ │
│                         │                          │
│ ┌───────────────────────┴───────────────────────┐ │
│ │  AppDatabase (Drift SQLite)                   │ │
│ │  Trips + isActive (v4→v5)                     │ │
│ └───────────────────────────────────────────────┘ │
└──────────────────────┬───────────────────────────┘
                       │ flutter_carplay
                       │ (template serialization)
                       ▼
┌──────────────────────────────────────────────────┐
│ Car Head Unit (Android Auto host)                │
│ ┌──────────────────────────────────────────────┐ │
│ │ ListTemplate                                 │ │
│ │ ★ Luwr · 10:00 · ← 15 min    [Naviguj]      │ │
│ │   Wieża Eiffla · 12:30 · ← 30 min [Naviguj] │ │
│ └──────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────┘
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Schema: isActive | Kolumna + migracja + DAO update | Migracja musi być backward-compatible |
| 2. Trip selection logic | Serwis wybierający trip dla AA | Logika fallbacku: aktywny → ostatni → lista |
| 3. Android Auto integration | CarAppService + ListTemplate przez flutter_carplay | flutter_carplay setup może być trudny (ostrzega README) |
| 4. isActive toggle in UI | Toggle w trip detail + trip list | Prosty UI — najmniejsze ryzyko |

**Prerequisites:** Android 9+ telefon do testów manualnych (DHU)
**Estimated effort:** ~2-3 sesje across 4 fazy
**Independence:** Phases 1-2 (isActive column + TripSelectionService) are independent of
`flutter_carplay` — they can be implemented, tested in CI, and merged as standalone pre-work.
Only Phase 3 requires the AA dependency.

## Open Risks & Assumptions

- flutter_carplay ListTemplate "limited support" może nie pomieścić wszystkich pól (nazwa+godzina+przejazd+gwiazdka+przycisk) — może trzeba ograniczyć dane
- DHU wymaga fizycznego telefonu — nie ma emulatora samego AA bez telefonu
- Android Auto deployment wymaga Play Store review — może wymagać Internal App Sharing do testów
- Założenie: `url_launcher` działa z poziomu Android Auto Action (do weryfikacji)

## Success Criteria (Summary)

- Użytkownik widzi dzisiejszy plan w Android Auto jako listę z nazwą, godziną, czasem przejazdu
- Kliknięcie "Naviguj" otwiera Google Maps z koordynatami atrakcji
- Apka działa normalnie gdy Android Auto nie jest podłączone
- Gdy nie ma atrakcji na dziś, AA pokazuje komunikat zamiast pustej listy
