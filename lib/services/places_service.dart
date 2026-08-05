import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter_places_sdk/flutter_places_sdk.dart';

/// Wraps the native Google Places SDK via flutter_places_sdk.
///
/// Uses the native Android/iOS Places SDK (not HTTP), so the API key's
/// application restriction (package name + SHA-1 fingerprint) works.
///
/// Pricing (Places API New, per 1k requests):
///   - Autocomplete: $2.83  (billed per call; no session token implemented)
///   - Place Details Essentials: $5.00
///   - Free tier: 10,000 autocomplete + 10,000 details per month
class PlacesService {
  final FlutterPlacesSdk _sdk;

  /// In-memory cache for autocomplete results.  Keyed by lowercased query,
  /// evicts eldest entry when over [_maxCacheSize].
  final LinkedHashMap<String, List<AutocompletePrediction>> _cache =
      LinkedHashMap<String, List<AutocompletePrediction>>();

  static const int _maxCacheSize = 50;

  PlacesService({String? apiKey})
      : _sdk = FlutterPlacesSdk(apiKey ?? kPlacesApiKey);

  bool get isAvailable => _sdk.apiKey.isNotEmpty;

  /// Autocomplete — returns predictions with place names and IDs.
  /// Uses native Places SDK (not HTTP).  Results are cached in memory
  /// for the session — repeat queries return instantly.
  Future<List<AutocompletePrediction>> autocomplete(String query) async {
    if (!isAvailable) return [];

    final key = query.toLowerCase().trim();
    final cached = _cache[key];
    if (cached != null) return cached;

    try {
      final results = await fetchPredictions(query);
      _cache[key] = results;
      if (_cache.length > _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      return results;
    } on PlacesException catch (e) {
      debugPrint('Places SDK autocomplete error ($e): ${e.message}');
      rethrow;
    }
  }

  /// Clears the autocomplete cache.  Used in tests.
  void clearCache() => _cache.clear();

  /// Calls the native SDK for autocomplete predictions.
  /// Overridable so tests can intercept without hitting the real SDK.
  @visibleForTesting
  Future<List<AutocompletePrediction>> fetchPredictions(String query) async {
    return _sdk.findAutocompletePredictions(query);
  }

  /// Place Details — returns coordinates and display name for a place_id.
  /// Called only when the user taps a prediction.
  Future<PlaceDetails?> details(String placeId) async {
    if (!isAvailable) return null;
    try {
      final place = await _sdk.fetchPlace(
        placeId,
        fields: [PlaceField.location, PlaceField.name],
      );
      if (place == null || place.latLng == null) return null;
      return PlaceDetails(
        name: place.name ?? '',
        latitude: place.latLng!.lat,
        longitude: place.latLng!.lng,
      );
    } on PlacesException catch (e) {
      debugPrint('Places SDK details error ($e): ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Places SDK details error: $e');
      return null;
    }
  }
}

/// Decoupled place details.
class PlaceDetails {
  final String name;
  final double latitude;
  final double longitude;

  const PlaceDetails({
    required this.name,
    required this.latitude,
    required this.longitude,
  });
}

// ── API key ──

/// Google Maps API key, injected at build time via:
///   flutter run --dart-define=MAPS_API_KEY=...
const String kPlacesApiKey = String.fromEnvironment('MAPS_API_KEY');

// ── Singleton for production & test injection ──

PlacesService? _placesInstance;

PlacesService getPlacesService() {
  _placesInstance ??= PlacesService();
  return _placesInstance!;
}

void setTestPlacesService(PlacesService service) {
  _placesInstance = service;
}

void clearTestPlacesService() {
  _placesInstance = null;
}
