import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'timeline_override_dao.g.dart';

@DriftAccessor(tables: [TimelineOverrides])
class TimelineOverrideDao extends DatabaseAccessor<AppDatabase>
    with _$TimelineOverrideDaoMixin {
  TimelineOverrideDao(super.db);

  /// Upserts an override for a given attraction.
  Future<void> upsertOverride(
    int attractionId,
    int userDay,
    int userPosition,
  ) async {
    // Delete existing override first, then insert.
    await deleteOverride(attractionId);
    await into(db.timelineOverrides).insert(
          TimelineOverridesCompanion.insert(
            attractionId: attractionId,
            userDay: userDay,
            userPosition: userPosition,
          ),
        );
  }

  /// Removes the override for a given attraction.
  Future<int> deleteOverride(int attractionId) {
    return (delete(db.timelineOverrides)
          ..where((o) => o.attractionId.equals(attractionId)))
        .go();
  }

  /// Loads all overrides for attractions in a given trip, keyed by attractionId.
  Future<Map<int, TimelineOverride>> loadOverridesByTrip(int tripId) async {
    final query = select(db.timelineOverrides).join([
      innerJoin(db.attractions,
          db.attractions.id.equalsExp(db.timelineOverrides.attractionId)),
    ])
      ..where(db.attractions.tripId.equals(tripId));

    final rows = await query.get();
    final result = <int, TimelineOverride>{};
    for (final row in rows) {
      final override = row.readTable(db.timelineOverrides);
      result[override.attractionId] = override;
    }
    return result;
  }

  /// Cleanup when a trip is deleted (FK cascade handles individual attractions).
  Future<void> deleteAllOverridesForTrip(int tripId) async {
    final ids = await (selectOnly(db.attractions)
          ..addColumns([db.attractions.id])
          ..where(db.attractions.tripId.equals(tripId)))
        .map((row) => row.read(db.attractions.id)!)
        .get();

    for (final id in ids) {
      await deleteOverride(id);
    }
  }
}
