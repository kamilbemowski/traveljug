# F-03: CI/CD Pipeline — Implementation Plan

## Overview

Create a GitHub Actions workflow that builds a signed release APK on every push to main, runs `flutter test` first, auto-patches the `firebase_app_distribution_android` compileSdk bug, and distributes the APK to Firebase App Distribution with release notes from CHANGELOG.md.

## Current State Analysis

- `.github/workflows/` does not exist — no CI/CD automation.
- `firebase-tools` CLI already authenticated locally; CI needs service account JSON.
- Release keystore does not exist yet.
- APK builds successfully manually: `flutter build apk --debug`.
- Firebase App ID: `1:880548270338:android:8cf0522d7bcdc14c68321b`.
- Package name: `pl.bemowski.trekjot`.

### Key Discoveries:

- `android/app/build.gradle.kts` currently uses `signingConfigs.getByName("debug")` for release builds — must be updated to use a real keystore.
- `firebase_app_distribution_android` plugin at `~/.pub-cache` has `compileSdkVersion 30` — must be patched to 35 before build. The pub cache path is not deterministic in CI, so we patch via a Gradle subproject override or a `sed` on the known path under the Flutter pub cache.
- GitHub-hosted runners include `flutter` but version varies — pinning is safer.

## Desired End State

On every push to main:
1. GitHub Actions checks out the code and sets up pinned Flutter.
2. Runs `flutter test` — fails the workflow if any test fails.
3. Patches the `compileSdkVersion 30 → 35` in the pub-cached plugin.
4. Decodes the release keystore from a GitHub Secret and builds a signed release APK.
5. Distributes the APK to Firebase App Distribution with release notes from CHANGELOG.md (fallback: commit message).

### Verification:

- Push to main triggers the workflow — visible in GitHub Actions tab.
- Workflow completes green: tests pass, APK built, distributed to Firebase.
- Release APK appears in Firebase App Distribution Console.

## What We're NOT Doing

- No Play Store deployment (AAB, Play Console API).
- No PR preview builds (build-on-PR can be added later).
- No version auto-increment — version stays as-is from `pubspec.yaml`.
- No multi-environment (staging/production) Firebase projects.

## Implementation Approach

Single `deploy.yml` workflow file with two jobs: `test` → `build-and-deploy` (sequential). The `build-and-deploy` job:
1. Sets up Java 17 + pinned Flutter via `subosito/flutter-action`.
2. Applies the compileSdk patch via `sed` on the pub-cached plugin path.
3. Decodes keystore + key properties from GitHub Secrets.
4. Runs `flutter build apk --release`.
5. Installs `firebase-tools` and calls `firebase appdistribution:distribute`.

## Critical Implementation Details

- **compileSdk patch path in CI**: The pub cache in GitHub Actions is at `~/.pub-cache` on Linux. The plugin path is `~/.pub-cache/hosted/pub.dev/firebase_app_distribution_android-1.3.0/android/build.gradle`. The `sed` command must run after `flutter pub get` populates the cache.
- **Keystore encoding**: The keystore `.jks` file is binary. Encode with `base64 -w0`, store as `KEYSTORE_BASE64`, decode with `base64 -d` in CI. Store password/alias as separate secrets: `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`.
- **Firebase service account**: The `FIREBASE_SERVICE_ACCOUNT_JSON` secret must contain the full JSON key for a service account with Firebase App Distribution Admin role.

---

## Phase 1: Keystore generation and GitHub Secrets setup

### Overview

Generate a release keystore, encode it, and create all required GitHub Secrets. No code changes — purely setup work.

### Changes Required:

#### 1. Generate release keystore

**Intent**: Create a Java keystore for signing release APKs. The keystore file lives locally (never committed). Its base64 encoding + passwords go to GitHub Secrets.

**Contract**:
- Run `keytool -genkey -v -keystore release.keystore -alias upload -keyalg RSA -keysize 2048 -validity 10000` — prompts for name, org, passwords.
- Encode: `base64 -w0 release.keystore > release.keystore.b64` (Linux) or `base64 -i release.keystore -o release.keystore.b64` (macOS).
- Delete the `.b64` file after adding to GitHub Secrets.

#### 2. Create GitHub Secrets

**Intent**: Store all sensitive values as GitHub Secrets accessible in CI.

**Contract**: Create these secrets in repo Settings → Secrets and variables → Actions:
- `KEYSTORE_BASE64` — base64-encoded release.keystore
- `KEYSTORE_PASSWORD` — keystore password
- `KEY_ALIAS` — key alias (default: `upload`)
- `KEY_PASSWORD` — key password
- `FIREBASE_SERVICE_ACCOUNT_JSON` — full JSON of service account key (from Firebase Console → Project Settings → Service Accounts)

### Success Criteria:

#### Automated Verification:

- `gh secret list` shows all 5 secrets exist

#### Manual Verification:

- Each secret value is correct (decode KEYSTORE_BASE64 → valid .jks; FIREBASE_SERVICE_ACCOUNT_JSON → valid JSON)

---

## Phase 2: Update Gradle for release signing

### Overview

