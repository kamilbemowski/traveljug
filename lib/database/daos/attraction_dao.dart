import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'attraction_dao.g.dart';

@DriftAccessor(tables: [Attractions])
class AttractionDao extends DatabaseAccessor<AppDatabase>
    with _$AttractionDaoMixin {
  AttractionDao(super.db);

  /// Creates a new attraction and returns its row id.
  Future<int> createAttraction({
    required String name,
    required int durationMin,
    required int tripId,
    AttractionCategory category = AttractionCategory.other,
    int priority = 1,
    int position = 0,
  }) {
    return into(db.attractions).insert(AttractionsCompanion.insert(
          name: name,
          category: category.name,
          durationMin: durationMin,
          priority: priority,
          position: position,
          tripId: tripId,
        ));
  }

  /// Returns a single attraction by id, or null if not found.
  Future<Attraction?> getAttractionById(int id) {
    return (select(db.attractions)..where((a) => a.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns all attractions for a given trip, ordered by position.
  Future<List<Attraction>> listAttractionsByTrip(int tripId) {
    return (select(db.attractions)
          ..where((a) => a.tripId.equals(tripId))
          ..orderBy([(a) => OrderingTerm.asc(a.position)]))
        .get();
  }

  /// Partially updates an attraction. Only non-null fields are changed.
  Future<void> updateAttraction(
    int id, {
    String? name,
    AttractionCategory? category,
    int? durationMin,
    int? priority,
    int? position,
    int? tripId,
  }) async {
    await (update(db.attractions)..where((a) => a.id.equals(id))).write(
          AttractionsCompanion(
            name: Value.absentIfNull(name),
            category: Value.absentIfNull(category?.name),
            durationMin: Value.absentIfNull(durationMin),
            priority: Value.absentIfNull(priority),
            position: Value.absentIfNull(position),
            tripId: Value.absentIfNull(tripId),
          ),
        );
  }

  /// Deletes a single attraction by id.
  Future<int> deleteAttraction(int id) {
    return (delete(db.attractions)..where((a) => a.id.equals(id))).go();
  }
}
