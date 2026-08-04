# TravelJug

Plan podróży, który trzyma się kupy. Aplikacja mobilna dla podróżnika-solo — zbierasz atrakcje, ustawiasz tempo, a TravelJug układa realistyczny plan dnia po dniu z ostrzeżeniami gdy dzień jest przeładowany.

## Dla kogo

Dla osoby planującej wyjazd solo — city break, road trip, dłuższe wakacje. Zbiera pomysły z wielu źródeł i chce je złożyć w spójny, wykonalny plan. Potrzebuje go zarówno podczas planowania, jak i w podróży — szybkie spojrzenie: co dalej, gdzie to jest, dlaczego to wybrałem.

## Główne funkcje

- **Tripy i atrakcje** — twórz wyjazd (nazwa, destynacja, daty), dodawaj atrakcje z kategorią, czasem zwiedzania i priorytetem
- **Automatyczny timeline** — algorytm rozkłada atrakcje na dni z uwzględnieniem: czasu na atrakcję, okna snu/budzenia (konfigurowalne tempo), czasu przejazdu między punktami
- **Realism check** — dzień przeładowany? Dostajesz czerwone ostrzeżenie. Napięty grafik? Pomarańczowa flaga
- **Manualne poprawki** — zmieniaj kolejność, przenoś między dniami, usuwaj. Twoje zmiany przetrwają przeliczenie planu
- **Działa offline** — cała logika i dane na urządzeniu, bez rejestracji, bez internetu

## Stack

| Warstwa | Technologia |
|---|---|
| Język / Framework | Dart / Flutter 3.44 |
| Baza danych | SQLite przez Drift ORM |
| Monitoring | Firebase Crashlytics |
| CI/CD | GitHub Actions + Firebase App Distribution |
| Quality gates | Lefthook (pre-commit), hooki agentowe Claude Code (per-edit) |

## Uruchomienie lokalne

```bash
# Zainstaluj zależności
flutter pub get

# Wygeneruj kod Drift (DAO, schemat bazy)
dart run build_runner build

# Uruchom na podłączonym urządzeniu / emulatorze
flutter run

# Sama analiza statyczna
flutter analyze

# Testy (wszystkie)
flutter test

# Tylko testy integracyjne (baza)
flutter test test/integration/

# Tylko testy jednostkowe
flutter test test/services/
```

## Struktura projektu

```
lib/
├── database/           # Drift ORM — tabele, DAO, migracje
│   ├── app_database.dart
│   ├── tables.dart
│   └── daos/           # TripDao, AttractionDao, TimelineOverrideDao
├── models/             # Modele domenowe (TimelineDay, TimelineSlot)
├── screens/            # Ekrany Flutter (lista tripów, detail tripu z timeline)
└── services/           # Logika biznesowa (TimelineService, PaceConfig)
test/
├── database/           # Testy DAO (in-memory SQLite)
├── integration/        # Testy E2E na poziomie serwis + baza (R2, R5)
├── screens/            # Widget testy
└── services/           # Testy jednostkowe TimelineService (R1, R3)
context/foundation/     # Dokumentacja 10x (PRD, roadmap, test-plan, tech-stack)
```

## Dokumentacja

Pełna dokumentacja projektu (PRD, shape-notes, roadmap, test-plan, tech-stack) znajduje się w `context/foundation/`. Została wygenerowana przez workflow 10xDevs AI Toolkit.
