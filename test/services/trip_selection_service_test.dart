import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/database/daos/trip_dao.dart';
import 'package:travelapp/services/trip_selection_service.dart';

void main() {
  late AppDatabase db;
  late TripDao tripDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    setTestDatabase(db);
    tripDao = TripDao(db);
  });

  tearDown(() async {
    clearTestDatabase();
    await db.close();
  });

  group('resolveForAndroidAuto', () {
    test('active trip with today dates returned first', () async {
      final yesterday = DateTime(2026, 8, 5);
      final tomorrow = DateTime(2026, 8, 7);

      await tripDao.createTrip(
        name: 'Inactive Today',
        destination: 'London',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: false,
      );
      await tripDao.createTrip(
        name: 'Active Today',
        destination: 'Paris',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: true,
      );

      final result =
          await TripSelectionService.resolveForAndroidAuto(tripDao);
      expect(result, isNotNull);
      expect(result!.name, 'Active Today');
    });

    test('no active trip falls back to last-opened by updatedAt', () async {
      final yesterday = DateTime(2026, 8, 5);
      final tomorrow = DateTime(2026, 8, 7);

      await tripDao.createTrip(
        name: 'First Created',
        destination: 'Paris',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: false,
      );
      final secondId = await tripDao.createTrip(
        name: 'Second Created',
        destination: 'London',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: false,
      );
      // Bump Second's updatedAt so it becomes "last opened".
      await tripDao.updateTrip(secondId, name: 'Second Created');

      final result =
          await TripSelectionService.resolveForAndroidAuto(tripDao);
      expect(result, isNotNull);
      expect(result!.name, 'Second Created');
    });

    test('no trips at all returns null', () async {
      final result =
          await TripSelectionService.resolveForAndroidAuto(tripDao);
      expect(result, isNull);
    });

    test('multiple active trips — first by updatedAt', () async {
      final yesterday = DateTime(2026, 8, 5);
      final tomorrow = DateTime(2026, 8, 7);

      await tripDao.createTrip(
        name: 'First Active',
        destination: 'Paris',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: true,
      );
      final secondId = await tripDao.createTrip(
        name: 'Second Active',
        destination: 'London',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: true,
      );
      // Bump second's updatedAt.
      await tripDao.updateTrip(secondId, name: 'Second Active');

      final result =
          await TripSelectionService.resolveForAndroidAuto(tripDao);
      expect(result, isNotNull);
      expect(result!.name, 'Second Active');
    });

    test('active trip with future dates is skipped', () async {
      final yesterday = DateTime(2026, 8, 5);
      final tomorrow = DateTime(2026, 8, 7);
      final future = DateTime(2026, 9, 6);
      final futureEnd = DateTime(2026, 9, 10);

      // Active trip in the future — should NOT match level 1.
      await tripDao.createTrip(
        name: 'Future Active',
        destination: 'Tokyo',
        startDate: future,
        endDate: futureEnd,
        isActive: true,
      );
      // Inactive trip covering today — will match level 2.
      final inactiveId = await tripDao.createTrip(
        name: 'Inactive Today',
        destination: 'Paris',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: false,
      );
      // Bump Inactive Today's updatedAt to guarantee it's first at level 2.
      await tripDao.updateTrip(inactiveId, name: 'Inactive Today');

      final result =
          await TripSelectionService.resolveForAndroidAuto(tripDao);
      expect(result, isNotNull);
      expect(result!.name, 'Inactive Today');
    });

    test('trip without dates falls to last-opened', () async {
      final yesterday = DateTime(2026, 8, 5);
      final tomorrow = DateTime(2026, 8, 7);

      await tripDao.createTrip(
        name: 'Dateless Trip',
        destination: 'Nowhere',
        startDate: null,
        endDate: null,
      );
      final datedId = await tripDao.createTrip(
        name: 'Dated Trip',
        destination: 'Paris',
        startDate: yesterday,
        endDate: tomorrow,
        isActive: false,
      );
      // Bump Dated Trip's updatedAt.
      await tripDao.updateTrip(datedId, name: 'Dated Trip');

      final result =
          await TripSelectionService.resolveForAndroidAuto(tripDao);
      expect(result, isNotNull);
      expect(result!.name, 'Dated Trip');
    });
  });

  group('listForSelection', () {
    test('returns all trips ordered by updatedAt DESC', () async {
      await tripDao.createTrip(name: 'A', destination: 'A');
      await tripDao.createTrip(name: 'B', destination: 'B');
      final cId = await tripDao.createTrip(name: 'C', destination: 'C');
      // Bump C's updatedAt so it's first.
      await tripDao.updateTrip(cId, name: 'C');

      final result = await TripSelectionService.listForSelection(tripDao);
      expect(result.length, 3);
      expect(result[0].name, 'C'); // bumped
      // B and A have same updatedAt — both created in sequence, B after A.
      // listAllTrips returns by createdAt DESC, then we sort by updatedAt.
      // With tied updatedAt, sort is stable (B stays before A if B was after A
      // in original listAllTrips, but that depends on createdAt ordering too).
      // Both have same timestamps — just verify C is first and count is 3.
      expect(result.length, 3);
    });
  });
}
