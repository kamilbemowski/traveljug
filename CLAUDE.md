<!-- BEGIN @przeprogramowani/10x-cli -->

## 10xDevs AI Toolkit - Module 3, Lesson 4 (E2E Tests)

**For E2E tests, use the `/10x-e2e` skill.** It is the single source of truth
for the workflow — risk → seed test + rules → generate → review against the five
anti-patterns → re-prompt → verify. The skill's `references/` carry the full
rules, anti-patterns, seed pattern, and prompt-template.

A few hard rules that hold even before you invoke the skill:

- **Locators:** `getByRole` / `getByLabel` / `getByText` first; `getByTestId`
  only when accessibility attributes are ambiguous. Never CSS selectors, XPath,
  or DOM structure.
- **Never `page.waitForTimeout()`.** Wait for state: `toBeVisible()`,
  `waitForURL()`, `waitForResponse()`.
- **Test independence + cleanup.** Each test runs standalone — its own setup,
  action, assertion, and cleanup; unique ids (timestamp suffix) so parallel runs
  and re-runs don't collide.

Two boundaries to keep straight:

- **DOM (snapshot) is the default.** Vision (`--caps=vision`) is a supplement for
  visual-only risks (layout, z-index, animation); for pixel regression prefer
  deterministic tools (`toMatchSnapshot`, Argos, Lost Pixel). VLM model
  selection/cost is a debugging topic (Lesson 5), not testing.
- **Healer helps on selectors, harms on logic.** A changed selector → healer
  re-finds it (route through PR review). A changed business behavior → healer
  masks the bug; that failing-test-to-fix case is Lesson 5.

<!-- END @przeprogramowani/10x-cli -->

## Developer Quickstart (TravelJug)

How to work with this Flutter/Dart project. This section is hand-maintained,
outside the 10x-cli managed block — keep it current.

### Branch strategy (MANDATORY)
- **`develop` is the default branch.** All feature branches branch off `develop`, all PRs target `develop`.
- **`main` is hands-off — never touch it.** No commits, no PRs against `main`. It's production, updated only via release process.

### One-time setup
```bash
flutter pub get
dart run build_runner build   # generate Drift DAO code
npx lefthook install           # install git hooks (pre-commit: analyze + test)
```

### Every change — quality gates (automated)
| Gate | What runs | Trigger |
|---|---|---|
| Per-edit | `flutter analyze` + scoped `flutter test` | Agent `Write`/`Edit` (`.claude/settings.json`) |
| Pre-commit | `flutter analyze` + `flutter test` | Lefthook (`lefthook.yml`) |
| CI | `flutter analyze` + `flutter test` | GitHub Actions PR check (`.github/workflows/pr-check.yml`) |

### Run tests
```bash
flutter test                    # all 39 tests
flutter test test/services/     # unit tests (timeline engine)
flutter test test/database/     # DAO integration tests (in-memory SQLite)
flutter test test/integration/  # E2E service-level tests (R2, R5)
flutter test test/screens/      # widget tests
```

### Key files for agents
- `context/foundation/prd.md` — vision, user stories, FRs, business logic
- `context/foundation/test-plan.md` — 5 risks (R1–R5), phased rollout, cookbook
- `context/foundation/tech-stack.md` — stack decisions
- `lib/services/timeline_service.dart` — core algorithm: `computeTimeline`, `reapplyOverrides`
- `lib/database/app_database.dart` — Drift DB, schema v2, migration strategy
- `lib/database/tables.dart` — schema: Trips, Attractions, TimelineOverrides (FK cascade)
