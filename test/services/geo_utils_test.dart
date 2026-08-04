import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/services/geo_utils.dart';

void main() {
  group('haversineKm', () {
    test('Paris to London ≈ 343 km', () {
      final d = haversineKm(48.8566, 2.3522, 51.5074, -0.1278);
      expect(d, closeTo(343.0, 1.0));
    });

    test('same point → 0 km', () {
      final d = haversineKm(52.2297, 21.0122, 52.2297, 21.0122);
      expect(d, closeTo(0.0, 0.1));
    });

    test('Warsaw to Krakow ≈ 252 km', () {
      final d = haversineKm(52.2297, 21.0122, 50.0647, 19.9450);
      expect(d, closeTo(252.0, 1.0));
    });

    test('Equator quarter: (0,0)→(0,90) ≈ 10007 km', () {
      final d = haversineKm(0.0, 0.0, 0.0, 90.0);
      expect(d, closeTo(10007.0, 5.0));
    });

    test('null coordinate returns null', () {
      expect(haversineKm(null, 0.0, 0.0, 0.0), isNull);
      expect(haversineKm(0.0, null, 0.0, 0.0), isNull);
    });

    test('invalid coordinates return null', () {
      expect(haversineKm(95.0, 0.0, 0.0, 0.0), isNull);
      expect(haversineKm(0.0, 200.0, 0.0, 0.0), isNull);
    });
  });

  group('detourFactor', () {
    test('<10 km → 1.6', () {
      expect(detourFactor(5), equals(1.6));
      expect(detourFactor(9.9), equals(1.6));
    });

    test('10-50 km → 1.35', () {
      expect(detourFactor(10), equals(1.35));
      expect(detourFactor(30), equals(1.35));
    });

    test('50-200 km → 1.2', () {
      expect(detourFactor(50), equals(1.2));
      expect(detourFactor(100), equals(1.2));
    });

    test('>200 km → 1.15', () {
      expect(detourFactor(200), equals(1.15));
      expect(detourFactor(500), equals(1.15));
    });
  });

  group('detourAdjustedKm', () {
    test('applies detour to Haversine', () {
      final d = detourAdjustedKm(48.8566, 2.3522, 51.5074, -0.1278);
      // Paris→London ≈ 343 km × 1.15 (>200 bracket) ≈ 394 km
      expect(d, closeTo(343 * 1.15, 2.0));
    });

    test('null coords return null', () {
      expect(detourAdjustedKm(null, 0.0, 0.0, 0.0), isNull);
    });
  });
}
