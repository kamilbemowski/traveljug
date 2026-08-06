import '../database/app_database.dart';
import '../database/daos/trip_dao.dart';

/// Resolves which trip Android Auto should display.
///
/// Three-level fallback:
/// 1. Active trip whose dates cover today (`isActive = true`)
/// 2. Last-opened trip (highest `updatedAt`)
/// 3. `null` — caller should show trip list for manual selection
class TripSelectionService {
  TripSelectionService._();

  /// Returns the best trip to display in Android Auto, or `null` if no trips
  /// exist and the caller should show a trip list for manual selection.
  static Future<Trip?> resolveForAndroidAuto(TripDao tripDao) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Level 1: active trip whose dates cover today.
    final activeToday = await tripDao.listTripsCoveringDate(
      today,
      isActive: true,
    );
    if (activeToday.isNotEmpty) return activeToday.first;

    // Level 2: last-opened trip (highest updatedAt).
    final allTrips = await tripDao.listAllTrips();
    if (allTrips.isNotEmpty) {
      // Sort by updatedAt DESC — the most recently opened/edited trip first.
      allTrips.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return allTrips.first;
    }

    // Level 3: no trips at all.
    return null;
  }

  /// Returns all trips for manual selection (ordered by updatedAt DESC).
  static Future<List<Trip>> listForSelection(TripDao tripDao) async {
    final trips = await tripDao.listAllTrips();
    trips.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return trips;
  }
}
