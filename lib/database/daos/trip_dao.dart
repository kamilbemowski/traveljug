import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables.dart';

part 'trip_dao.g.dart';

@DriftAccessor(tables: [Trips])
class TripDao extends DatabaseAccessor<AppDatabase> with _$TripDaoMixin {
  TripDao(super.db);

  /// Creates a new trip and returns its row id.
  Future<int> createTrip({
    required String name,
    required String destination,
    DateTime? startDate,
    DateTime? endDate,
    TravelPace pace = TravelPace.intensive,
    String? imageUrl,
  }) {
    return into(db.trips).insert(TripsCompanion.insert(
          name: name,
          destination: destination,
          startDate: Value(startDate),
          endDate: Value(endDate),
          pace: pace.name,
          imageUrl: Value(imageUrl),
        ));
  }

  /// Returns a single trip by id, or null if not found.
  Future<Trip?> getTripById(int id) {
    return (select(db.trips)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Returns all trips, newest first.
  Future<List<Trip>> listAllTrips() {
    return (select(db.trips)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .get();
  }

  /// Partially updates a trip. Only non-null fields are changed.
  /// [updatedAt] is always bumped to now.
  Future<bool> updateTrip(
    int id, {
    String? name,
    String? destination,
    DateTime? startDate,
    DateTime? endDate,
    TravelPace? pace,
    String? imageUrl,
  }) async {
    final rows = await (update(db.trips)..where((t) => t.id.equals(id))).write(
          TripsCompanion(
            name: Value.absentIfNull(name),
            destination: Value.absentIfNull(destination),
            startDate: Value.absentIfNull(startDate),
            endDate: Value.absentIfNull(endDate),
            pace: Value.absentIfNull(pace?.name),
            imageUrl: Value.absentIfNull(imageUrl),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return rows > 0;
  }

  /// Deletes a trip by id. Cascades to its attractions per FK constraint.
  Future<int> deleteTrip(int id) {
    return (delete(db.trips)..where((t) => t.id.equals(id))).go();
  }
}