Update `android/app/build.gradle.kts` to use the release keystore (from environment variables set by CI) instead of the debug keystore for release builds. Also create `android/key.properties` support for local builds.

### Changes Required:

#### 1. build.gradle.kts — release signing config

**File**: `android/app/build.gradle.kts`

**Intent**: Read keystore path, passwords, and alias from CI environment variables. Fall back to debug signing if env vars are absent (local development).

**Contract**:
- Before `android {}` block, add code to read `System.getenv("KEYSTORE_BASE64")` etc.
- In `buildTypes { release { ... } }`, replace `signingConfigs.getByName("debug")` with a real `signingConfig` that uses the decoded keystore file.
- If env vars are absent: use debug signing (local dev friendly).

### Success Criteria:

#### Automated Verification:

- `flutter build apk --release` succeeds locally (falls back to debug keystore since env vars are absent)
- `flutter analyze` passes

#### Manual Verification:

- Release build produces a valid signed APK

---

## Phase 3: Create GitHub Actions workflow

### Overview

Create `.github/workflows/deploy.yml` with test + build-and-deploy jobs. This is the core deliverable.

### Changes Required:

#### 1. Workflow file

**File**: `.github/workflows/deploy.yml` (new)

**Intent**: On push to main: test → patch compileSdk → decode keystore → build release APK → distribute to Firebase.

**Contract**:
- `on: push: branches: [main]`
- Job `test`: `flutter test`
- Job `build-and-deploy` (needs `test`):
  - `actions/checkout@v4`
  - `actions/setup-java@v4` (Java 17)
  - `subosito/flutter-action@v2` (pinned Flutter version)
  - `flutter pub get`
  - Patch compileSdk: `sed -i 's/compileSdkVersion 30/compileSdkVersion 35/' ~/.pub-cache/hosted/pub.dev/firebase_app_distribution_android-1.3.0/android/build.gradle`
  - Decode keystore: `echo "$KEYSTORE_BASE64" | base64 -d > "$HOME"/release.keystore && echo "KEYSTORE_PATH=$HOME/release.keystore" >> "$GITHUB_ENV"`
  - Gradle reads `KEYSTORE_PATH` env var for release signing config
  - `flutter build apk --release`
  - `npm install -g firebase-tools`
  - Firebase auth: `echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > "$HOME"/firebase-key.json && export GOOGLE_APPLICATION_CREDENTIALS="$HOME/firebase-key.json"`
  - `firebase appdistribution:distribute ... --app "$FIREBASE_APP_ID" --groups "testers" --release-notes "${{ github.event.head_commit.message }}"`
- Secrets: `KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`, `KEY_PASSWORD`, `FIREBASE_SERVICE_ACCOUNT_JSON`, `FIREBASE_APP_ID`
- Release notes: use commit message directly via `${{ github.event.head_commit.message }}`. Future: switch to reading from `CHANGELOG.md` when curated notes are maintained.

#### 2. CHANGELOG.md stub

**File**: `CHANGELOG.md` (new)

**Intent**: Provide a place for curated release notes. CI reads this file. If it's empty or a stub, the Firebase release notes will show the commit message.

**Contract**: Minimal initial content — one section header.

### Success Criteria:

#### Automated Verification:

- Push to main triggers the workflow
- `flutter test` passes in CI
- `flutter build apk --release` succeeds in CI
- Firebase distribution step completes

#### Manual Verification:

- APK appears in Firebase App Distribution Console with correct release notes
- Workflow is green in GitHub Actions tab

---

## Testing Strategy

### Unit Tests:

- None at F-03 stage. The workflow is verified by running it on push to main. Pre-merge testing can be added later via a PR-check workflow (out of scope).

### Manual Testing Steps:

1. Generate keystore and create GitHub Secrets (Phase 1).
2. Push a test commit to main.
3. Observe the workflow in GitHub Actions tab — should be green.
4. Check Firebase App Distribution Console — new release should appear with release notes.

## References

- Roadmap: `context/foundation/roadmap.md` — F-03
- GitHub Issue: [#3](https://github.com/kamilbemowski/traveljug/issues/3)
- Firebase App ID: `1:880548270338:android:8cf0522d7bcdc14c68321b`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Keystore generation and GitHub Secrets setup

#### Automated

- [x] 1.1 `gh secret list` shows all 5 secrets exist

#### Manual

- [ ] 1.2 Keystore .jks decodes correctly from KEYSTORE_BASE64
- [ ] 1.3 FIREBASE_SERVICE_ACCOUNT_JSON is valid service account key

### Phase 2: Update Gradle for release signing

#### Automated

- [x] 2.1 `flutter build apk --release` succeeds locally
- [x] 2.2 `flutter analyze` passes

#### Manual

- [ ] 2.3 Release APK is signed with the provided keystore

### Phase 3: Create GitHub Actions workflow

#### Automated

- [x] 3.1 Workflow triggers on push to main
- [x] 3.2 `flutter test` passes in CI
- [x] 3.3 `flutter build apk --release` succeeds in CI
- [x] 3.4 Firebase distribution step completes

#### Manual

- [ ] 3.5 APK appears in Firebase App Distribution Console with release notes
