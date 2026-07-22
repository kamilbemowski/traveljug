---
change_id: observability-baseline
title: "Wire Firebase Crashlytics"
status: implemented
roadmap_ref: F-02
created: 2026-07-21
updated: 2026-07-21
---

# Observability Baseline

Foundation F-02 from `context/foundation/roadmap.md`. Wires Firebase Crashlytics into `main.dart` — all uncaught Flutter errors and async errors forwarded to Crashlytics console. Privacy-minimal: stack trace + device info only, no breadcrumbs, opt-out flag ready for future Settings UI.

**Outcome:** Crashlytics initialized; all uncaught errors reported to Firebase console.

**Unlocks:** verification path for all slices (crash visibility during development and testing).
