# S-08: Map Search — Plan Brief

> Full plan: `context/changes/map-search/plan.md`
> Research: `context/changes/map-search/research.md`

## What & Why

TravelJug ma map picker (S-06), ale nie da się w nim wyszukać miejsca po nazwie — tylko tapnięcie na mapie. Użytkownik musi znać współrzędne albo ręcznie znaleźć miejsce. S-08 dodaje wyszukiwanie geocodingowe: wpisujesz "wieża eiffla", dostajesz wyniki, klikasz → pinezka na mapie.

## Starting Point

`MapPickerScreen` (152 linie) — pełnoekranowa mapa Google z tap-to-place i 5-sekundowym timeout fallbackiem do ręcznego wpisywania współrzędnych. `google_maps_flutter` już w projekcie. Brakuje pola wyszukiwania i warstwy geocodingu.

## Desired End State

MapPickerScreen ma pole wyszukiwania nad mapą. Użytkownik wpisuje ≥3 znaki, po 300ms debounce apka szuka miejsc przez natywny geocoder Androida. Wyniki pokazują się jako overlay dropdown. Tap na wynik przesuwa mapę i stawia pinezkę. Wyniki cache'owane w pamięci na czas sesji. Gdy geocoder niedostępny — komunikat inline i sugestia ręcznego wpisania współrzędnych.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Geocoding provider | Flutter Geocoding (Baseflow) | Darmowy, bez API key, używa natywnego geocodera Androida przez Play Services | Research |
| Search UX | Debounce 300ms | Balans między responsywnością a liczbą wywołań | Plan |
| Results display | Overlay dropdown nad mapą | Kompaktowe, mapa zostaje na ekranie — jak Google Maps | Plan |
| Cache | In-memory per session (Map) | Szybkie powtórne wyszukiwania, zero złożoności | Plan |
| Error handling | Komunikaty inline pod polem wyszukiwania | Widoczne bez zasłaniania mapy SnackBarem | Plan |
| Min query length | 3 znaki | Eliminuje szum przy 1-2 znakach, sensowny próg | Plan |
| Testing | Widget testy z mockowanym geocoderem | Sprawdza UI + interakcje bez zależności od Play Services | Plan |

## Scope

**In scope:**
- Pole wyszukiwania z debounce 300ms w MapPickerScreen
- Overlay z wynikami (max 5 widocznych, scrollowalne)
- Geocoding przez `geocoding` package (darmowy, natywny Android)
- In-memory cache na sesję (max 50 wpisów)
- Komunikaty inline dla błędów: brak geocodera, brak wyników, błąd sieci
- `Geocoder.isPresent()` check przed wywołaniem
- Search bar ukryty w fallback mode (timeout)

**Out of scope:**
- Reverse geocoding (współrzędne → adres)
- Persistent cache (SQLite)
- Autocomplete / sugestie w trakcie pisania
- Oddzielny ekran wyszukiwania
- Google Geocoding API ani OSM Nominatim
- Zmiany w `_AddAttractionDialog` lub innych ekranach

## Architecture / Approach

```
MapPickerScreen (zmodyfikowany)
├── AppBar: "Pick Location" + Confirm
├── Stack
│   ├── GoogleMap (istniejący)
│   ├── Positioned(top) → SearchField (NOWY)
│   │   ├── TextField z onChanged + Timer(300ms)
│   │   └── Text(error) gdy błąd
│   └── Positioned(top, below search) → ResultsOverlay (NOWY)
│       └── Card > ListView > ListTile × N
│           └── onTap → animateCamera + setState(_position)
└── FallbackView (istniejący, bez zmian)
```

Nowy pakiet: `geocoding: ^4.0.0` (pub.dev, Baseflow, High reputation)

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Geocoding search in MapPickerScreen | Search bar + results overlay + cache + error handling | Geocoder `isPresent()` false na urządzeniu bez Play Services |

**Prerequisites:** — (S-06 map picker exists, `google_maps_flutter` already in project)
**Estimated effort:** ~1 sesja, jedna faza
