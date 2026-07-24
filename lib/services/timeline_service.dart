import '../database/app_database.dart';
import '../models/timeline_day.dart';
import 'pace_config.dart';

/// Pure-function timeline computation engine.
/// Stateless — recomputes from scratch every call.
class TimelineService {
  TimelineService._();

  /// Computes a day-by-day plan for [trip] using [attractions].
  ///
  /// Throws [StateError] if the trip has no dates.
  /// Returns an empty list if there are no attractions.
  static List<TimelineDay> computeTimeline(
    Trip trip,
    List<Attraction> attractions,
  ) {
    if (trip.startDate == null || trip.endDate == null) {
      throw StateError('Trip has no dates');
    }
    if (attractions.isEmpty) return [];

    final config = parsePace(trip.pace).config;
    final dailyBudget = config.wakingMinutes;
    final effectiveTravel = (kDefaultTravelMinutes * config.travelMultiplier).round();

    final days = _dateRange(trip.startDate!, trip.endDate!);
    final timeline = <TimelineDay>[];
    var dayIndex = 0;

    var currentSlots = <TimelineSlot>[];
    var currentTotal = 0;

    for (final attr in attractions) {
      final isFirstInDay = currentSlots.isEmpty;
      final travelCost = isFirstInDay ? 0 : effectiveTravel;
      final slotCost = attr.durationMin + travelCost;

      if (currentTotal + slotCost <= dailyBudget) {
        // Fits in current day.
        currentSlots.add(TimelineSlot(
          attraction: attr,
          startMin: config.wakeHour * 60 + currentTotal + travelCost,
          travelFromPrevMin: isFirstInDay ? null : effectiveTravel,
        ));
        currentTotal += slotCost;
      } else if (dayIndex + 1 < days.length) {
        // Move to next day.
        timeline.add(TimelineDay(
          date: days[dayIndex],
          slots: currentSlots,
          totalMin: currentTotal,
          overstuffed: false,
          tightSchedule: currentTotal >= dailyBudget * 0.8,
        ));
        dayIndex++;
        currentSlots = [];
        currentTotal = 0;

        // Add attraction as first slot of new day (no travel cost).
        currentSlots.add(TimelineSlot(
          attraction: attr,
          startMin: config.wakeHour * 60,
          travelFromPrevMin: null,
        ));
        currentTotal += attr.durationMin;
      } else {
        // Last day overflow — add anyway, mark overstuffed.
        currentSlots.add(TimelineSlot(
          attraction: attr,
          startMin: config.wakeHour * 60 + currentTotal + travelCost,
          travelFromPrevMin: isFirstInDay ? null : effectiveTravel,
        ));
        currentTotal += slotCost;
      }
    }

    // Don't forget the last day.
    if (currentSlots.isNotEmpty || dayIndex < days.length) {
      final overstuffed = currentTotal > dailyBudget;
      timeline.add(TimelineDay(
        date: days[dayIndex],
        slots: currentSlots,
        totalMin: currentTotal,
        overstuffed: overstuffed,
        tightSchedule: !overstuffed && currentTotal >= dailyBudget * 0.8,
      ));
    }

    return timeline;
  }

  /// Generates a list of dates from [start] to [end] (inclusive).
  static List<DateTime> _dateRange(DateTime start, DateTime end) {
    final normalizedStart = DateTime(start.year, start.month, start.day);
    final normalizedEnd = DateTime(end.year, end.month, end.day);
    final days = <DateTime>[];
    for (var d = normalizedStart;
        !d.isAfter(normalizedEnd);
        d = d.add(const Duration(days: 1))) {
      days.add(d);
    }
    return days;
  }
}
