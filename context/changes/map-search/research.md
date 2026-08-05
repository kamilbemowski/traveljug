---
date: 2026-08-05T11:50:00+02:00
researcher: Claude
git_commit: 6e115f7bb197395e8ff6a66d114166cb257d6ac7
branch: develop
repository: kamilbemowski/traveljug
topic: "S-08 Map Search — geocoding provider selection & integration research"
tags: [research, s-08, map-search, geocoding, google-maps, nominatim, flutter-geocoding]
status: complete
last_updated: 2026-08-05
last_updated_by: Claude
---

# Research: S-08 Map Search — Geocoding Provider

**Date**: 2026-08-05 11:50 CEST
**Researcher**: Claude
**Git Commit**: 6e115f7
**Branch**: develop
**Repository**: kamilbemowski/traveljug

## Research Question

Który provider geocodingu wybrać dla S-08 (wyszukiwanie miejsc na mapie) i jak zintegrować go z istniejącym `MapPickerScreen`?

## Summary

Zidentyfikowano **trzy** opcje (nie dwie, jak zakładał roadmap). Rekomendacja: **Flutter Geocoding plugin (`/baseflow/flutter-geocoding`)** — korzysta z natywnego geocodera Androida (Google Play Services), jest darmowy, nie wymaga API key, i ma bezpośrednią integrację z `google_maps_flutter` który już jest w projekcie.

## Detailed Findings

### Opcja 1: Flutter Geocoding (⭐ Rekomendowana)

- **Koszt**: DARMOWY — używa wbudowanego geocodera Androida (Google Play Services)
- **API key**: NIE wymaga — działa przez Play Services, żadnych secretów
- **Rate limit**: Brak (ograniczenia Play Services są niewidoczne)
- **Jakość**: Wysoka — ten sam backend co Google Geocoding API, przez platformę
- **Offline**: `Geocoder.isPresent()` sprawdza dostępność; fallback do ręcznego wpisywania
- **Integracja z google_maps_flutter**: Natywna — dokumentacja pokazuje bezpośrednią konwersję na `LatLng`
- **Wymagania**: Android API 33+ używa `GeocodeListener` (callback-based); pre-33 legacy API
- **Ryzyka**: Play Services może nie działać w niektórych krajach (VPN potrzebny)

Pakiet: `geocoding: ^4.0.0` (pub.dev, Baseflow, 292 snippets, High reputation)

```dart
// Przykład integracji z MapPickerScreen:
final geocoding = Geocoding();
final locations = await geocoding.locationFromAddress('Luwr, Paryż');
if (locations.isNotEmpty) {
  final loc = locations[0];
  final latLng = LatLng(loc.latitude, loc.longitude);
  // Przesuń mapę na latLng, ustaw pinezkę
}
```

### Opcja 2: Google Geocoding API (bezpośrednie HTTP)

- **Koszt**: $5/1000 zapytań, 10 000 free/month
- **API key**: Wymaga klucza (osobny od Maps API key)
- **Rate limit**: 50 req/s
- **Jakość**: Najwyższa — bezpośredni dostęp do pełnego Google Geocoding
- **Offline**: Nie — wymaga HTTP
- **Integracja**: Wymaga ręcznego parsowania JSON + zarządzania kluczem
- **Setup**: Potrzebny dodatkowy klucz API, billing-enabled projekt GCP
- **Ryzyka**: Koszty przy większej skali, zarządzanie kluczami

### Opcja 3: OSM Nominatim Dart (`/provokateurin/osm-nominatim`)

- **Koszt**: DARMOWY
- **API key**: Nie wymaga
- **Rate limit**: 1 req/s (wymuszone przez OSM policy)
- **Jakość**: Dobra w Europie, gorsza poza — braki w mniejszych miejscowościach
- **Offline**: Nie — wymaga HTTP do nominatim.openstreetmap.org
- **Integracja**: Prosty Dart HTTP client
- **Wymagania**: `User-Agent` header wymagany przez OSM
- **Ryzyka**: 1 req/s to wąskie gardło przy szybkim pisaniu; nie działa w Chinach/Rosji

