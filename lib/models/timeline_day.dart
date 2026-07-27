import '../database/app_database.dart';

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
  final bool tightSchedule;

  const TimelineDay({
    required this.date,
    required this.slots,
    required this.totalMin,
    required this.overstuffed,
    required this.tightSchedule,
  });
}
