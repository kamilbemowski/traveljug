---
bootstrapped_at: "2026-06-21T18:31:00+02:00"
starter_id: flutter
starter_name: Flutter
project_name: travelapp
language_family: dart
package_manager: pub
cwd_strategy: native-cwd
bootstrapper_confidence: verified
phase_3_status: ok
audit_command: "null"
---

## Hand-off

```yaml
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
```

### Why this stack

A solo developer building an Android travel-planning MVP in 3 weeks after-hours needs a
battle-tested, agent-friendly mobile framework with fast iteration and no backend overhead.
Flutter is the recommended default for `(mobile, dart)` — it clears all four agent-friendly
quality gates (typed Dart codebase, convention-based widget tree, popular in training data,
well-documented) and carries verified bootstrapper confidence. The app is local-first with
no auth, payments, realtime, AI, or background jobs — Flutter's on-device SQLite and state
management cover every FR without a server. Deployment is self-host: CI produces a signed
APK artifact via GitHub Actions on merge to main, keeping the MVP free of store overhead
while preserving a clean path to Play Store when ready.

## Pre-scaffold verification

| Signal             | Value                              | Severity | Notes                              |
| ------------------ | ---------------------------------- | -------- | ---------------------------------- |
| npm package        | not run                            | —        | non-JS starter (dart)              |
| GitHub repo        | not run                            | —        | docs_url is https://flutter.dev/docs, not a GitHub repo |

Recency: no recency signal available. Proceeding.

## Scaffold log

**Resolved invocation**: `flutter create -e . --org com.example --platforms android,ios,web`
**Strategy**: native-cwd
**Exit code**: 0
**Pre-flight files-to-touch**: pubspec.yaml, lib/main.dart, analysis_options.yaml, .gitignore, .metadata, README.md, android/**, ios/**, web/**, test/**, .idea/**
**Files written by CLI**: 81
**Pre-existing files preserved**: CLAUDE.md, context/, flutter_linux_3.44.2-stable.tar.xz, .claude/
**Conflicts (.scaffold siblings)**: none

## Post-scaffold audit

**Tool**: skipped — no built-in audit tool for dart
**Recommended external tool**: `dart pub outdated --mode=null-safety` as a dependency-freshness stand-in. For vulnerability scanning, consider Snyk or OWASP Dependency-Check with Dart/Flutter support.

## Hints recorded but not acted on

| Hint                       | Value                              |
| -------------------------- | ---------------------------------- |
| bootstrapper_confidence    | verified                           |
| quality_override           | false                              |
| path_taken                 | standard                           |
| self_check_answers         | null                               |
| team_size                  | solo                               |
| deployment_target          | self-host                          |
| ci_provider                | github-actions                     |
| ci_default_flow            | auto-deploy-on-merge               |
| has_auth                   | false                              |
| has_payments               | false                              |
| has_realtime               | false                              |
| has_ai                     | false                              |
| has_background_jobs        | false                              |

## Next steps

Next: a future skill will set up agent context (CLAUDE.md, AGENTS.md). For now, your project is scaffolded and verified — happy hacking.

Useful manual steps in the meantime:
- `git init` (if you have not already) to start your own repo history.
- Review any `.scaffold` siblings the conflict policy created and decide which version of each file to keep (none in this run).
- The Flutter SDK tarball (`flutter_linux_3.44.2-stable.tar.xz`) is still in cwd — consider extracting or removing it.
- Run `flutter doctor` to verify your Flutter installation is complete.
