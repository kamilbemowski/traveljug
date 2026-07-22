---
change_id: ci-cd-pipeline
title: "GitHub Actions — build APK + distribute to Firebase"
status: implementing
roadmap_ref: F-03
created: 2026-07-22
updated: 2026-07-22
---

# CI/CD Pipeline

Foundation F-03 from `context/foundation/roadmap.md`. Creates a GitHub Actions workflow that builds a release APK on push to main, runs tests, and distributes to Firebase App Distribution with release notes from CHANGELOG.md.

**Outcome:** Every push to main triggers test → build → Firebase distribution automatically.

**Unlocks:** deployment path for all slices.
