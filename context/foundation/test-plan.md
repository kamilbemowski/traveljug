---
project: travelapp
version: 1
status: active
created: 2026-07-27
updated: 2026-07-27
test_base: sparse
stack: Flutter/Dart + Drift SQLite + flutter_test
---

# Test Plan: TravelJug

> Phased rollout orchestrator. Each §3 phase opens its own `context/changes/<change-id>/`.
> Re-run `/10x-test-plan` to check status or advance to the next phase.

## §1 — Quality Strategy

1. **Cost × signal.** Every test answers: what is the cheapest test that gives a real signal for this risk? Promote to e2e only when no cheaper layer covers the risk. AI-native layer only when it adds signal classic tests do not give cheaply.

2. **User concerns are evidence.** Risks the developer has lived through carry the same weight as PRD lines or hot-spot data. Phase 2 interview answers are cited alongside document sources in §2.

3. **Signal, not knowledge (risks are scenarios, not code locations).** This plan cites evidence that raised each risk (PRD lines, interview Q#, hot-spot directories with churn counts). It never asserts a file as "where the failure lives." File:line anchors and call-graph verification are `/10x-research`'s output, produced during each rollout phase.

## §2 — Risk Map

| # | Risk (failure scenario — user/business terms) | Impact | Likelihood | Source(s) — evidence, not anchors |
|---|---|---|---|---|
| R1 | Timeline engine produces an impossible plan — wrong day intensity, unreal visit durations, impossible travel distances between attractions | HIGH | MEDIUM | PRD §Business Logic (inputs/outputs), Interview Q1 ("aplikacja tworzy nierealny plan"), hot-spot `lib/services/timeline_service.dart` (4 commits/30d) |
| R2 | Schema migration corrupts or loses user data — trips and attractions disappear after app update | HIGH | MEDIUM | Interview Q3 ("zmiany schematu psują kompatybilność danych"), PRD guardrail "No data loss", hot-spot `lib/database/` (5 commits/30d) |
| R3 | reapplyOverrides silently corrupts plan ordering — user reorders attractions, reload shows wrong order | MEDIUM | HIGH | Interview Q4 (explicitly named), hot-spot `lib/screens/trip_detail_screen.dart` (4 commits/30d), S-03 implemented in last sprint |
| R4 | Overstuffing not detected after manual overrides — day with 20h of activities shows no warning | MEDIUM | MEDIUM | PRD guardrail "Overstuffing always flagged", Interview Q1 (intensity concerns) |
| R5 | Trip deletion leaves orphan attractions or overrides — FK cascade fails silently | HIGH | LOW | PRD guardrail "No data loss", drift FK cascade relies on PRAGMA foreign_keys=ON being set at connection open |

### Risk Response Guidance

| Risk | What would prove protection | Must challenge | Context needed for /10x-research | Likely cheapest layer | Anti-pattern to avoid |
|---|---|---|---|---|---|
| R1 | Day budget, travel gaps, and start times match pace config for given attractions. Overstuffing triggers exactly at boundary. | "Happy-path 3-attraction trip works" implies edge cases work. | PaceConfig values, computeTimeline algorithm, edge cases (empty trip, single attraction, exact boundary, multi-day overflow). | Unit test (pure function) | Implementation mirror — expected value copied from the algorithm's own output instead of computed independently |
| R2 | Existing data survives schema migration. Fresh install creates correct schema. | "Migration ran locally" implies it works on every device. | Current schema version, migration path, onUpgrade logic, existing test data fixtures. | Integration test (in-memory drift DB + migration) | Testing only fresh install (onCreate) and skipping upgrade from previous version |
| R3 | Attraction moved by override appears on target day with correct position. Empty days preserved. Order persists after recompute. | "Two-attraction reorder works" implies N-attraction reorder works. | reapplyOverrides algorithm, TimelineOverrides DAO, loadOverridesByTrip query. | Unit test (pure function) | Testing only insertion, never removal from source day |
| R4 | Day total exceeds waking budget after overrides → overstuffed=true. Day within budget → overstuffed=false. | "Overstuffing works on computed timeline" implies it works after overrides. | Override-aware budget recalculation in reapplyOverrides. | Unit test (pure function) | Reusing computed overstuffed flag without recalculating after overrides |
| R5 | Deleting a trip removes all its attractions and overrides. No orphan rows remain. | "FK cascade is ON" implies it actually fires. | PRAGMA foreign_keys verification, cascade delete test coverage. | Integration test (in-memory DB) | Testing only the trip row deletion, not the cascade effect |

## §3 — Phased Rollout

| # | Phase | Goal | Risks | Test types | Status | Change folder |
|---|---|---|---|---|---|---|
| 1 | Migration safety + data integrity | Prove schema migrations never lose data and FK cascades work correctly | R2, R5 | Integration tests (drift in-memory) | not started | — |
| 2 | Timeline engine correctness | Prove computeTimeline produces correct day budgets, travel gaps, start times, and overstuffing flags | R1 | Unit tests (pure function) | not started | — |
| 3 | Override logic robustness | Prove reapplyOverrides preserves ordering, handles empty days, and recomputes overstuffing | R3, R4 | Unit tests (pure function) | not started | — |
| 4 | Quality gates wiring | Lock the floor — coverage thresholds, PR check enforcement, cookbook entries | All | CI gate (flutter test --coverage) | not started | — |

## §4 — Stack

- **Language/Framework:** Dart / Flutter 3.44.2
- **Database:** Drift (SQLite) v2.34.2, on-device
- **Test runner:** flutter_test (built-in), no external test framework
- **Test base profile:** `sparse` — 3 test files (test/database/, test/services/, test/screens/), 27 test cases total. No coverage instrumentation configured.
- **CI:** GitHub Actions — deploy.yml (push to main), pr-check.yml (flutter analyze + flutter test on PR)
- **Stack grounding tools (current session):**
  - Docs: Context7 MCP available — not used (existing drift patterns well-understood); checked: 2026-07-27
  - Search: WebSearch available — not used (no external library research needed); checked: 2026-07-27
  - Runtime/browser: not available — not applicable (mobile app)
  - Provider/platform: GitHub MCP available — used for CI gate verification; checked: 2026-07-27

## §5 — Quality Gates

| Gate | Status | Wired in CI? | Notes |
|---|---|---|---|
| `flutter analyze` | ✅ active | PR check (pr-check.yml) | Zero issues enforced |
| `flutter test` | ✅ active | PR check (pr-check.yml) | 27 tests, all pass |
| Coverage threshold | ❌ not yet | — | Target: ≥80% on lib/services/, lib/database/daos/. Phase 4 wires this. |
| Post-edit hook | ❌ not yet | — | Recommended local — run `flutter test` before commit. 10x-commit Step 0 enforces this. |

## §6 — Cookbook (test patterns)

### Unit test — drift DAO (in-memory)

**Location:** `test/database/trip_dao_test.dart`
**Pattern:** `AppDatabase(NativeDatabase.memory())` → `PRAGMA foreign_keys = ON` → DAO → assert
**Run:** `flutter test test/database/`

### Unit test — pure function (timeline service)

**Location:** `test/services/timeline_service_test.dart`
**Pattern:** Fake data objects → call `TimelineService.computeTimeline()` → assert on TimelineDay fields
**Run:** `flutter test test/services/`

### Widget test — screen

**Location:** `test/screens/trip_list_screen_test.dart`
**Pattern:** `setTestDatabase()` → seed data via DAO → `pumpWidget(MaterialApp)` → assert widget tree
**Run:** `flutter test test/screens/`

### TBD patterns (fill as rollout phases ship)

- **Migration integration test** — TBD, see §3 Phase 1
- **reapplyOverrides edge cases** — TBD, see §3 Phase 3
- **Coverage CI gate** — TBD, see §3 Phase 4

## §7 — Negative Space (what we deliberately do NOT test)

- **Firebase Crashlytics integration** — verified manually (F-02). Crashlytics SDK is trusted; testing it would require Firebase runtime in CI.
- **Firebase App Distribution** — CI deploys to Firebase; manual verification that APK appears in console.
- **`_AddAttractionDialog` form** — boilerplate Flutter widget. If it breaks, the timeline test catches missing attractions.
- **Flutter widget rendering fidelity** — no screenshot/golden tests. Widget tests assert on widget existence and text, not pixel output.
- **Performance benchmarks** — MVP scale (<50 attractions, <14 days) makes computeTimeline O(n). No perf test needed until data volume grows 10x.
