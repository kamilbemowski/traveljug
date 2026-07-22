# F-03: CI/CD Pipeline — Plan Brief

> Full plan: `context/changes/ci-cd-pipeline/plan.md`

## What & Why

Kazde wypchniecie APK do Firebase App Distribution wymaga recznego odpalenia `flutter build` i `firebase appdistribution:distribute`. F-03 automatyzuje to przez GitHub Actions: push do main → testy → build release APK → dystrybucja. Koniec z recznym buildem.

## Starting Point

`firebase-tools` CLI dziala lokalnie. `google-services.json` + Firebase Gradle plugin skonfigurowane. `flutter build apk --debug` przechodzi. Brakuje: workflow YAML, release keystore, GitHub Secrets, konfiguracji release signing w Gradle.

## Desired End State

Push do main triggeruje GitHub Actions: `flutter test` → `flutter build apk --release` (podpisany) → `firebase appdistribution:distribute`. Release notes z commita. Calosc widoczna w zakladce Actions na GitHub.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Trigger | Push to main only | Kazdy merge = nowy build u testerow, bez dodatkowych krokow. | Plan |
| APK type | Release z keystorem | Szybszy, zoptymalizowany build. Profesjonalny image. | Plan |
| Tests | Run before deploy | Fail testow = brak deployu — lapie regresje przed testerami. | Plan |
| Flutter version | Pin via subosito/flutter-action | Reprodukowalne buildy — wersja Fluttera nie zmienia sie miedzy runami. | Plan |
| Keystore | base64 w GitHub Secrets | Binary JKS nie jest committowany; dekodowany w CI przed buildem. | Plan |
| compileSdk patch | sed w CI przed buildem | Ten sam patch ktory dziala lokalnie; nie wymaga commitowania zmodyfikowanego pluginu. | Plan |
| Release notes | Commit message | Proste, automatyczne — zadnej recznej roboty. CHANGELOG.md jako przyszla opcja. | Plan |

## Scope

**In scope:** deploy.yml workflow, release signing w Gradle, CHANGELOG.md stub, GitHub Secrets setup.

**Out of scope:** Play Store, PR preview builds, auto-version-increment, multi-environment.

## Architecture / Approach

```
Push to main
    │
    ▼
  flutter test ──fail──▶ ❌ Stop
    │ pass
    ▼
  sed patch compileSdk
    │
    ▼
  decode keystore (base64 → .jks)
    │
    ▼
  flutter build apk --release
    │
    ▼
  firebase appdistribution:distribute
    │
    ▼
  ✅ APK in Firebase Console
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Keystore + Secrets | release.keystore wygenerowany, 5 GitHub Secrets utworzonych | Zle zakodowany base64 — keystore nie dekoduje sie w CI |
| 2. Gradle signing | build.gradle.kts czyta env vars do release signing | Lokalne buildy moga sie wywalic jesli env vars obowiazkowe |
| 3. Workflow YAML | .github/workflows/deploy.yml — pelna automatyzacja | Sciezka pub cache w CI moze sie roznic od locala |

**Prerequisites:** Firebase service account z rola App Distribution Admin.
**Estimated effort:** ~30 min — 1h z generowaniem keystore i setupem secrets.

## Open Risks & Assumptions

- **Sciezka pub cache w CI runnerze**: `~/.pub-cache` na Linux runnerach. Jesli GitHub zmieni lokalizacje, sed nie zadziala.
- **Firebase service account wymaga GCP billing setup** — jesli nie masz jeszcze service account, Phase 1 wymaga zalogowania do GCP Console.

## Success Criteria (Summary)

- Push do main → workflow zielony w GitHub Actions.
- Release APK w Firebase App Distribution Console z poprawnymi release notes.
- `flutter test` przechodzi w CI przed buildem.
