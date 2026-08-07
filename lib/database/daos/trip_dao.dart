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
    TravelContext? travelContext,
    String? imageUrl,
    bool isActive = false,
  }) {
    return into(db.trips).insert(TripsCompanion.insert(
          name: name,
          destination: destination,
          startDate: Value(startDate),
          endDate: Value(endDate),
          pace: Value(pace.name),
          travelContext: Value(travelContext?.name),
          imageUrl: Value(imageUrl),
          isActive: Value(isActive),
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
    TravelContext? travelContext,
    String? imageUrl,
    bool? isActive,
  }) async {
    final rows = await (update(db.trips)..where((t) => t.id.equals(id))).write(
          TripsCompanion(
            name: Value.absentIfNull(name),
            destination: Value.absentIfNull(destination),
            startDate: Value.absentIfNull(startDate),
            endDate: Value.absentIfNull(endDate),
            pace: Value.absentIfNull(pace?.name),
            travelContext: Value.absentIfNull(travelContext?.name),
            imageUrl: Value.absentIfNull(imageUrl),
            isActive: Value.absentIfNull(isActive),
            updatedAt: Value(DateTime.now()),
          ),
        );
    return rows > 0;
  }

  /// Returns trips whose date range covers [date]. If [isActive] is provided,
  /// filters to only trips matching that active state.
  /// Results are ordered by updatedAt descending (most recently opened first).
  Future<List<Trip>> listTripsCoveringDate(DateTime date,
      {bool? isActive}) async {
    final query = select(db.trips)
      ..where((t) {
        final dateExpr = t.startDate.isSmallerOrEqualValue(date) &
            t.endDate.isBiggerOrEqualValue(date);
        if (isActive != null) {
          return dateExpr & t.isActive.equals(isActive);
        }
        return dateExpr;
      });
    return (query
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
  }

  /// Deletes a trip by id. Cascades to its attractions per FK constraint.
  Future<int> deleteTrip(int id) {
    return (delete(db.trips)..where((t) => t.id.equals(id))).go();
  }
}
