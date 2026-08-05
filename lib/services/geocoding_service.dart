import 'package:flutter/foundation.dart';
import 'package:flutter_places_sdk/flutter_places_sdk.dart';

/// Wraps the native Google Places SDK via flutter_places_sdk.
///
/// Uses the native Android/iOS Places SDK (not HTTP), so the API key's
/// application restriction (package name + SHA-1 fingerprint) works.
///
/// Pricing (Places API New, per 1k):
///   - Autocomplete: $2.83 (free within a session ending in fetchPlace)
///   - Place Details Essentials: $5.00
///   - Free tier: 10,000 autocomplete + 10,000 details per month
class PlacesService {
  final FlutterPlacesSdk _sdk;

  PlacesService({String? apiKey})
      : _sdk = FlutterPlacesSdk(apiKey ?? kPlacesApiKey);

  bool get isAvailable => _sdk.apiKey.isNotEmpty;

  /// Autocomplete — returns predictions with place names and IDs.
  /// Uses native Places SDK (not HTTP).
  Future<List<AutocompletePrediction>> autocomplete(String query) async {
    if (!isAvailable) return [];
    try {
      return await _sdk.findAutocompletePredictions(query);
    } on PlacesException catch (e) {
      debugPrint('Places SDK autocomplete error ($e): ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Places SDK autocomplete error: $e');
      return [];
    }
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
      if (place == null) return null;
      return PlaceDetails(
        name: place.name ?? '',
        latitude: place.latLng?.lat ?? 0,
        longitude: place.latLng?.lng ?? 0,
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
