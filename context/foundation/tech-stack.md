---
starter_id: flutter
package_manager: pub
project_name: travelapp
hints:
  language_family: dart
  team_size: solo
  deployment_target: self-host
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: false
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
---

## Why this stack

A solo developer building an Android travel-planning MVP in 3 weeks after-hours needs a
battle-tested, agent-friendly mobile framework with fast iteration and no backend overhead.
Flutter is the recommended default for `(mobile, dart)` — it clears all four agent-friendly
quality gates (typed Dart codebase, convention-based widget tree, popular in training data,
well-documented) and carries verified bootstrapper confidence. The app is local-first with
no auth, payments, realtime, AI, or background jobs — Flutter's on-device SQLite and state
management cover every FR without a server. Deployment is self-host: CI produces a signed
APK artifact via GitHub Actions on merge to main, keeping the MVP free of store overhead
while preserving a clean path to Play Store when ready.