```dart
final nominatim = Nominatim(userAgent: 'TravelJug/1.0');
final results = await nominatim.searchByName(
  query: 'Luwr, Paryż',
  limit: 5,
);
```

## Code References

### Istniejący kod do modyfikacji

- `lib/screens/map_picker_screen.dart` — główny plik do rozszerzenia o search field + results list
- `lib/screens/trip_detail_screen.dart:703-806` — `_AddAttractionDialog` wywołuje `MapPickerScreen.show(context)`, miejsce gdzie wyniki geocodingu są konsumowane
- `pubspec.yaml` — już zawiera `google_maps_flutter: ^2.10.0` i `url_launcher: ^6.3.0`

### Nowy kod

- Nowy widget/pole `SearchBar` w `MapPickerScreen` do wpisywania nazwy miejsca
- Nowa metoda `_search(String query)` wywołująca geocoding
- Nowa lista wyników `_results: List<Location>` wyświetlana pod search barem
- `_onResultTap(Location loc)` — przesuwa mapę na `LatLng(loc.latitude, loc.longitude)` i ustawia `_position`

### Bez zmian

- DAO, schemat DB, timeline engine, pace config — nie dotykane
- Istniejący `MapPickerScreen` fallback (timeout → manual entry) zachowany

## Architecture Insights

### Wzorzec integracji

MapPickerScreen już ma 3 stany: map loaded, map timeout (manual entry), i potwierdzenie. S-08 dodaje czwarty element: **search mode** — pole tekstowe z listą wyników nakładającą się na mapę.

```
MapPickerScreen
├── AppBar: "Pick Location" + Confirm
├── SearchField (NOWY) — TextField z debounce 500ms
│   └── ResultsList (NOWY) — ListView pod search barem
├── GoogleMap (istniejący) — tap-to-place zachowany
│   └── Marker (istniejący)
└── FallbackView (istniejący) — manual coordinate entry
```

### Debounce strategy

Przy OSM Nominatim (1 req/s), debounce 500ms + cancel poprzedniego requestu jest kluczowy. Przy Flutter Geocoding (brak limitu), debounce 300ms wystarczy dla UX.

### Cache (nice-to-have)

PRD v2 secondary: "Wyniki wyszukiwania są zapamiętywane lokalnie". Można zrealizować przez prosty `Map<String, List<Location>>` w pamięci (niepersystentny, tracony przy restarcie apki) lub nową tabelę w SQLite (overkill na MVP).

## Rekomendacja

**Flutter Geocoding (`/baseflow/flutter-geocoding`)** jest optymalnym wyborem:

1. **Darmowy** — brak kosztów, brak billing-enabled projektu GCP
2. **Bez API key** — zero konfiguracji CI/secrets, mniej punktów awarii
3. **Natywny Android geocoder** — ten sam backend Google co płatne API, przez Play Services
4. **Bezpośrednia integracja** z `google_maps_flutter` — dokumentacja Baseflow pokazuje gotowe snippety
5. **`isPresent()` check** — naturalny fallback do ręcznego wpisywania współrzędnych
6. **Już na pub.dev** — `geocoding: ^4.0.0`, dojrzały pakiet (292 snippets, High reputation)

OSM Nominatim zostaje jako opcja backup na wypadek gdyby Play Services okazał się problematyczny. Google Geocoding API (bezpośrednie) jest overkillem dla skali MVP.

## Open Questions

1. **Android API level coverage** — Flutter Geocoding używa `GeocodeListener` na API 33+. Czy apka wspiera API 29+ (jak deklaruje PRD)? Trzeba obsłużyć obie ścieżki (pre-33 legacy + 33+ callback).
2. **Play Services w kraju użytkownika** — czy geocoding przez Play Services działa w Polsce? (tak — Google Play Services jest standardem na polskich urządzeniach)
3. **Czy `geocoding` package już jest w pubspec.yaml?** — nie, trzeba dodać.
4. **Cache strategy** — czy implementować lokalny cache wyników w S-08, czy zostawić na później?
