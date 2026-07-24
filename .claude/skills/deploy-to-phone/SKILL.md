---
name: deploy-to-phone
description: Build app with tests, check for connected phone, install APK. Pauses on failure with fix instructions.
argument-hint: "[--release] to build release APK instead of debug"
allowed-tools:
  - Bash
  - AskUserQuestion
---

# /deploy-to-phone — Build, Test & Install on Connected Phone

Runs unit tests, builds the APK, detects a connected phone via USB, and installs. If any step fails, explains what to fix and waits for user confirmation before retrying or stopping.

## Workflow

### Step 1 — Run unit tests

```bash
flutter test
```

- **Pass** → continue to Step 2.
- **Fail** → print the failing test output, then ask:

  AskUserQuestion:
  - question: "Tests failed. How to proceed?"
    header: "Tests"
    options:
    - label: "Fix tests first"
      description: "Stop here. I'll fix the failing tests and re-run."
    - label: "Skip tests & continue"
      description: "Proceed to build anyway (tests will be skipped)."
      multiSelect: false

  On "Fix tests first": STOP. On "Skip tests & continue": proceed to Step 2.

### Step 2 — Check connected device

```bash
flutter devices
```

Parse the output. Look for a line containing `(mobile)`.

- **Found** → extract device ID, print: `Connected: <device name> (<device id>)`. Continue to Step 3.
- **Not found** → print fix instructions, then ask:

  ```
  No phone detected via USB.

  Fix steps:
  1. Enable Developer options: Settings → About phone → tap Build number 7 times
  2. Enable USB debugging: Settings → Developer options → USB debugging
  3. Connect phone via USB cable
  4. On phone, accept "Allow USB debugging?" dialog
  5. Run: flutter devices (should show your phone)
  ```

  AskUserQuestion:
  - question: "Phone not detected. After following the steps above, retry?"
    header: "No device"
    options:
    - label: "Retry"
      description: "Scan for devices again."
    - label: "Build APK only"
      description: "Skip device check and install. APK will be in build/app/outputs/."
    - label: "Stop"
      description: "Cancel. I'll handle the device setup manually."
      multiSelect: false

  On "Retry": re-run device detection. On "Build APK only": proceed to Step 3 but skip Step 4. On "Stop": STOP.

### Step 3 — Build APK

Default: debug APK. If `--release` was passed, build release.

```bash
flutter build apk --debug    # default
flutter build apk --release  # if --release flag
```

- **Pass** → continue to Step 4.
- **Fail** → print the build error, then ask:

  AskUserQuestion:
  - question: "Build failed. How to proceed?"
    header: "Build fail"
    options:
    - label: "Fix & retry"
      description: "I'll fix the issue and re-run the build."
    - label: "Stop"
      description: "Cancel. I'll fix the build error manually."
      multiSelect: false

  On "Stop": STOP. On "Fix & retry": fix the issue, re-run `flutter build apk`, loop.

### Step 4 — Install on phone

If device was detected in Step 2:

```bash
adb -s <device-id> install -r build/app/outputs/flutter-apk/app-debug.apk
```

(or `app-release.apk` for `--release`)

- **Pass** → print success summary and stop.
- **Fail** → print the error, then ask:

  AskUserQuestion:
  - question: "Install failed. How to proceed?"
    header: "Install fail"
    options:
    - label: "Retry"
      description: "Try installing again."
    - label: "Build APK only"
      description: "APK is built. I'll install it manually."
    - label: "Stop"
      description: "Cancel."
      multiSelect: false

### Success Summary

```
═══════════════════════════════════════════════════════════
  DEPLOYED TO PHONE
═══════════════════════════════════════════════════════════

  Tests:     <all passed | skipped>
  Build:     app-<debug|release>.apk
  Device:    <device name>
  Status:    Installed ✅
═══════════════════════════════════════════════════════════
```

## Notes

- The skill never force-continues on failure — every error path pauses for user input.
- Step 2 fix instructions are self-contained so a user who has never set up USB debugging can follow them.
- The skill does NOT commit, push, or modify code — it only builds and installs.
