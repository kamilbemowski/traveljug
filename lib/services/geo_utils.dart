import 'dart:math' as math;

/// Mean Earth radius in kilometers (IUGG mean radius).
const double kEarthRadiusKm = 6371.0;

/// Great-circle (Haversine) distance between two coordinates in km.
/// Returns `null` if any coordinate is null or out of valid range:
/// |lat| ≤ 90, |lon| ≤ 180.
double? haversineKm(double? lat1, double? lon1, double? lat2, double? lon2) {
  if (lat1 == null || lon1 == null || lat2 == null || lon2 == null) {
    return null;
  }
  if (lat1.abs() > 90 || lon1.abs() > 180 ||
      lat2.abs() > 90 || lon2.abs() > 180) {
    return null;
  }

  final dLat = _rad(lat2 - lat1);
  final dLon = _rad(lon2 - lon1);
  final rLat1 = _rad(lat1);
  final rLat2 = _rad(lat2);

  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rLat1) * math.cos(rLat2) *
          math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.asin(math.sqrt(a));
  return kEarthRadiusKm * c;
}

/// Distance-bracket detour factor based on empirical European data (S-06 research).
/// Converts straight-line km to approximate real-road km.
double detourFactor(double km) {
  if (km < 10) return 1.6;
  if (km < 50) return 1.35;
  if (km < 200) return 1.2;
  return 1.15;
}

/// Straight-line distance with detour factor applied.
/// Returns `null` when coordinates are missing or invalid.
double? detourAdjustedKm(
    double? lat1, double? lon1, double? lat2, double? lon2) {
  final straight = haversineKm(lat1, lon1, lat2, lon2);
  if (straight == null) return null;
  return straight * detourFactor(straight);
}

double _rad(double deg) => deg * math.pi / 180;
