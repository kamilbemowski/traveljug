---
project: travelapp
researched_at: 2026-07-04
recommended_platform: Firebase App Distribution
runner_up: GitHub Releases
context_type: mvp
tech_stack:
  language: dart
  framework: flutter
  runtime: android-apk
---

## Recommendation

**Dystrybucja APK przez Firebase App Distribution.**

Aplikacja jest lokalną apką Flutter/Dart bez backendu — nie potrzebuje hostingu webowego, tylko kanału dystrybucji budowanych APK do testerów. Firebase App Distribution jest do tego zbudowane: darmowe, zautomatyzowane z GitHub Actions, z obsługą grup testerów, in-app update SDK i integracją z Crashlytics. Koszt $0 przy skali MVP (do 500 testerów, 10 GiB egress/miesiąc, 5 GB storage). Drugie miejsce: GitHub Releases — jeszcze prostsze, ale brak auto-update i tester managementu to realne tarcie przy iteracjach co kilka dni.

## Platform Comparison

Sześć standardowych platform (Cloudflare, Vercel, Netlify, Fly.io, Railway, Render) to platformy webowe/backendowe — żadna nie jest zaprojektowana do dystrybucji plików APK. Dwie platformy mobilne (GitHub Releases, Firebase App Distribution) trafiły do shortlisty jako jedyne trafne dla tego projektu.

### Scoring matrix

| Platform | CLI-first | Managed/Serverless | Agent-readable docs | Stable deploy API | MCP / Integration | Trafność dla APK |
|---|---|---|---|---|---|---|
| Firebase App Distribution | ✅ Pass | ✅ Pass | ⚠️ Partial | ✅ Pass | ⚠️ Partial | ✅ Celowana |
| GitHub Releases | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass | ⚠️ Partial | ✅ Celowana |
| Cloudflare Pages+R2 | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass | ⚠️ Partial |
| Vercel | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass* | ❌ Fail |
| Netlify | ⚠️ Partial | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass | ❌ Fail |
| Fly.io | ✅ Pass | ⚠️ Partial | ✅ Pass | ✅ Pass | ✅ Pass | ❌ Fail |
| Railway | ✅ Pass | ⚠️ Partial | ✅ Pass | ✅ Pass | ✅ Pass | ❌ Fail |
| Render | ⚠️ Partial | ✅ Pass | ✅ Pass | ✅ Pass | ✅ Pass | ❌ Fail |

*\* Vercel MCP w Public Beta, read-only*

**Hard filtry:** brak — brak wymogu persistent connections, a statyczne serwowanie APK nie wymaga runtime'u Dart na platformie. Platformy webowe odpadły w score'ingu przez fundamentalne niedopasowanie do dystrybucji APK.

**Soft-weighting:** wywiad wskazał priorytet DX nad kosztem (Firebase wygrywa przez in-app update SDK), brak preferencji co do platformy, Europa jako region (bez wpływu), zewnętrzni dostawcy OK.

### Shortlisted Platforms

#### 1. Firebase App Distribution (Rekomendowany)

Zbudowany specjalnie pod dystrybucję testowych buildów mobilnych. Darmowy, wspiera grupy testerów (do 500), ma in-app update SDK (`updateIfNewReleaseAvailable()`), integruje się z Crashlytics. `firebase appdistribution:distribute` jest w pełni skryptowalne w CI. Minusy: SDK jest wersjonowany jako beta (mimo że produkt GA), testersi muszą mieć konto Google, dokumentacja nie ma `llms.txt` na GitHub.

#### 2. GitHub Releases

Jedna linijka w istniejącym GitHub Actions — `gh release create` z poziomu CI. Zero dodatkowych kont, zero kosztów, nielimitowany bandwidth. Minusy: brak auto-update, brak tester managementu, ręczny sideloading z całym tarciem Androida (unknown sources, Play Protect), publiczne repo = publiczny APK.

#### 3. Cloudflare Pages + R2

Technicznie może serwować APK (R2: 10 GB free, zero egress, Pages jako landing page). Wrangler CLI referencyjnie dobry. Minusy: nie jest to platforma dystrybucji mobilnej — brak versioningu, tester managementu, auto-update. Rozwiązanie "może działać", a nie "jest do tego zbudowane".

