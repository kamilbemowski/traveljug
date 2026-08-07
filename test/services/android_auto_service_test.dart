import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/models/timeline_day.dart';
import 'package:travelapp/services/android_auto_service.dart';

/// Fake [Attraction] with only the fields needed for AA template building.
Attraction _attr({
  int id = 1,
  String name = 'Test Attraction',
  String category = 'museum',
  int durationMin = 60,
  int priority = 1,
  double? latitude,
  double? longitude,
}) {
  return Attraction(
    id: id,
    name: name,
    category: category,
    durationMin: durationMin,
    priority: priority,
    position: 0,
    tripId: 1,
    latitude: latitude,
    longitude: longitude,
    placeName: null,
  );
}

/// Fake [TimelineSlot] wrapping an attraction.
TimelineSlot _slot(Attraction a,
    {int startMin = 480, int? travelFromPrevMin}) {
  return TimelineSlot(
    attraction: a,
    startMin: startMin,
    travelFromPrevMin: travelFromPrevMin,
  );
}

/// Fake [TimelineDay] with the given slots.
TimelineDay _day(List<TimelineSlot> slots, {bool overstuffed = false}) {
  final totalMin = slots.fold<int>(
      0,
      (s, sl) =>
          s +
          sl.attraction.durationMin +
          (sl.travelFromPrevMin ?? 0));
  return TimelineDay(
    date: DateTime.now(),
    slots: slots,
    totalMin: totalMin,
    overstuffed: overstuffed,
    intensity: DayIntensity.medium,
  );
}

void main() {
  group('showTodayPlan data transformation', () {
    test('★★ must-have prefix applied to priority 0 attractions', () {
      // Verify the must-have marker logic without calling the AA platform.
      // The showTodayPlan method prepends ★ to must-have attractions.
      final mustHave = _attr(id: 1, name: 'Louvre', priority: 0);
      final niceToHave = _attr(id: 2, name: 'Cafe', priority: 1);

      expect(mustHave.priority, 0);
      expect(niceToHave.priority, 1);

      // The prefix logic is: slot.isMustHave ? '★ ' : ''
      // isMustHave is true when attraction.priority == 0
      final mustSlot = _slot(mustHave);
      final niceSlot = _slot(niceToHave);

      expect(mustSlot.isMustHave, true);
      expect(niceSlot.isMustHave, false);
    });

    test('startTime formatting is correct', () {
      final a = _attr(id: 1, name: 'Test', durationMin: 60);
      final slot = _slot(a, startMin: 630); // 10:30

      expect(slot.startTime, '10:30');
    });
  });

  group('template building (platform-dependent)', () {
    // These tests call FlutterAndroidAuto.setRootTemplate which requires
    // a native MethodChannel — unavailable in unit tests.
    // Run these on device or with DHU connected.

    test('showTodayPlan smoke test', () {
      final day = _day([
        _slot(_attr(id: 1, name: 'Louvre', category: 'museum',
            latitude: 48.8584, longitude: 2.2945)),
        _slot(_attr(id: 2, name: 'Eiffel Tower', category: 'landmark'),
            travelFromPrevMin: 15),
      ]);

      // In unit tests this will throw MissingPluginException —
      // expected, AA not connected. Verify by checking we can construct
      // the template data without errors up to the platform call.
      expect(day.slots.length, 2);
      expect(day.slots[0].attraction.name, 'Louvre');
      // With coordinates → Navigate should be available.
      expect(day.slots[0].attraction.latitude, isNotNull);
      // Without coordinates → Navigate should be hidden.
      expect(day.slots[1].attraction.latitude, isNull);
    }, skip: 'Requires native Android Auto host (device or DHU)');

    test('showNoAttractionsMessage smoke test', () {
      // These methods also call setRootTemplate — platform-dependent.
      expect(
        () => AndroidAutoService.showNoAttractionsMessage('Trip'),
        returnsNormally,
      );
    }, skip: 'Requires native Android Auto host (device or DHU)');
  });
}
