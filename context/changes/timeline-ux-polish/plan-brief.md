# S-05: Timeline UX Polish — Plan Brief

> Full plan: `context/changes/timeline-ux-polish/plan.md`

## What & Why

Timeline dziala, ale brakuje wizualnej informacji zwrotnej o zapelnieniu dnia i kontroli nad tym, czy atrakcje maja byc razem. S-05 dodaje kolorowy pasek intensywnosci (zielony/zolty/pomaranczowy) zamiast tekstowego "Tight schedule" oraz przelacznik "Keep Together" zeby wymusic trzymanie atrakcji razem w jednym dniu.

## Starting Point

`TimelineDay` ma `totalMin`, `overstuffed`, `tightSchedule`. `_DaySection` renderuje karty dnia z naglowkami i banerami. Wszystko dziala — to tylko polish.

## Desired End State

Kazdy dzien ma kolorowy pasek na gorze: zielony (<50%), zolty (50-80%), pomaranczowy (>80%). Przy naglowku dnia ikona klodki pozwala wymusic "Keep Together" — atrakcje zostaja razem, nawet jesli dzien jest przepełniony.

## Key Decisions Made

| Decision | Choice | Why (1 sentence) | Source |
|---|---|---|---|
| Intensity levels | Low (<50%), Medium (50-80%), High (>80%) | Proste progi, latwe do zrozumienia. | Plan |
| Force overstuff UX | Per-day Lock icon toggle | Naturalne — klodka = trzymaj razem. UI-only, nie persistuje. | Plan |
| Visual | Colored bar + lock icon | Bar daje natychmiastowy wizualny feedback, ikona jest intuicyjna. | Plan |
| Persistence | UI-only toggle | MVP — nie warto dodawac stanu w DB dla eksperymentalnego feature'u. | Plan |

## Scope

**In scope:** DayIntensity enum (low/medium/high), colored bar on day cards, Lock toggle per day, suppress overstuffing when locked.

**Out of scope:** Persistence of toggle state, per-attraction lock, animations, DB changes.

## Architecture / Approach

```
TimelineDay.intensity ← computed from totalMin / wakingMinutes
    ↓
_DaySection (now StatefulWidget):
  - colored bar (4px Container at top)
  - lock icon button in header
  - conditional overstuffing banner
```

## Phases at a Glance

| Phase | What it delivers | Key risk |
|---|---|---|
| 1. Intensity bars | Colored bars + removed "Tight schedule" text | None — pure UI addition |
| 2. Force toggle | Lock icon per day + suppressed overstuffing | None — local state only |

**Prerequisites:** S-02 (timeline-generation) ✅
**Estimated effort:** ~1 sesja — 2 fazy, czysty UI polish.