## Anti-Bias Cross-Check: Firebase App Distribution

### Devil's Advocate — Weaknesses

1. **Google account jako bariera dla testerów.** Każdy tester musi mieć konto Google. Dla znajomych/rodziny bez Gmaila to dodatkowy krok przed pierwszą instalacją.
2. **Firebase = GCP billing setup.** Nawet na darmowym Spark planie trzeba podpiąć konto rozliczeniowe Google Cloud Platform — 20-30 minut konfiguracji przed pierwszym deployem.
3. **SDK App Distribution jest beta (wersja `16.0.0-beta20`).** Mimo że sam produkt jest GA, biblioteka kliencka może zmienić API. `updateIfNewReleaseAvailable()` może mieć nieudokumentowane przypadki brzegowe.
4. **APK z kluczem developerskim = tarcie przy Play Store.** Przy przejściu na Play Store (AAB + klucz produkcyjny) testerzy Firebase muszą odinstalować starą wersję.
5. **Brak MCP dla App Distribution.** Firebase MCP server obsługuje Auth, Firestore, Storage, Hosting, Functions — ale nie App Distribution. Agent musi używać CLI.

### Pre-Mortem — How This Could Fail

Pierwszy tydzień był świetny — CI z GitHub Actions budował APK i wypychał go przez `firebase appdistribution:distribute`. Druga iteracja ujawniła problem: `updateIfNewReleaseAvailable()` w SDK beta wymagało ręcznego odświeżenia tokena Firebase po restarcie aplikacji. Testerzy, którzy nie zamknęli apki, nie widzieli nowego builda. Trzeci tydzień: klucz keystore w CI został zregenerowany z innym aliasem po wyczyszczeniu cache. Podpis się nie zgadzał — "App not installed". Tester stracił lokalne dane. Miesiąc później: 5 testerów to za mało, żeby wyłapać crash na Androidzie 10. Crashlytics, które miało być "później", nigdy nie zostało skonfigurowane. Cztery miesiące później: aplikacja działała tylko na telefonie developera.

### Unknown Unknowns

- **`firebase-tools` w CI potrzebuje service account JSON, nie tokena OAuth.** Token OAuth z `firebase login:ci` wygasa po ~1h i pipeline nagle przestaje działać.
- **"App not installed" przy niezgodności podpisu jest ciche.** Android nie podaje przyczyny — debugowanie na cudzym telefonie przez komunikator to koszmar.
- **Firebase App Distribution nie jest dostępne we wszystkich regionach GCP.** W rzadkich regionach (niektóre kraje Ameryki Płd.) dystrybucja może nie działać.
- **Flutter + Firebase = dodatkowe ~5-10 MB w APK.** Inicjalizacja Firebase i SDK App Distribution to zależność, która może się zepsuć przy aktualizacji Fluttera.
- **150-dniowa ekspiracja buildów jest nieodwołalna.** Po 5 miesiącach stary build znika — nie da się odtworzyć historycznego buga z tego builda.

## Operational Story

- **Preview deploys**: Każdy push/merge do main odpala GitHub Actions → `flutter build apk --debug` → `firebase appdistribution:distribute` do grupy testerów. Nowy build dostępny natychmiast po zakończeniu CI. Testerzy dostają email i/lub in-app prompt (jeśli SDK jest zintegrowane).
- **Secrets**: `FIREBASE_SERVICE_ACCOUNT_JSON` jako GitHub Secret — service account z rolą Firebase App Distribution Admin. Klucz keystore i hasła również w GitHub Secrets (`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`). Service account rotuje się w GCP Console > Service Accounts > nowy klucz JSON > update GitHub Secret.
- **Rollback**: W Firebase Console > App Distribution > wybierz poprzedni release > "Re-distribute". Albo przez CLI: `firebase appdistribution:distribute <stary-apk> --groups "testers"`. Czas revertu: ~2 min (czas uploadu APK). Uwaga: rollback nie cofa migracji bazy lokalnej — jeśli schemat się zmienił, apka może crashować.
- **Approval**: `firebase appdistribution:distribute` z CI jest automatyczne (agent może wypychać). Kasowanie projektu Firebase, rotacja klucza produkcyjnego, przejście na Play Store — tylko ręcznie.
- **Logs**: `firebase appdistribution:distribute` zwraca URI do konsoli. Crash/ANR logi w Firebase Crashlytics (jeśli skonfigurowane). Logi CI widoczne w GitHub Actions. Brak runtime logów po stronie Firebase dla samej dystrybucji (to nie hosting).

