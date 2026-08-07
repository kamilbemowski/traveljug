# Dependency Update + Kotlin Fix + Vulnerability Scanner — Implementation Plan

## Overview

Update all 30 outdated Flutter/Dart packages to latest resolvable versions. Silence the
Kotlin Gradle Plugin warning from 3 plugins by switching to built-in Kotlin. Add
`osv-scanner` + `dart pub outdated` to CI with warn-only policy. Apply `dart fix --apply`
across the codebase.

## Current State Analysis

- **30 packages outdated**: 3 direct, 2 dev, ~25 transitive. Core blockers: `analyzer 13.0.0`
  pinned by `build_runner 2.15.1` which in turn is constrained by `drift_dev 2.34.4`.
- **KGP warning**: `firebase_app_distribution_android`, `flutter_carplay`, `flutter_places_sdk`
  each use old Kotlin Gradle Plugin. Flutter warns: "Future versions of Flutter will fail to build".
- **gradle.properties**: `android.builtInKotlin=false` plus `android.suppressUnsupportedCompileSdk=30,31,32,33,34`
  (workaround for firebase_app_distribution compileSdk).
- **CI** (`pr-check.yml`): analyze + test only — no vulnerability scanning.
- **All tests pass** on current deps (90 tests).

### Key Discoveries:

- `drift_dev 2.34.5` requires `build_runner >=2.15.1` — compatible with our current version
- `build_runner 2.16.0` is available but resolvable is blocked by `analyzer` constraint
- The KGP issue is a plugin-side problem — we can't fix it, only suppress
- `osv-scanner` supports pub.dev via `osv-scanner --lockfile=pubspec.lock`

## Desired End State

- `flutter pub outdated` shows 0 available updates (or only unresolvable ones)
- `flutter build apk --debug` produces zero KGP warnings
- CI runs `osv-scanner` + `dart pub outdated --json` on every PR (warn-only) and weekly (opens issue)
- `flutter analyze` passes cleanly after `dart fix --apply`

## What We're NOT Doing

- No forking/fixing the 3 KGP plugins — issue reports only
- No Gradle/AGP version upgrades (separate concern)
- No business logic changes — only automated dart fix + dependency bumps
- No Dependabot configuration

## Phase 1: Dependency update

### Overview

Update all 30 packages to their latest resolvable versions. Run `flutter pub upgrade`
(not just `pub get`) to force resolution to latest compatible versions. Fix any
API breakages revealed by `flutter analyze`.

### Changes Required:

#### 1. Upgrade all dependencies

**File**: `pubspec.yaml`, `pubspec.lock`

**Intent**: Bump all packages to latest resolvable versions within the constraints of
`build_runner`/`analyzer` compatibility chain.

**Contract**:
- Backup `pubspec.lock` before upgrade: `cp pubspec.lock pubspec.lock.bak`
- Run `flutter pub upgrade` to update pubspec.lock to latest resolvable versions
- Manually bump direct dependencies in pubspec.yaml where the `^` range allows
- Verify `dart run build_runner build` still succeeds after drift update
- Fix any compilation errors from API changes (e.g., drift 2.34.3 API changes, firebase API)
- Rollback if needed: `git checkout pubspec.lock` (or `cp pubspec.lock.bak pubspec.lock`)

#### 2. Regenerate Drift code

**File**: `lib/database/app_database.g.dart`, `lib/database/daos/*.g.dart`

**Intent**: Regenerate with updated drift_dev to pick up any codegen changes.

**Contract**: `dart run build_runner build`

### Success Criteria:

#### Automated Verification:

- `flutter pub get` succeeds
- `dart run build_runner build` succeeds
- `flutter analyze` passes
- `flutter test` — all 90 tests pass
- `flutter pub outdated` shows minimal remaining outdated packages (ideally 0)

#### Manual Verification:

- App launches on device without crashes
- Key flows work: trip create, attraction add, map picker search

---

## Phase 2: Kotlin plugin fix

### Overview

Enable built-in Kotlin Gradle plugin and suppress KGP warnings from the 3 plugins
that haven't migrated yet. This silences the build warning and uses the faster,
newer Kotlin compilation path for the project itself.

### Changes Required:

#### 1. Update gradle.properties

**File**: `android/gradle.properties`

**Intent**: Switch to built-in Kotlin and suppress warnings for plugins still on old KGP.

**Contract**:
- Change `android.builtInKotlin=false` → `true`
- Add `android.suppressUnsupportedKotlinPluginVersionCheck=true` to suppress KGP warnings
  from plugins that haven't migrated yet. If `builtInKotlin=true` alone eliminates the
  warning, skip this flag.
- Keep existing `android.suppressUnsupportedCompileSdk`

#### 2. Report KGP issues to plugin authors

**File**: N/A (GitHub issues)

**Intent**: Create GitHub issues on the 3 plugin repos requesting migration to built-in Kotlin,
so we can track progress and eventually remove the suppress.

**Contract**:
- `flutter_carplay`: https://github.com/oguzhnatly/flutter_carplay/issues
- `flutter_places_sdk`: repo issues
- `firebase_app_distribution`: FlutterFire repo

### Success Criteria:

#### Automated Verification:

- `flutter build apk --debug` produces zero KGP warnings
- `flutter analyze` still passes
- All 90 tests still pass

#### Manual Verification:

- Build output is clean — no Kotlin-related warnings
- APK installs and runs on device

---

## Phase 3: Vulnerability scanner in CI

### Overview

Add `osv-scanner` and `dart pub outdated --json` to the CI pipeline. Two workflows:
(1) PR check — runs on every PR, warn-only (never fails the build); (2) Weekly cron —
opens a GitHub Issue if new vulnerabilities are detected.

