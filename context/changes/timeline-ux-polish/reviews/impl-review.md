<!-- IMPL-REVIEW-REPORT -->
# Implementation Review: Timeline UX Polish (S-05)

- **Plan**: context/changes/timeline-ux-polish/plan.md
- **Scope**: Phase 1-2 (all phases)
- **Date**: 2026-08-04
- **Verdict**: APPROVED
- **Findings**: 0 critical, 1 warning, 3 observations

## Verdicts

| Dimension | Verdict |
|-----------|---------|
| Plan Adherence | PASS |
| Scope Discipline | PASS |
| Safety & Quality | PASS |
| Architecture | PASS |
| Pattern Consistency | WARNING |
| Success Criteria | PASS |

## Findings

### F1 — _keepTogether survives reload, defying plan's "resets on reload" contract

- **Severity**: ⚠️ WARNING
- **Impact**: 🏃 LOW — quick decision; fix is obvious and narrowly scoped
- **Dimension**: Pattern Consistency
- **Location**: lib/screens/trip_detail_screen.dart:254
- **Detail**: Plan says "UI-only, resets on screen reload." Code doesn't reset — `_keepTogether` is `_DaySectionState` field, survives `_loadTimeline()` refreshes. Only resets on screen dispose. Without a `Key` on `_DaySection`, lock state binds to list *index*, not day identity — if days shift, lock attaches to wrong day.
- **Fix**: Add `key: ValueKey(widget.day.date)` to `_DaySection` in `_DaySectionState.build()`. This makes lock state track the day, and resets on data changes.
- **Decision**: PENDING

### F2 — Widget tests promised in plan but not scheduled as deliverables

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Success Criteria
- **Location**: N/A
- **Detail**: Plan's Testing Strategy promises "Intensity bar renders correct color" and "Lock toggle changes icon and suppresses overstuffing warning." Never listed in phase contracts or Progress. All 5 planned changes MATCH — this is a plan gap, not implementation gap.
- **Fix**: Add widget tests or update plan to note deferral.
- **Decision**: PENDING

### F3 — Toggle copy implies enforcement that doesn't exist

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Scope Discipline
- **Location**: lib/screens/trip_detail_screen.dart:289-294
- **Detail**: Tooltip "Keep Together (locked)" and blue banner "Keeping all attractions together" promise behavior the code doesn't enforce — move-day arrows can still pull slots off a "locked" day. Code follows the plan's Phase 2 change spec (only swaps banners), but the plan's Overview says "forces all attractions to stay." UX wording gap.
- **Fix**: Soften copy to "Keep Together (warning hidden)" / "Overstuffing suppressed" — or wire the toggle to actually block splitting.
- **Decision**: PENDING

### F4 — tightSchedule 0.8 threshold duplicated in two places

- **Severity**: OBSERVATION
- **Impact**: 🏃 LOW
- **Dimension**: Architecture
- **Location**: lib/models/timeline_day.dart:13 + lib/services/timeline_service.dart:55,88,177
- **Detail**: 0.8 boundary encoded twice: `computeIntensity` (>=0.8 → high) and `tightSchedule` (>= dailyBudget * 0.8). Two sources of truth that can diverge. `tightSchedule` is fully derivable from `intensity` + `overstuffed` but 6 tests still assert it as primary.
- **Fix**: Make `tightSchedule` a getter: `bool get tightSchedule => intensity == DayIntensity.high && !overstuffed;`. Single threshold, backward compatible.
- **Decision**: PENDING
