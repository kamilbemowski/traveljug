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

  /// Reapplies user overrides to the computed timeline.
  /// Each override moves an attraction to a user-specified day and position.
  /// Slots within each day are sorted by their override position.
  static List<TimelineDay> reapplyOverrides(
    List<TimelineDay> computed,
    Map<int, TimelineOverride> overrides,
  ) {
    if (overrides.isEmpty) return computed;
    if (computed.isEmpty) return computed;

    // Collect all slots with their current day index.
    final allSlots = <_SlotWithOverrides>[];
    for (var d = 0; d < computed.length; d++) {
      for (final slot in computed[d].slots) {
        final ov = overrides[slot.attraction.id];
        allSlots.add(_SlotWithOverrides(
          slot: slot,
          day: ov?.userDay ?? d,
          position: ov?.userPosition ?? 0,
          hasOverride: ov != null,
        ));
      }
    }

    // Group by day.
    final dayMap = <int, List<_SlotWithOverrides>>{};
    for (final s in allSlots) {
      dayMap.putIfAbsent(s.day, () => []).add(s);
    }

    // Sort each day: overridden items first by position, then non-overridden.
    for (final list in dayMap.values) {
      list.sort((a, b) {
        if (a.hasOverride && b.hasOverride) {
          return a.position.compareTo(b.position);
        }
        if (a.hasOverride) return -1;
        if (b.hasOverride) return 1;
        return 0;
      });
    }

    // Build result. Preserve empty days from original timeline.
    final result = <TimelineDay>[];
    final maxDay = dayMap.keys.fold<int>(
        computed.length - 1, (a, b) => a > b ? a : b);
    for (var d = 0; d <= maxDay; d++) {
      final rawSlots = (dayMap[d] ?? []).map((s) => s.slot).toList();
      final date = d < computed.length
          ? computed[d].date
          : computed.last.date.add(Duration(days: d - computed.length + 1));

      // Recompute start times and travel gaps.
      final config = parsePace('intensive').config; // fallback
      final travel = (kDefaultTravelMinutes * config.travelMultiplier).round();
      var currentMin = config.wakeHour * 60;
      var total = 0;
      final adjustedSlots = <TimelineSlot>[];
      for (var i = 0; i < rawSlots.length; i++) {
        final travelGap = i == 0 ? null : travel;
        adjustedSlots.add(TimelineSlot(
          attraction: rawSlots[i].attraction,
          startMin: currentMin + (travelGap ?? 0),
          travelFromPrevMin: travelGap,
        ));
        total += rawSlots[i].attraction.durationMin + (travelGap ?? 0);
        currentMin += rawSlots[i].attraction.durationMin + (travelGap ?? 0);
      }

      final dailyBudget = config.wakingMinutes;
      final overstuffed = total > dailyBudget;
      result.add(TimelineDay(
        date: date,
        slots: adjustedSlots,
        totalMin: total,
        overstuffed: overstuffed,
        tightSchedule: !overstuffed && total >= dailyBudget * 0.8,
      ));
    }

    return result;
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

class _SlotWithOverrides {
  final TimelineSlot slot;
  final int day;
  final int position;
  final bool hasOverride;

  _SlotWithOverrides({
    required this.slot,
    required this.day,
    required this.position,
    required this.hasOverride,
  });
}