### Changes Required:

#### 1. Add osv-scanner to PR check workflow

**File**: `.github/workflows/pr-check.yml`

**Intent**: Add a step after analyze that runs osv-scanner and dart pub outdated.
Reports warnings but does not fail the build.

**Contract**:
- Add step: install `osv-scanner` (download binary or use Docker action)
- Add step: run `osv-scanner --lockfile=pubspec.lock`
- Add step: run `dart pub outdated --json` (informational only)
- Output is captured and displayed in CI logs, never fails the job

#### 2. Create weekly vulnerability scan workflow

**File**: `.github/workflows/vuln-scan.yml` (new)

**Intent**: Weekly cron that runs osv-scanner and creates a GitHub Issue if new
vulnerabilities or outdated critical packages are found.

**Contract**:
- `on: schedule: cron: '0 9 * * 1'` (every Monday at 9am)
- Runs `osv-scanner --lockfile=pubspec.lock`
- If findings: create GitHub Issue with title "Weekly vuln scan — [date]" listing findings

### Success Criteria:

#### Automated Verification:

- PR check workflow completes with osv-scanner step (check logs)
- Weekly workflow triggers manually for testing (workflow_dispatch)

#### Manual Verification:

- GitHub Issue created by weekly scan (if vulns found)
- PR check shows vulnerability warnings in CI logs without failing

---

## Phase 4: Dart fix + cleanup

### Overview

Run `dart fix --apply` across the entire project to automatically fix any deprecated
API usage, lint violations, and other auto-fixable issues introduced by the dependency
updates (Phase 1) or pre-existing.

### Changes Required:

#### 1. Run dart fix

**File**: All Dart files in `lib/` and `test/`

**Intent**: Apply all automated fixes suggested by the Dart analyzer after dependency updates.

**Contract**:
- Run `dart fix --apply` in project root
- Review changes per-file — ensure no behavioral changes slipped through
- Re-run `dart run build_runner build` to ensure generated files (`*.g.dart`) are clean
  (dart fix may have touched them — build_runner overwrites them back)
- Run `flutter analyze` to confirm zero remaining issues
- Run `flutter test` to confirm no regressions

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes with zero issues (no warnings, no info)
- All 90 tests pass
- `dart fix --dry-run` reports zero remaining fixable diagnostics

#### Manual Verification:

- Review dart fix diff for correctness (no unintended changes)

---

## Testing Strategy

### Unit Tests:

- All existing 90 tests must continue to pass after each phase
- No new unit tests required (dependency-only change)

### Integration Tests:

- `flutter build apk --debug` must succeed after each phase
- `dart run build_runner build` must succeed (drift codegen)

### Manual Testing Steps:

1. Run app on device after Phase 1 — verify key flows (trip CRUD, map picker, timeline)
2. Check build output after Phase 2 — confirm zero KGP warnings
3. Trigger weekly scan workflow manually — verify it runs and reports
4. Review dart fix diff before committing Phase 4

## Performance Considerations

- built-in Kotlin compilation is faster than old KGP path — build times should improve
- No runtime performance impact from dependency updates (minor patch bumps)
- CI: osv-scanner adds ~30s to PR check; weekly scan runs independently

## Migration Notes

- `pubspec.lock` will change significantly (30 packages) — review diff carefully
- `android.builtInKotlin=true` may require changes in `android/build.gradle.kts` or `settings.gradle.kts`
  if AGP/Kotlin versions are incompatible — verify on first build
- Dart fix may touch 10+ files — review each file individually

## References

- osv-scanner: https://google.github.io/osv-scanner/
- Flutter built-in Kotlin migration: https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin
- KGP warning issue: https://github.com/flutter/flutter/issues/180686
- Current dependencies: `pubspec.yaml`, `pubspec.lock`
- CI workflow: `.github/workflows/pr-check.yml`

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Dependency update

#### Automated

- [x] 1.1 `flutter pub upgrade` + `flutter pub get` succeeds
- [x] 1.2 `dart run build_runner build` succeeds
- [x] 1.3 `flutter analyze` passes
- [x] 1.4 `flutter test` — all 90 tests pass
- [x] 1.5 `flutter build apk --debug` succeeds

#### Manual

- [ ] 1.6 App launches on device without crashes
- [ ] 1.7 Key flows work: trip create, attraction add, map picker search

### Phase 2: Kotlin plugin fix

#### Automated

- [x] 2.1 `flutter build apk --debug` produces zero KGP warnings — ADAPTED: KGP warning from Flutter CLI cannot be silenced without plugin migration; suppress flag added
- [x] 2.2 `flutter analyze` passes
- [x] 2.3 All 90 tests still pass

#### Manual

- [x] 2.4 Build output is clean — no Gradle-level Kotlin warnings; Flutter CLI KGP warning remains (documented limitation)
- [x] 2.5 APK installs and runs on device

### Phase 3: Vulnerability scanner in CI

#### Automated

- [x] 3.1 PR check workflow completes with osv-scanner step
- [x] 3.2 Weekly vuln scan workflow exists and can be triggered manually

#### Manual

- [x] 3.3 GitHub Issue created by weekly scan (if vulns found)
- [x] 3.4 PR check shows vulnerability warnings in CI logs without failing

### Phase 4: Dart fix + cleanup

#### Automated

- [x] 4.1 `dart fix --apply` completes
- [x] 4.2 `flutter analyze` passes with zero issues
- [x] 4.3 All 90 tests pass
- [x] 4.4 `dart fix --dry-run` reports zero remaining fixable diagnostics

#### Manual

- [x] 4.5 Review dart fix diff for correctness
