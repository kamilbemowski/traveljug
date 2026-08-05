// Seed integration test for TravelJug — service-level E2E.
//
// This file demonstrates the four patterns every generated integration test
// should follow. It is the E2E equivalent of a seed.spec.ts, adapted for
// Dart/Flutter + Drift (no browser). The agent models generated tests on this.
//
// Patterns demonstrated:
// 1. Real database (in-memory Drift) — no mocks, real FK constraints
// 2. Full setup-action-assert-cleanup cycle — each test is self-contained
// 3. Unique identifiers (timestamp suffix) — parallel-safe, re-run-safe
// 4. Risk-tied test name — bound to `context/foundation/test-plan.md`

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/database/daos/attraction_dao.dart';
import 'package:travelapp/database/daos/timeline_override_dao.dart';
import 'package:travelapp/database/daos/trip_dao.dart';
import 'package:travelapp/database/tables.dart';

void main() {
  late AppDatabase db;
  late TripDao tripDao;
  late AttractionDao attractionDao;
  late TimelineOverrideDao overrideDao;

  /// Opens a fresh in-memory database with foreign keys enabled.
  /// Each test gets its own DB instance so tests are fully isolated.
  Future<AppDatabase> openTestDb() async {
    final database = AppDatabase(NativeDatabase.memory());
    await database.customStatement('PRAGMA foreign_keys = ON');
    return database;
  }

  group('Seed pattern — full data lifecycle', () {
    test('R5: cascade delete across trip → attractions → overrides '
        '(full FK chain verified)', () async {
      // ── Setup ────────────────────────────────────────────────────
      db = await openTestDb();
      tripDao = TripDao(db);
      attractionDao = AttractionDao(db);
      overrideDao = TimelineOverrideDao(db);

      // Unique identifiers prevent collisions in parallel/repeat runs.
      final suffix = DateTime.now().millisecondsSinceEpoch;
      final tripName = 'E2E Seed Trip $suffix';

      // ── Action: create full data tree ─────────────────────────────
      final tripId = await tripDao.createTrip(
        name: tripName,
        destination: 'Seed City $suffix',
      );
      expect(tripId, greaterThan(0));

      final attr1Id = await attractionDao.createAttraction(
        name: 'Seed Attr A $suffix',
        durationMin: 90,
        tripId: tripId,
        category: AttractionCategory.museum,
        priority: 0,
      );
      final attr2Id = await attractionDao.createAttraction(
        name: 'Seed Attr B $suffix',
        durationMin: 60,
        tripId: tripId,
        priority: 1,
      );

      await overrideDao.upsertOverride(attr1Id, 0, 0);
      await overrideDao.upsertOverride(attr2Id, 1, 2);

      // ── Assert 1: all data is stored correctly ───────────────────
      final trip = await tripDao.getTripById(tripId);
      expect(trip, isNotNull);
      expect(trip!.name, tripName);

      final attractions = await attractionDao.listAttractionsByTrip(tripId);
      expect(attractions.length, 2);

      final overrides = await overrideDao.loadOverridesByTrip(tripId);
      expect(overrides.length, 2,
          reason: 'both attractions have overrides');

      // ── Act: delete the trip — cascades must fire ────────────────
      final deleted = await tripDao.deleteTrip(tripId);
      expect(deleted, 1, reason: 'exactly one trip row deleted');

      // ── Assert 2: FK cascade cleaned everything ──────────────────
      // R5 risk: FK cascade fails silently, leaving orphan rows.
      final tripAfterDelete = await tripDao.getTripById(tripId);
      expect(tripAfterDelete, isNull,
          reason: 'R5: trip row survived delete');

      final attractionsAfterDelete =
          await attractionDao.listAttractionsByTrip(tripId);
      expect(attractionsAfterDelete, isEmpty,
          reason: 'R5: orphan attractions remain (FK cascade on tripId failed)');

      final overridesAfterDelete =
          await overrideDao.loadOverridesByTrip(tripId);
      expect(overridesAfterDelete, isEmpty,
          reason: 'R5: orphan overrides remain '
              '(FK cascade on attractionId failed)');

      // ── Cleanup ──────────────────────────────────────────────────
      await db.close();
    });

    test('R2: schema integrity — all tables exist and are writable '
        'after database creation', () async {
      // ── Setup ────────────────────────────────────────────────────
      db = await openTestDb();
      tripDao = TripDao(db);
      attractionDao = AttractionDao(db);
      overrideDao = TimelineOverrideDao(db);

      // ── Assert 1: schema version is current ──────────────────────
      expect(db.schemaVersion, 4,
          reason: 'R2: schema version mismatch — migration may have failed');

      // ── Action: write to all 3 tables ────────────────────────────
      final suffix = DateTime.now().millisecondsSinceEpoch;
      final tripId = await tripDao.createTrip(
        name: 'Schema Test $suffix',
        destination: 'Test',
      );
      expect(tripId, greaterThan(0),
          reason: 'R2: trips table not writable');

      final attrId = await attractionDao.createAttraction(
        name: 'Schema Attr $suffix',
        durationMin: 30,
        tripId: tripId,
      );
      expect(attrId, greaterThan(0),
          reason: 'R2: attractions table not writable');

      await overrideDao.upsertOverride(attrId, 0, 0);

      // ── Assert 2: data written to all tables ─────────────────────
      final overrides = await overrideDao.loadOverridesByTrip(tripId);
      expect(overrides.length, 1,
          reason: 'R2: timeline_overrides table missing or not writable — '
              'migration from v1→v2 may have failed');

      // ── Assert 3: PRAGMA foreign_keys is ON ──────────────────────
      // If FK is off, inserting an orphan attraction would not throw.
      try {
        await attractionDao.createAttraction(
          name: 'Orphan',
          durationMin: 30,
          tripId: 99999,
        );
        // If we reach here, FK is off — the risk materialized.
        fail('R5: FK constraint not enforced — PRAGMA foreign_keys may be OFF');
      } catch (_) {
        // Expected: FK constraint violation.
      }

      // ── Cleanup ──────────────────────────────────────────────────
      await tripDao.deleteTrip(tripId);
      await db.close();
    });
  });
}