## Risk Register

| Risk | Source | Likelihood | Impact | Mitigation |
|---|---|---|---|---|
| Keystore zregenerowany w CI = "App not installed" u testerów | Pre-mortem | M | H | Keystore przechowywany jako GitHub Secret (base64), nigdy generowany ad-hoc. Backup keystore poza repo. |
| Token OAuth zamiast service account w CI = pipeline się wykłada | Unknown unknowns | M | M | Użyj service account JSON od początku. Dokumentacja w AGENTS.md: "Używaj wyłącznie service account, nie tokenów OAuth." |
| SDK beta — `updateIfNewReleaseAvailable()` nie działa na niektórych urządzeniach | Devil's advocate | M | L | Testuj in-app update na 2-3 różnych urządzeniach/Android wersjach przed szerszą dystrybucją. Fallback: link w emailu zawsze działa. |
| Testerzy bez Google account nie mogą zainstalować | Devil's advocate | L | L | MVP: testerzy techniczni z kontami Google. Dla nietechnicznych: wyślij bezpośredni link do APK z Firebase (działa bez konta przy pierwszym pobraniu, konto wymagane do auto-update). |
| 150-dniowa ekspiracja builda = nie da się odtworzyć historycznego buga | Unknown unknowns | L | L | Taguj każdy release w GitHub z numerem wersji. Odtwarzaj bugi z kodu, nie z builda. |
| Firebase/GCP region nie wspiera App Distribution | Unknown unknowns | L | L | Podczas setupu wybierz region `us-central1` lub `europe-west` — oba wspierają App Distribution. |
| Brak Crashlytics = niewidoczne crashy u testerów | Pre-mortem | H | M | Skonfiguruj Firebase Crashlytics razem z App Distribution. To 3 komendy CLI i 2 pliki konfiguracyjne — zrób to przed pierwszą dystrybucją. |

## Getting Started

### 1. Zainstaluj Firebase CLI i zaloguj się

```bash
npm install -g firebase-tools
firebase login
```

### 2. Utwórz projekt Firebase i skonfiguruj App Distribution

W Firebase Console (<https://console.firebase.google.com>):
- Utwórz nowy projekt (nazwa: "travelapp" lub dowolna)
- Włącz App Distribution (Release & Monitor > App Distribution)
- W "Ustawienia projektu" > "Konta usługowe" — wygeneruj nowy klucz JSON dla Firebase Admin SDK
- Zapisz JSON jako GitHub Secret: `FIREBASE_SERVICE_ACCOUNT_JSON`

### 3. Dodaj Firebase do projektu Flutter

```bash
cd travelapp
flutter pub add firebase_core
flutter pub add firebase_app_distribution
```

Zainicjalizuj Firebase w aplikacji zgodnie z dokumentacją `flutterfire init`.

### 4. Skonfiguruj CI (GitHub Actions)

Dodaj krok w `.github/workflows/deploy.yml`:

```yaml
- name: Build APK
  run: flutter build apk --debug

- name: Distribute to Firebase
  run: |
    npm install -g firebase-tools
    firebase appdistribution:distribute build/app/outputs/flutter-apk/app-debug.apk \
      --app "${{ secrets.FIREBASE_APP_ID }}" \
      --groups "testers" \
      --release-notes "${{ github.event.head_commit.message }}"
```

### 5. Dodaj pierwszych testerów

W Firebase Console > App Distribution > Testers:
- Utwórz grupę "testers"
- Dodaj adresy email testerów (muszą być kontami Google)
- Testerzy dostaną zaproszenie email — po akceptacji będą widzieć nowe buildy

## Out of Scope

The following were not evaluated in this research:
- Google Play Store (produkcyjna dystrybucja — wymaga $25 rejestracji, AAB zamiast APK, review process)
- Shorebird (Flutter-specific OTA updates — komplementarne, nie alternatywne)
- Docker image configuration
- CI/CD pipeline beyond GitHub Actions + `firebase-tools`
- Production-scale architecture (multi-region, HA, DR)
