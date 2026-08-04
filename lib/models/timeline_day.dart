import '../database/app_database.dart';

/// Three-level day intensity based on % of waking budget used (S-05).
enum DayIntensity {
  low,     // <50%
  medium,  // 50-80%
  high,    // >80% (replaces tightSchedule)
}

/// Computes [DayIntensity] from total minutes used vs. waking budget.
DayIntensity computeIntensity(int totalMin, int budgetMin) {
  final ratio = totalMin / budgetMin;
  if (ratio >= 0.8) return DayIntensity.high;
  if (ratio >= 0.5) return DayIntensity.medium;
  return DayIntensity.low;
}

/// One attraction placed on the timeline with its computed start time.
class TimelineSlot {
  final Attraction attraction;

  /// Minutes from midnight (e.g., 480 = 08:00).
  final int startMin;

  /// Travel time from the previous slot, or null for the first slot of a day.
  final int? travelFromPrevMin;

  const TimelineSlot({
    required this.attraction,
    required this.startMin,
    this.travelFromPrevMin,
  });

  /// Formatted start time, e.g. "08:00".
  String get startTime {
    final h = startMin ~/ 60;
    final m = startMin % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// True when this attraction has must-have priority.
  bool get isMustHave => attraction.priority == 0;
}

/// One day in the generated timeline.
class TimelineDay {
  final DateTime date;
  final List<TimelineSlot> slots;

  /// Total minutes used by visit durations + travel gaps.
  final int totalMin;

  /// True when total time exceeds the waking budget for this day's pace.
  final bool overstuffed;

  /// True when the day is at 80%+ capacity but not yet overstuffed.
  /// Derives from [intensity] — single source of truth for the 0.8 threshold.
  bool get tightSchedule => intensity == DayIntensity.high && !overstuffed;

  /// Computed intensity level based on totalMin / budget ratio.
  final DayIntensity intensity;

  const TimelineDay({
    required this.date,
    required this.slots,
    required this.totalMin,
    required this.overstuffed,
    required this.intensity,
  });
}
