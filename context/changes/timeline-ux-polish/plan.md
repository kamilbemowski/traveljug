# S-05: Timeline UX Polish — Implementation Plan

## Overview

Add a per-day intensity indicator (Low/Medium/High colored bar), replace the text-based "Tight schedule" warning with the intensity system, and add a "Keep Together" toggle per day that forces all attractions to stay on that day (ignoring the budget). Pure UI polish — no algorithm changes.

## Current State Analysis

- `TimelineDay` already has `totalMin`, `overstuffed`, and `tightSchedule` fields.
- `_DaySection` widget renders each day with a colored header and optional overstuffing/tight-schedule banners.
- `TimelineService.computeTimeline()` is a pure function — force-overstuff will be a UI-layer flag, not a DB change.

### Key Discoveries:

- `lib/models/timeline_day.dart:19` — `tightSchedule` already computed at 80%+ budget. This will be replaced by the 3-level intensity system.
- `lib/screens/trip_detail_screen.dart:120-145` — `_DaySection` build method where intensity bar and force toggle will be added.

## Desired End State

Each day card shows a thin colored bar at the top:
- **Green** — Low (<50% of budget used)
- **Yellow/amber** — Medium (50-80%)
- **Orange** — High (>80%, was "tight schedule")

Next to the day header, a small lock icon (🔒/🔓) toggles "Keep Together" mode. When active, that day ignores the waking budget — all attractions stay in it. When inactive, normal greedy-fill behavior applies.

## What We're NOT Doing

- No persistence for force-overstuff state — UI-only, resets on screen reload.
- No per-attraction lock — only per-day "keep together."
- No changes to the timeline computation algorithm.
- No animation for the intensity bar.

## Implementation Approach

`TimelineDay` gets an `intensity` enum field (low/medium/high) computed from `totalMin / budget`. `_DaySection` renders the colored bar and the force toggle. Force-overstuff is a local `StatefulWidget` boolean — when toggled on, the day's header shows a lock icon and the overstuffing warning is suppressed (since the user chose it). The toggle does NOT modify the timeline computation — it's purely a visual override.

---

## Phase 1: Intensity indicator on day cards

### Overview

Add `DayIntensity` enum to `TimelineDay`, compute it in `TimelineService`, and render a colored bar in `_DaySection`. Replace the text-based "Tight schedule" banner.

### Changes Required:

#### 1. DayIntensity enum

**File**: `lib/models/timeline_day.dart`

**Intent**: Replace the boolean `tightSchedule` with a 3-level enum for richer visual feedback.

**Contract**:
- `enum DayIntensity { low, medium, high }`.
- `TimelineDay` gets `DayIntensity get intensity { ... }` computed from `totalMin` and the day's budget (passed via constructor or computed externally).
- Add `intensity` field to `TimelineDay` constructor, computed by `TimelineService`.
- Deprecate `tightSchedule` (keep for backward compat, but UI reads `intensity` instead).

#### 2. Compute intensity in TimelineService

**File**: `lib/services/timeline_service.dart`

**Intent**: Set `intensity` on each `TimelineDay` based on `totalMin / budget` ratio.

**Contract**:
- After computing `totalMin`, set `intensity`:
  - `< 50%` → `DayIntensity.low`
  - `50-80%` → `DayIntensity.medium`
  - `> 80%` → `DayIntensity.high`
- Uses the pace config's `wakingMinutes` as the budget denominator.

#### 3. Colored bar in _DaySection

**File**: `lib/screens/trip_detail_screen.dart` (`_DaySection`)

**Intent**: Show a thin colored bar at the top of each day card, matching the intensity level. Remove the text-based "Tight schedule" banner.

**Contract**:
- Add a `Container` bar (height: 4px, full width) above the day header.
- Colors: `Colors.green` (low), `Colors.amber` (medium), `Colors.orange` (high).
- Remove the orange "Tight schedule" `Container` banner — the bar replaces it.
- Keep the red "Overstuffed" banner for overstuffed days.

#### 4. Update unit tests

**File**: `test/services/timeline_service_test.dart`

**Intent**: Verify intensity is computed correctly.

**Contract**:
- Low: single short attraction (e.g., 60 min / 960 = 6% → low).
- Medium: fill to 60% → medium.
- High: fill to 85% → high (was tightSchedule).

### Success Criteria:

#### Automated Verification:

- `flutter test` — all tests pass, new intensity assertions pass
- `flutter analyze` passes

#### Manual Verification:

- Day with few attractions shows green bar
- Day nearing capacity shows amber bar
- Day near-full shows orange bar
- "Tight schedule" text banner is gone (replaced by bar)

---

## Phase 2: Force-overstuff toggle

### Overview

Add a "Keep Together" toggle per day (lock icon 🔒/🔓). When active, the day ignores the overstuffing warning — all attractions visually stay in that day.

### Changes Required:

#### 1. Keep Together toggle in _DaySection

**File**: `lib/screens/trip_detail_screen.dart` (`_DaySection`)

**Intent**: A small lock icon button next to the day header toggles "Keep Together" mode.

**Contract**:
- Convert `_DaySection` from `StatelessWidget` to `StatefulWidget`.
- Add `bool _keepTogether = false;` state.
- In the day header `Row`, add an `IconButton`:
  - Icon: `_keepTogether ? Icons.lock : Icons.lock_open`
  - Tooltip: "Keep Together" / "Auto-split"
  - On tap: toggle `_keepTogether`.
- When `_keepTogether` is true: suppress the red "Overstuffed" banner (user chose this), show a subtle blue info banner: "Keeping all attractions together."
- The toggle is UI-only — does not persist to DB.

### Success Criteria:

#### Automated Verification:

- `flutter analyze` passes
- `flutter build apk --debug` compiles

#### Manual Verification:

- Tap lock icon on a day → icon changes to locked (🔒)
- Overstuffing warning hidden when locked
- Tap again → unlocked, normal behavior
- Toggle state resets on screen reload (not persisted — by design)

---

## Testing Strategy

### Unit Tests:

- Intensity computation: low/medium/high boundaries verified in existing timeline service tests.

### Widget Tests:

- Intensity bar renders correct color.
- Lock toggle changes icon and suppresses overstuffing warning.

### Manual Testing Steps:

1. Create trip with 2 attractions — day shows green bar.
2. Add more until amber then orange.
3. Force overstuff: tap lock → red banner disappears, blue info appears.
4. Reload screen → toggle resets (by design for MVP).

## Performance Considerations

- Intensity is a simple integer division — O(1), computed once per day.
- Force toggle is a local boolean — no DB writes, no performance impact.

## References

- Roadmap: `context/foundation/roadmap.md` — S-05
- PRD: `context/foundation/prd.md` — FR-005
- GitHub Issue: [#17](https://github.com/kamilbemowski/traveljug/issues/17)

## Progress

> Convention: `- [ ]` pending, `- [x]` done. Append ` — <commit sha>` when a step lands.

### Phase 1: Intensity indicator on day cards

#### Automated

- [x] 1.1 `flutter test` — all tests pass with intensity assertions — a30f7b2
- [x] 1.2 `flutter analyze` passes — a30f7b2

#### Manual

- [x] 1.3 Day cards show colored bar (green/amber/orange) matching intensity
- [x] 1.4 "Tight schedule" text banner replaced by bar

### Phase 2: Force-overstuff toggle

#### Automated

- [ ] 2.1 `flutter analyze` passes
- [ ] 2.2 `flutter build apk --debug` compiles

#### Manual

- [ ] 2.3 Lock icon toggles Keep Together mode
- [ ] 2.4 Overstuffing warning suppressed when locked
