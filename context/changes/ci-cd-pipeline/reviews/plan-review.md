<!-- PLAN-REVIEW-REPORT -->
# Plan Review: CI/CD Pipeline

- **Plan**: context/changes/ci-cd-pipeline/plan.md
- **Mode**: Deep
- **Date**: 2026-07-22
- **Verdict**: REVISE
- **Findings**: 0 critical, 3 warnings, 0 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| End-State Alignment | PASS ✅ |
| Lean Execution | PASS ✅ |
| Architectural Fitness | PASS ✅ |
| Blind Spots | WARNING ⚠️ (2 findings) |
| Plan Completeness | WARNING ⚠️ (1 finding) |

## Grounding
Grounding: 5/5 paths ✓ (2 new, 3 existing), 1/1 pub cache verified, brief↔plan ✓

## Findings

### F1 — No GOOGLE_APPLICATION_CREDENTIALS setup for CI Firebase auth

- **Severity**: ⚠️ WARNING
- **Impact**: 🔎 MEDIUM — real tradeoff; pause to reason through it
- **Dimension**: Blind Spots
- **Location**: Phase 3 — deploy.yml workflow
- **Detail**: The plan says CI uses `firebase appdistribution:distribute` with `FIREBASE_SERVICE_ACCOUNT_JSON` as a secret, but `firebase-tools` in CI doesn't read from an arbitrary env var. It needs `GOOGLE_APPLICATION_CREDENTIALS` pointing to a file path containing the JSON, OR the `--token` flag with a CI token. Without this setup, the firebase CLI will fail with "not authenticated."
- **Fix**: Add a step before `firebase appdistribution:distribute` that writes the secret to a file and exports it:
  `echo "$FIREBASE_SERVICE_ACCOUNT_JSON" > "$HOME"/firebase-key.json && export GOOGLE_APPLICATION_CREDENTIALS="$HOME/firebase-key.json"`. Document this in the plan's Phase 3 contract.
  - Strength: One-liner, standard pattern documented in Firebase CI docs.
  - Tradeoff: None — this is a required step, not optional.
  - Confidence: HIGH — this is how every Firebase CI setup works.
  - Blind spot: None significant.
- **Decision**: FIXED — Added `echo $FIREBASE_SERVICE_ACCOUNT_JSON > file` + `export GOOGLE_APPLICATION_CREDENTIALS` step before firebase command in plan Phase 3 contract.

### F2 — No testers group specified in firebase distribution command

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Blind Spots
- **Location**: Phase 3 — deploy.yml workflow
- **Detail**: The `firebase appdistribution:distribute` command in the plan contract doesn't include `--groups` or `--testers`. Without this, every CI build will produce the warning "no testers or groups specified, skipping" — the same issue we encountered during manual distribution. The APK uploads but nobody can download it until someone manually distributes it in the Firebase Console.
- **Fix**: Add `--groups "testers"` to the distribution command. If the group doesn't exist, document that it must be created in Firebase Console first. Alternatively, pass `--testers` with a comma-separated list.
- **Decision**: FIXED — Added `--groups "testers"` to the firebase appdistribution:distribute command in plan Phase 3 contract.

### F3 — CHANGELOG.md stub produces empty release notes

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Plan Completeness
- **Location**: Phase 3 — CHANGELOG.md stub
- **Detail**: Phase 3 creates a stub `CHANGELOG.md` with "one section header". The contract says CI reads from CHANGELOG.md with a fallback to the commit message. But with a stub that only has `# Changelog`, the release notes will be just that header. Since this is a new repo, there's no prior content. The fallback will work, but the user chose "From CHANGELOG.md" in the interview — the stub doesn't deliver the intended curated release notes experience.
- **Fix**: For the initial commit, use the fallback path exclusively (commit message). Add a note in the plan that CHANGELOG.md is maintained manually and the first meaningful entry should be written before the first production release. Or: make the CI read from CHANGELOG.md but truncate to the latest entry (between first and second `## ` heading).
- **Decision**: FIXED — Switched to commit message as primary release notes source. CHANGELOG.md retained as stub for future curated notes.
