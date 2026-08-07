# Dependency Update + Kotlin Fix + Vulnerability Scanner — Plan Brief

> Full plan: `context/changes/dependency-update/plan.md`

## What & Why

30 pakietów Flutter/Dart jest nieaktualnych. 3 pluginy (`firebase_app_distribution`,
`flutter_carplay`, `flutter_places_sdk`) używają starego Kotlin Gradle Plugin, generując
ostrzeżenie przy każdym buildzie: "Future versions of Flutter will fail to build".
Dodatkowo brakuje automatycznego monitorowania podatności w zależnościach.

Aktualizujemy wszystkie pakiety do najnowszych resolvable wersji, wyciszamy warning KGP
przez przejście na built-in Kotlin, i dodajemy `osv-scanner` + `dart pub outdated` do CI.

## Starting Point

- 30 pakietów outdated (3 direct, 2 dev, ~25 transitive). Główny bloker: `analyzer 13.0.0`
  trzymany przez `build_runner 2.15.1`
- CI: GitHub Actions `pr-check.yml` — analyze + testy
- `android/gradle.properties`: `builtInKotlin=false` (stara ścieżka)
- KGP warning: "Your app uses the following plugins that apply KGP: firebase_app_distribution_android,
  flutter_carplay, flutter_places_sdk"
- `android.suppressUnsupportedCompileSdk=30,31,32,33,34` już jest (firebase_app_distribution issue)

## Desired End State

Wszystkie pakiety w `pubspec.lock` na najnowszych resolvable wersjach. Build bez warningu KGP.
CI automatycznie skanuje podatności przy każdym PR i co tydzień — warning-only, nie blokuje.
`dart fix --apply` przeprowadzone na całym kodzie.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Zakres aktualizacji | Wszystkie 30 pakietów | Maksymalnie świeży kod, jedna sesja zamiast cyklicznych | Plan |
| KGP warning | builtInKotlin=true + suppress | Nowa szybsza ścieżka Kotlina, warning wyciszony dla niekompatybilnych pluginów | Plan |
| Skaner podatności | dart pub outdated --json + osv-scanner | Darmowe, oficjalne narzędzia Google, natywne dla Darta | Plan |
| CI policy | Warn — nie blokuj PR | Nie blokuje developmentu fałszywymi alarmami | Plan |
| Częstotliwość skanowania | Każdy PR + weekly cron | Bieżąca świadomość + regularny przegląd | Plan |
| Dart fix | Tak — osobna faza | Automatyczne poprawki deprecated API po aktualizacji | Plan |

## Scope

**In scope:**
- Aktualizacja wszystkich 30 pakietów w pubspec.yaml + pubspec.lock
- Przejście na built-in Kotlin + suppress KGP warning
- Dodanie osv-scanner do CI (PR + weekly cron)
- Dart fix --apply na całym projekcie
- Zgłoszenie issue do pluginów KGP o migrację do built-in Kotlin

**Out of scope:**
- Forkowanie/naprawianie pluginów KGP
- Aktualizacja Gradle lub AGP
- Zmiany w kodzie biznesowym (poza dart fix)
- Konfiguracja Dependabot (osobny tool, nie chcemy spam-PR-ów)

## Architecture / Approach

```
pubspec.yaml → flutter pub upgrade → pubspec.lock → dart fix --apply
                                                         │
gradle.properties → builtInKotlin=true               CI workflow
                  → suppress flag                     ├─ PR check: osv-scanner + dart pub outdated (warn)
                                                      └─ Weekly cron: osv-scanner → GitHub Issue
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Dependency update | Wszystkie 30 pakietów na najnowszych resolvable wersjach | Breaking changes w API (drift, firebase) |
| 2. Kotlin plugin fix | Build bez KGP warningu | Gradle może odmówić z builtInKotlin=true |
| 3. Vulnerability scanner | CI workflow z osv-scanner + dart pub outdated | osv-scanner może nie pokrywać pub.dev |
| 4. Dart fix + cleanup | dart fix --apply, czysty analyze | Może wygenerować dużo zmian |

**Prerequisites:** brak
**Estimated effort:** ~1-2 sesje across 4 fazy
**Independence:** Phase 3 (vuln scanner) is independent of Phases 1-2 — can be implemented
in parallel or first for immediate vulnerability visibility.

## Open Risks & Assumptions

- `android.builtInKotlin=true` może być niekompatybilne z naszą wersją Fluttera 3.44.2 — do zweryfikowania
- osv-scanner może nie pokrywać wszystkich pakietów z pub.dev
- Aktualizacja `analyzer`/`build_runner` może wymagać zmiany wersji `drift_dev` która z kolei wymaga nowszego `build_runner`
- dart fix może wygenerować zmiany w 10+ plikach — trudniejszy review

## Success Criteria (Summary)

- `flutter pub outdated` pokazuje 0 dostępnych aktualizacji
- `flutter build apk --debug` bez KGP warningu
- CI workflow z osv-scanner działa i raportuje warningi (nie blokuje)
- `flutter analyze` przechodzi bez błędów po dart fix
