# F-02: Wire Firebase Crashlytics — Implementation Plan

## Overview

Initialize Firebase Crashlytics in `main.dart` immediately after `Firebase.initializeApp()`. Privacy-minimal configuration: stack trace + device model + OS version + app version only. No breadcrumbs, no custom keys, no user-identifying data. Opt-out boolean flag wired for future Settings UI. Both debug and release builds report crashes.

## Current State Analysis

- `firebase_crashlytics: ^5.2.4` already in `pubspec.yaml` — no additional dependencies needed.
- `Firebase.initializeApp()` at `lib/main.dart:6` — Crashlytics init goes right after this line.
- No error handlers are set — uncaught Flutter errors and async errors currently go to the OS default handler (logcat on Android), invisible to the developer.
- PRD NFR: "No analytics, no telemetry, no network calls that expose trip content" — Crashlytics must NOT send user data, only crash metadata.

### Key Discoveries:

- `lib/main.dart:4-7` — existing async `main()` with `WidgetsFlutterBinding.ensureInitialized()` + `await Firebase.initializeApp()`. Crashlytics init fits naturally between `Firebase.initializeApp()` and `runApp()`.
- The `FirebaseCrashlytics` singleton is available after `Firebase.initializeApp()` — no separate initialization call needed.
- CRASHLYTICS_DISABLED flag at `lib/main.dart:3` (new) — opt-out mechanism, default `false`.

## Desired End State

After `Firebase.initializeApp()`, `FlutterError.onError` is set to `FirebaseCrashlytics.instance.recordFlutterFatalError`, and `PlatformDispatcher.instance.onError` is set to forward async errors to Crashlytics. A `const bool kCrashlyticsDisabled = false` flag gates both handlers — when `true`, Crashlytics is skipped. The app builds and launches without errors.

### Verification:

- `flutter build apk --debug` compiles successfully.
- `flutter analyze` passes with no new warnings.
- Manual force-crash in debug mode sends a report visible in Firebase Crashlytics Console.

## What We're NOT Doing

- No breadcrumbs (`FirebaseCrashlytics.instance.log()`).
- No custom keys (`FirebaseCrashlytics.instance.setCustomKey()`).
- No user identifier (`FirebaseCrashlytics.instance.setUserIdentifier()`).
- No opt-out UI (Settings screen) — just the boolean flag, ready for future wiring.
- No automated tests — Crashlytics is verified manually.
- No `recordError` calls in app code — just the top-level uncaught-error handlers.

## Implementation Approach

Standard Firebase Crashlytics Flutter initialization pattern: two error handlers (`FlutterError.onError` + `PlatformDispatcher.instance.onError`) set in `main()` after `Firebase.initializeApp()`. Wrapped in a `if (!kCrashlyticsDisabled)` guard for the future opt-out. No DI, no separate module — the handlers live inline in `main.dart` because they're ~6 lines total and the app has no error-handling infrastructure yet.

---

## Phase 1: Wire Crashlytics initialization

### Overview

Add the Crashlytics import and two error handlers to `main.dart` with an opt-out flag. The entire change is in one file.

### Changes Required:

#### 1. Import and initialize Crashlytics

**File**: `lib/main.dart`

**Intent**: Forward all uncaught Flutter and async errors to Firebase Crashlytics. Wrap handlers behind a const boolean flag so the user can disable Crashlytics from a future Settings UI without changing the handler code.

**Contract**:
- Add `import 'dart:ui';` (for `PlatformDispatcher`) and `import 'package:firebase_crashlytics/firebase_crashlytics.dart';` at the top.
- Add `const bool kCrashlyticsDisabled = false;` after imports.
- After `await Firebase.initializeApp();`, add:

```dart
if (!kCrashlyticsDisabled) {
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
}
```

The `PlatformDispatcher` handler returns `true` to signal the error was handled (prevents the default crash behavior from also firing).

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes with no new warnings in `lib/main.dart`
- `flutter build apk --debug` compiles successfully

#### Manual Verification:

- Force a crash in debug mode (e.g., `throw Exception('test crash')` in a button callback), verify the crash report appears in Firebase Crashlytics Console
- Verify no crash report is sent when `kCrashlyticsDisabled = true`

---

## Testing Strategy

### Unit Tests:

- None. Crashlytics initialization has no testable side effects in unit test environments — it requires Firebase, which is not available in the Dart VM test runner.

### Manual Testing Steps:

1. Build and launch the app in debug mode on a device/emulator.
2. Add a temporary button that throws an exception.
3. Tap the button, observe the app crashes (or shows the red error screen in debug).
4. Open Firebase Console → Crashlytics → verify the crash report appears with stack trace and device info.
5. Set `kCrashlyticsDisabled = true`, rebuild, tap the crash button — verify NO report appears in Crashlytics Console.
6. Revert `kCrashlyticsDisabled = false` and remove the test crash button.

## Performance Considerations

- `FlutterError.onError` and `PlatformDispatcher.instance.onError` are simple assignments — zero overhead until a crash occurs.
- Crashlytics crash reporting is async and non-blocking — does not affect app startup time.

## References

- Roadmap: `context/foundation/roadmap.md` — F-02
- GitHub Issue: [#2](https://github.com/kamilbemowski/traveljug/issues/2)
- Firebase Crashlytics Flutter docs: https://firebase.google.com/docs/crashlytics/get-started?platform=flutter

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Wire Crashlytics initialization

#### Automated

- [x] 1.1 `flutter analyze` passes with no new warnings in `lib/main.dart`
- [x] 1.2 `flutter build apk --debug` compiles successfully

#### Manual

- [x] 1.3 Force-crash in debug sends report to Firebase Crashlytics Console
- [x] 1.4 `kCrashlyticsDisabled = true` suppresses crash reporting
