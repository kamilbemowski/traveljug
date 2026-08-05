import '../database/app_database.dart';
import '../models/timeline_day.dart';
import 'geo_utils.dart';
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
    final baseTravel = travelMinutesForContext(parseTravelContext(trip.travelContext));
    final flatTravel = (baseTravel * config.travelMultiplier).round();
    final speedKmh = speedKmhForContext(parseTravelContext(trip.travelContext));

    final days = _dateRange(trip.startDate!, trip.endDate!);
    final timeline = <TimelineDay>[];
    var dayIndex = 0;

    var currentSlots = <TimelineSlot>[];
    var currentTotal = 0;
    Attraction? previousAttr;

    for (final attr in attractions) {
      final isFirstInDay = currentSlots.isEmpty;
      final travelCost = pairTravelMinutes(
        isFirstInDay ? null : previousAttr,
        attr,
        speedKmh: speedKmh,
        fallbackMinutes: flatTravel,
        multiplier: config.travelMultiplier,
      );
      final slotCost = attr.durationMin + travelCost;

      if (currentTotal + slotCost <= dailyBudget) {
        // Fits in current day.
        currentSlots.add(TimelineSlot(
          attraction: attr,
          startMin: config.wakeHour * 60 + currentTotal + travelCost,
          travelFromPrevMin: isFirstInDay ? null : travelCost,
        ));
        currentTotal += slotCost;
      } else if (dayIndex + 1 < days.length) {
        // Move to next day.
        timeline.add(TimelineDay(
          date: days[dayIndex],
          slots: currentSlots,
          totalMin: currentTotal,
          overstuffed: false,
          intensity: computeIntensity(currentTotal, dailyBudget),
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
          travelFromPrevMin: isFirstInDay ? null : travelCost,
        ));
        currentTotal += slotCost;
      }
      previousAttr = attr;
    }

    // Don't forget the last day.
    if (currentSlots.isNotEmpty || dayIndex < days.length) {
      final overstuffed = currentTotal > dailyBudget;
      timeline.add(TimelineDay(
        date: days[dayIndex],
        slots: currentSlots,
        totalMin: currentTotal,
        overstuffed: overstuffed,
        intensity: computeIntensity(currentTotal, dailyBudget),
      ));
    }

    return timeline;
  }

  /// Computes travel minutes between two consecutive attractions using
  /// distance-based estimation when coordinates are available, falling back
  /// to [fallbackMinutes] otherwise. First-in-day always returns 0.
  static int pairTravelMinutes(
    Attraction? prev,
    Attraction current, {
    required double speedKmh,
    required int fallbackMinutes,
    required double multiplier,
  }) {
    if (prev == null) return 0; // first attraction in day
    final km = detourAdjustedKm(
      prev.latitude, prev.longitude,
      current.latitude, current.longitude,
    );
    if (km == null) return fallbackMinutes;
    final baseMinutes = (km / speedKmh * 60).round();
    final buffered = baseMinutes < kMinPairTravelMin
        ? kMinPairTravelMin
        : baseMinutes;
    return (buffered * multiplier).round();
  }

  /// Reapplies user overrides to the computed timeline.
  /// Each override moves an attraction to a user-specified day and position.
  /// Slots within each day are sorted by their override position.
  ///
  /// [pace] and [baseTravel] parameterize travel gap computation the same way
  /// [computeTimeline] does — S-04 travel context flows through here.
  static List<TimelineDay> reapplyOverrides(
    List<TimelineDay> computed,
    Map<int, TimelineOverride> overrides, {
    String pace = 'intensive',
    int baseTravel = kDefaultTravelMinutes,
    double speedKmh = kDefaultSpeedKmh,
  }) {
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
      final config = parsePace(pace).config;
      final fallback = (baseTravel * config.travelMultiplier).round();
      var currentMin = config.wakeHour * 60;
      var total = 0;
      final adjustedSlots = <TimelineSlot>[];
      for (var i = 0; i < rawSlots.length; i++) {
        final travelPair = pairTravelMinutes(
          i == 0 ? null : rawSlots[i - 1].attraction,
          rawSlots[i].attraction,
          speedKmh: speedKmh,
          fallbackMinutes: fallback,
          multiplier: config.travelMultiplier,
        );
        final travelGap = i == 0 ? null : travelPair;
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
        intensity: computeIntensity(total, dailyBudget),
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
