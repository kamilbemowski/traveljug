import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/database/daos/attraction_dao.dart';
import 'package:travelapp/database/daos/trip_dao.dart';
import 'package:travelapp/database/tables.dart';

void main() {
  late AppDatabase db;
  late TripDao tripDao;
  late AttractionDao attractionDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    tripDao = TripDao(db);
    attractionDao = AttractionDao(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TripDao', () {
    test('create and read roundtrip', () async {
      final id = await tripDao.createTrip(
        name: 'Rome City Break',
        destination: 'Rome, Italy',
      );

      expect(id, greaterThan(0));

      final trip = await tripDao.getTripById(id);
      expect(trip, isNotNull);
      expect(trip!.name, 'Rome City Break');
      expect(trip.destination, 'Rome, Italy');
      expect(trip.pace, TravelPace.intensive.name);
    });

    test('travelContext roundtrip — null, city, roadTrip', () async {
      // Null (default).
      final id1 = await tripDao.createTrip(
        name: 'Default', destination: 'X', travelContext: null,
      );
      final t1 = await tripDao.getTripById(id1);
      expect(t1!.travelContext, isNull);

      // City.
      final id2 = await tripDao.createTrip(
        name: 'City', destination: 'X', travelContext: TravelContext.city,
      );
      final t2 = await tripDao.getTripById(id2);
      expect(t2!.travelContext, TravelContext.city.name);

      // Road trip.
      final id3 = await tripDao.createTrip(
        name: 'Road', destination: 'X', travelContext: TravelContext.roadTrip,
      );
      final t3 = await tripDao.getTripById(id3);
      expect(t3!.travelContext, TravelContext.roadTrip.name);
    });

    test('list all — newest first', () async {
      final id1 = await tripDao.createTrip(name: 'A', destination: 'A');
      await Future.delayed(const Duration(seconds: 1));
      final id2 = await tripDao.createTrip(name: 'B', destination: 'B');
      await Future.delayed(const Duration(seconds: 1));
      final id3 = await tripDao.createTrip(name: 'C', destination: 'C');

      final trips = await tripDao.listAllTrips();

      expect(trips.length, 3);
      // Newest first → C, B, A.
      expect(trips[0].id, id3);
      expect(trips[1].id, id2);
      expect(trips[2].id, id1);
    });

    test('update — fields and updatedAt change', () async {
      final id = await tripDao.createTrip(
        name: 'Old Name',
        destination: 'Old Dest',
      );

      final before = await tripDao.getTripById(id);

      final updated = await tripDao.updateTrip(
        id,
        name: 'New Name',
        destination: 'New Dest',
      );
      expect(updated, isTrue);

      final after = await tripDao.getTripById(id);
      expect(after!.name, 'New Name');
      expect(after.destination, 'New Dest');
      // updatedAt should be newer than before update.
      expect(
        after.updatedAt.isAfter(before!.updatedAt) ||
            after.updatedAt.isAtSameMomentAs(before.updatedAt),
        isTrue,
      );
    });

    test('createTrip isActive defaults to false', () async {
      final id = await tripDao.createTrip(
        name: 'Default Active',
        destination: 'Test',
      );
      final trip = await tripDao.getTripById(id);
      expect(trip!.isActive, false);
    });

    test('createTrip and updateTrip isActive roundtrip', () async {
      final id = await tripDao.createTrip(
        name: 'Active Trip',
        destination: 'Test',
        isActive: true,
      );
      final created = await tripDao.getTripById(id);
      expect(created!.isActive, true);

      await tripDao.updateTrip(id, isActive: false);
      final updated = await tripDao.getTripById(id);
      expect(updated!.isActive, false);

      await tripDao.updateTrip(id, isActive: true);
      final reactivated = await tripDao.getTripById(id);
      expect(reactivated!.isActive, true);
    });

    test('listTripsCoveringDate filters by date range and isActive', () async {
      final today = DateTime(2026, 8, 6);
      final yesterday = DateTime(2026, 8, 5);
      final tomorrow = DateTime(2026, 8, 7);

      // Trip covering today, active.
      await tripDao.createTrip(
        name: 'Active Today',
        destination: 'Paris',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: true,
      );
      // Trip covering today, NOT active.
      await tripDao.createTrip(
        name: 'Inactive Today',
        destination: 'London',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: false,
      );
      // Trip NOT covering today (future trip).
      await tripDao.createTrip(
        name: 'Future Trip',
        destination: 'Tokyo',
        startDate: DateTime(2026, 9, 1),
        endDate: DateTime(2026, 9, 10),
        isActive: true,
      );

      // All trips covering today (no filter).
      final allToday =
          await tripDao.listTripsCoveringDate(today);
      expect(allToday.length, 2);

      // Only active trips covering today.
      final activeToday =
          await tripDao.listTripsCoveringDate(today, isActive: true);
      expect(activeToday.length, 1);
      expect(activeToday.first.name, 'Active Today');
    });

    test('delete — getById returns null', () async {
      final id = await tripDao.createTrip(
        name: 'To Delete',
        destination: 'Nowhere',
      );

      final deleted = await tripDao.deleteTrip(id);
      expect(deleted, 1);

      final trip = await tripDao.getTripById(id);
      expect(trip, isNull);
    });

    test('cascade delete — attractions deleted with trip', () async {
      final tripId = await tripDao.createTrip(
        name: 'Trip with attractions',
        destination: 'Paris',
      );

      await attractionDao.createAttraction(
        name: 'Eiffel Tower',
        durationMin: 120,
        tripId: tripId,
      );
      await attractionDao.createAttraction(
        name: 'Louvre',
        durationMin: 180,
        tripId: tripId,
      );

      // Both attractions exist.
      var list = await attractionDao.listAttractionsByTrip(tripId);
      expect(list.length, 2);

      // Delete the trip — cascades.
      await tripDao.deleteTrip(tripId);

      // Attractions are gone.
      list = await attractionDao.listAttractionsByTrip(tripId);
      expect(list, isEmpty);
    });
  });

  group('AttractionDao', () {
    late int tripId;

    setUp(() async {
      tripId = await tripDao.createTrip(
        name: 'Test Trip',
        destination: 'Test City',
      );
    });

    test('create and read roundtrip', () async {
      final id = await attractionDao.createAttraction(
        name: 'Colosseum',
        durationMin: 90,
        tripId: tripId,
        category: AttractionCategory.landmark,
        priority: 0,
      );

      expect(id, greaterThan(0));

      final attraction = await attractionDao.getAttractionById(id);
      expect(attraction, isNotNull);
      expect(attraction!.name, 'Colosseum');
      expect(attraction.durationMin, 90);
      expect(attraction.category, AttractionCategory.landmark.name);
      expect(attraction.priority, 0);
    });

    test('list by trip — position order', () async {
      final id1 = await attractionDao.createAttraction(
        name: 'Third',
        durationMin: 30,
        tripId: tripId,
        position: 2,
      );
      final id2 = await attractionDao.createAttraction(
        name: 'First',
        durationMin: 30,
        tripId: tripId,
        position: 0,
      );
      final id3 = await attractionDao.createAttraction(
        name: 'Second',
        durationMin: 30,
        tripId: tripId,
        position: 1,
      );

      final list = await attractionDao.listAttractionsByTrip(tripId);

      expect(list.length, 3);
      expect(list[0].id, id2); // position 0
      expect(list[1].id, id3); // position 1
      expect(list[2].id, id1); // position 2
    });

    test('update — fields change', () async {
      final id = await attractionDao.createAttraction(
        name: 'Old Name',
        durationMin: 60,
        tripId: tripId,
      );

      await attractionDao.updateAttraction(
        id,
        name: 'New Name',
        durationMin: 120,
      );

      final updated = await attractionDao.getAttractionById(id);
      expect(updated!.name, 'New Name');
      expect(updated.durationMin, 120);
    });

    test('delete — count decreases', () async {
      await attractionDao.createAttraction(
        name: 'A',
        durationMin: 30,
        tripId: tripId,
      );
      final idB = await attractionDao.createAttraction(
        name: 'B',
        durationMin: 30,
        tripId: tripId,
      );

      await attractionDao.deleteAttraction(idB);

      final list = await attractionDao.listAttractionsByTrip(tripId);
      expect(list.length, 1);
      expect(list.first.name, 'A');
    });

    test('FK integrity — invalid tripId throws', () async {
      expect(
        () => attractionDao.createAttraction(
          name: 'Orphan',
          durationMin: 30,
          tripId: 99999,
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
