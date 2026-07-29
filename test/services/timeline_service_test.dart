import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/services/timeline_service.dart';

/// A minimal fake [Trip] with only the fields computeTimeline needs.
Trip _trip({
  int? id,
  required DateTime startDate,
  required DateTime endDate,
  String pace = 'intensive',
}) {
  return Trip(
    id: id ?? 1,
    name: 'Test',
    destination: 'Test',
    startDate: startDate,
    endDate: endDate,
    pace: pace,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
    imageUrl: null,
  );
}

/// A minimal fake [Attraction] with only the fields computeTimeline needs.
Attraction _attr({
  int? id,
  required int durationMin,
  int priority = 1,
  int position = 0,
  int tripId = 1,
}) {
  return Attraction(
    id: id ?? 1,
    name: 'Test Attraction',
    category: 'other',
    durationMin: durationMin,
    priority: priority,
    position: position,
    tripId: tripId,
  );
}

void main() {
  group('TimelineService.computeTimeline', () {
    final today = DateTime(2026, 7, 24);

    test('empty attractions returns empty list', () {
      final trip = _trip(startDate: today, endDate: today);
      expect(TimelineService.computeTimeline(trip, []), isEmpty);
    });

    test('trip without dates throws StateError', () {
      final trip = Trip(
        id: 1,
        name: 'No dates',
        destination: 'Nowhere',
        startDate: null,
        endDate: null,
        pace: 'intensive',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        imageUrl: null,
      );
      expect(
        () => TimelineService.computeTimeline(trip, [_attr(durationMin: 60)]),
        throwsStateError,
      );
    });

    test('single attraction — one day, one slot, no travel, no overstuffing', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(
        trip,
        [_attr(id: 1, durationMin: 60)],
      );

      expect(result.length, 1);
      expect(result[0].slots.length, 1);
      expect(result[0].slots[0].startTime, '07:00'); // wakeHour = 7
      expect(result[0].slots[0].travelFromPrevMin, isNull);
      expect(result[0].overstuffed, isFalse);
    });

    test('two attractions fit in one day', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 60, position: 0),
          _attr(id: 2, durationMin: 60, position: 1),
        ],
      );

      expect(result.length, 1);
      expect(result[0].slots.length, 2);
      // Slot 1: starts at 07:00, no travel
      expect(result[0].slots[0].startMin, 420); // 7 * 60
      // Slot 2: starts at 07:00 + 60min + 21min travel (intensive: 30 * 0.7 = 21)
      expect(result[0].slots[1].startMin, 420 + 60 + 21);
      expect(result[0].slots[1].travelFromPrevMin, 21);
      expect(result[0].overstuffed, isFalse);
    });

    test('three attractions forcing day split', () {
      final trip = _trip(
        startDate: today,
        endDate: today.add(const Duration(days: 1)),
      );
      // Intensive: 960 min/day, 2 days.
      // Slot 1: 500 + 0 travel = 500. Total day1 = 500.
      // Slot 2: 500 + 21 travel = 521. 500 + 521 = 1021 > 960 → split to day 2.
      // Day 2: slot 2 (500, 0 travel) = 500.
      // Slot 3: 500 + 21 = 521. 500 + 521 = 1021 > 960 → no more days, overstuff.
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 500, position: 0),
          _attr(id: 2, durationMin: 500, position: 1),
          _attr(id: 3, durationMin: 500, position: 2),
        ],
      );

      expect(result.length, 2);
      expect(result[0].slots.length, 1); // day 1 gets only slot 1 (slot 2 overflowed it)
      expect(result[1].slots.length, 2); // day 2 gets slot 2 + overflowing slot 3
      expect(result[1].overstuffed, isTrue);
      expect(result[1].slots[0].travelFromPrevMin, isNull); // first in day 2
    });

    test('three short attractions all fit in one day', () {
      final trip = _trip(
        startDate: today,
        endDate: today.add(const Duration(days: 1)),
      );
      // Short enough to all fit. 60 + 60+21 + 60+21 = 222 < 960.
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 60, position: 0),
          _attr(id: 2, durationMin: 60, position: 1),
          _attr(id: 3, durationMin: 60, position: 2),
        ],
      );

      expect(result.length, 1);
      expect(result[0].slots.length, 3);
    });

    test('exact boundary — no overstuffing, but tight schedule', () {
      final trip = _trip(startDate: today, endDate: today);
      // Intensive: 960 min budget. 939 min = 97.8% > 80% → tightSchedule.
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 939, position: 0),
        ],
      );

      expect(result.length, 1);
      expect(result[0].overstuffed, isFalse);
      expect(result[0].tightSchedule, isTrue);
    });

    test('one minute over boundary — overstuffing triggered', () {
      final trip = _trip(startDate: today, endDate: today);
      // First slot: 800 (no travel). Second: 160 + 21 travel = 181. Total = 981 > 960.
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 800, position: 0),
          _attr(id: 2, durationMin: 160, position: 1),
        ],
      );

      expect(result.length, 1);
      expect(result[0].slots.length, 2);
      expect(result[0].overstuffed, isTrue);
    });

    test('relaxing pace overstuffs earlier than intensive', () {
      final tripIntensive = _trip(startDate: today, endDate: today, pace: 'intensive');
      final tripRelaxing = _trip(startDate: today, endDate: today, pace: 'relaxing');

      // 2 slots: first 500 (no travel), second 120 + travel.
      // Intensive: 500 + 120 + 21 = 641 < 960 → no overstuff.
      // Relaxing: 500 + 120 + 45 = 665 > 600 → overstuffed.
      final resultIntensive = TimelineService.computeTimeline(
        tripIntensive,
        [
          _attr(id: 1, durationMin: 500, position: 0),
          _attr(id: 2, durationMin: 120, position: 1),
        ],
      );
      final resultRelaxing = TimelineService.computeTimeline(
        tripRelaxing,
        [
          _attr(id: 1, durationMin: 500, position: 0),
          _attr(id: 2, durationMin: 120, position: 1),
        ],
      );

      expect(resultIntensive[0].overstuffed, isFalse);
      expect(resultRelaxing[0].overstuffed, isTrue);
    });

    test('travel time between slots is accounted', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 60, position: 0),
          _attr(id: 2, durationMin: 60, position: 1),
          _attr(id: 3, durationMin: 60, position: 2),
        ],
      );

      // 3 slots: travel appears between 1-2 and 2-3.
      expect(result[0].slots[0].travelFromPrevMin, isNull);
      expect(result[0].slots[1].travelFromPrevMin, 21); // 30 * 0.7
      expect(result[0].slots[2].travelFromPrevMin, 21);
    });

    test('priority 0 slots are marked mustHave', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(
        trip,
        [
          _attr(id: 1, durationMin: 60, priority: 0, position: 0),
          _attr(id: 2, durationMin: 60, priority: 1, position: 1),
          _attr(id: 3, durationMin: 60, priority: 2, position: 2),
        ],
      );

      expect(result[0].slots[0].isMustHave, isTrue);
      expect(result[0].slots[1].isMustHave, isFalse);
      expect(result[0].slots[2].isMustHave, isFalse);
    });

    test('exactly at budget — not overstuffed', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(trip, [_attr(id: 1, durationMin: 960)]);
      expect(result[0].overstuffed, isFalse);
    });

    test('exactly at 80% — tightSchedule=true', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(trip, [_attr(id: 1, durationMin: 768)]);
      expect(result[0].tightSchedule, isTrue);
      expect(result[0].overstuffed, isFalse);
    });

    test('one below 80% — tightSchedule=false', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(trip, [_attr(id: 1, durationMin: 767)]);
      expect(result[0].tightSchedule, isFalse);
    });

    test('one above budget — overstuffed=true', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(trip, [_attr(id: 1, durationMin: 961)]);
      expect(result[0].overstuffed, isTrue);
    });

    test('tightSchedule on split non-final day at 85%', () {
      final trip = _trip(startDate: today, endDate: today.add(const Duration(days: 2)));
      final result = TimelineService.computeTimeline(trip, [
        _attr(id: 1, durationMin: 820, position: 0),
        _attr(id: 2, durationMin: 200, position: 1),
      ]);
      expect(result[0].tightSchedule, isTrue);
      expect(result[0].overstuffed, isFalse);
    });

    test('5-day trip with 12 attractions', () {
      final trip = _trip(startDate: today, endDate: today.add(const Duration(days: 4)));
      final attrs = List.generate(12, (i) => _attr(id: i + 1, durationMin: 120, position: i));
      final result = TimelineService.computeTimeline(trip, attrs);
      expect(result.length, greaterThan(1));
    });

    test('reversed dates crash', () {
      final trip = _trip(startDate: today.add(const Duration(days: 2)), endDate: today);
      expect(
        () => TimelineService.computeTimeline(trip, [_attr(id: 1, durationMin: 60)]),
        throwsA(isA<RangeError>()),
      );
    });

    test('startMin overflow on overstuffed day', () {
      final trip = _trip(startDate: today, endDate: today);
      final result = TimelineService.computeTimeline(trip, [
        _attr(id: 1, durationMin: 500, position: 0),
        _attr(id: 2, durationMin: 480, position: 1),
        _attr(id: 3, durationMin: 120, position: 2),
      ]);
      expect(result[0].overstuffed, isTrue);
      expect(result[0].slots[2].startMin, greaterThan(1440));
    });

    test('relaxing first slot at 10:00', () {
      final trip = _trip(startDate: today, endDate: today, pace: 'relaxing');
      final result = TimelineService.computeTimeline(trip, [_attr(id: 1, durationMin: 60)]);
      expect(result[0].slots[0].startMin, 600);
    });

    test('relaxing travel gap 45 min', () {
      final trip = _trip(startDate: today, endDate: today, pace: 'relaxing');
      final result = TimelineService.computeTimeline(trip, [
        _attr(id: 1, durationMin: 60, position: 0),
        _attr(id: 2, durationMin: 60, position: 1),
      ]);
      expect(result[0].slots[1].travelFromPrevMin, 45);
    });
  });
}
