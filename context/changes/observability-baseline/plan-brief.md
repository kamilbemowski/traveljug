# F-02: Wire Firebase Crashlytics — Plan Brief

> Full plan: `context/changes/observability-baseline/plan.md`

## What & Why

Apka nie ma żadnego raportowania crashy — jeśli coś padnie u testera, developer nigdy się o tym nie dowie. F-02 podłącza Firebase Crashlytics (biblioteka już jest w `pubspec.yaml`) z minimalną konfiguracją prywatnościową: tylko stack trace + device info, bez breadcrumbs, bez custom keys, z flagą opt-out gotową pod przyszły Settings UI.

## Starting Point

`firebase_crashlytics: ^5.2.4` już w `pubspec.yaml`. `Firebase.initializeApp()` już w `main.dart:6`. Brakuje tylko dwóch handlerów błędów i flagi opt-out.

## Desired End State

`FlutterError.onError` i `PlatformDispatcher.instance.onError` ustawione w `main()` po `Firebase.initializeApp()`. Crashy w debug i release trafiają do Firebase Console. Flaga `kCrashlyticsDisabled = false` (hardcoded) gotowa do podpięcia pod przyszły Settings — zmiana na `true` wyłącza raportowanie bez dotykania handlerów.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Privacy posture | Minimal: stack trace + device info only | Zgodne z PRD NFR "no analytics, no telemetry" — tylko techniczne dane o crashu. | Plan |
| Opt-in model | Default ON, opt-out later | Deweloper widzi crashy od dnia 1; user dostanie możliwość wyłączenia w przyszłym Settings. | Plan |
| Breadcrumbs | None | Breadcrumbs ("screen_view", "trip_created") to już dane o zachowaniu — naruszają NFR. | Plan |
| Debug vs release | Both | Crashy w release są kluczowe dla testerów Firebase App Distribution. W debug dodatkowo widoczne w konsoli. | Plan |
| Opt-out implementation | `const bool kCrashlyticsDisabled = false` | Najprostszy mechanizm — zero zależności, gotowe pod przyszły Settings bez zmiany handlerów. | Plan |
| Testing | Manual only | Crashlytics nie testuje się automatycznie w Dart VM — wymaga Firebase runtime. | Plan |

## Scope

**In scope:** `FlutterError.onError` handler, `PlatformDispatcher.instance.onError` handler, `kCrashlyticsDisabled` flag, importy w `main.dart`.

**Out of scope:** breadcrumbs, custom keys, user identifier, opt-out UI (Settings screen), automated tests, `recordError` calls w kodzie aplikacji.

## Architecture / Approach

Standardowy pattern Firebase Crashlytics dla Flutter: dwa handlery błędów w `main()` po `Firebase.initializeApp()`, owinięte w `if (!kCrashlyticsDisabled)`. Wszystko w `lib/main.dart` — ~8 linijek kodu (2 importy + 1 flaga + 5 linii handlerów).

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Wire Crashlytics | Crashlytics initialization + opt-out flag in main.dart | None — standard Firebase boilerplate, zero unknowns |

**Prerequisites:** `firebase_crashlytics` in `pubspec.yaml` (✅ already present), `Firebase.initializeApp()` in `main.dart` (✅ already present).
**Estimated effort:** ~5 minut — 1 plik, 8 linijek kodu, manualna weryfikacja.

## Open Risks & Assumptions

- **Crashlytics nie wysyła danych użytkownika.** Zakładamy, że stack trace + device info nie zawiera treści tripów ani atrakcji. Jeśli w przyszłości okaże się, że stack trace może zawierać dane użytkownika (np. nazwy atrakcji w message wyjątku), trzeba będzie dodać sanitizację przed wysłaniem.
- **Flaga `kCrashlyticsDisabled` jest const.** Oznacza to, że zmiana wymaga rebuildu apki — nie da się przełączyć w runtime. Akceptowalne dla MVP; jeśli opt-out stanie się priorytetem, flagę można przenieść do shared_preferences.

## Success Criteria (Summary)

- `flutter analyze` i `flutter build apk --debug` przechodzą bez błędów.
- Force-crash w debug widoczny w Firebase Crashlytics Console.
- `kCrashlyticsDisabled = true` blokuje wysyłanie crash reportów.
