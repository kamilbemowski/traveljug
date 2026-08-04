import 'package:flutter/foundation.dart';

import '../database/tables.dart';

/// Default travel time between consecutive attractions (in minutes).
/// Used as fallback when no [TravelContext] is set on the trip.
const int kDefaultTravelMinutes = 30;

/// Safe-parses a travel context string, returning null on unknown values.
TravelContext? parseTravelContext(String? contextName) {
  if (contextName == null) return null;
  try {
    return TravelContext.values.byName(contextName);
  } on ArgumentError {
    debugPrint('WARNING: Unknown travel context value "$contextName" in database, '
        'defaulting to null (30 min default). This may indicate data from a '
        'newer app version or a schema corruption.');
    return null;
  }
}

/// Human-readable label for a travel context, including its base minutes.
String travelContextLabel(TravelContext? context) {
  final name = switch (context) {
    TravelContext.city => 'City tour',
    TravelContext.roadTrip => 'Road trip',
    null => 'Default',
  };
  return '$name (${travelMinutesForContext(context)} min)';
}

// ── S-06: Speed constants for distance-to-time conversion ──

/// Walking speed in km/h used for city tour context.
const double kCitySpeedKmh = 5.0;

/// Driving speed in km/h used for road trip context.
/// Raised to 75 km/h because the detour factor now explicitly handles road circuity.
const double kRoadTripSpeedKmh = 75.0;

/// Default speed in km/h when travel context is null (conservative: walking pace).
const double kDefaultSpeedKmh = 5.0;

/// Minimum travel minutes between two stops with coordinates (pre-multiplier).
/// Prevents 0 min for same-point or very close attractions.
const int kMinPairTravelMin = 5;

/// Returns the km/h speed used to convert distance → travel time.
/// Mirrors [travelMinutesForContext]'s null-fallback pattern.
double speedKmhForContext(TravelContext? context) => switch (context) {
      TravelContext.city => kCitySpeedKmh,
      TravelContext.roadTrip => kRoadTripSpeedKmh,
      null => kDefaultSpeedKmh,
    };

/// Returns the base travel minutes for a given [TravelContext].
/// Falls back to [kDefaultTravelMinutes] when context is null.
int travelMinutesForContext(TravelContext? context) => switch (context) {
      TravelContext.city => 20,
      TravelContext.roadTrip => 90,
      null => kDefaultTravelMinutes,
    };

/// Concrete hour and budget parameters for each [TravelPace].
class PaceConfig {
  final int wakeHour;
  final int sleepHour;
  final int wakingMinutes;
  final double travelMultiplier;

  const PaceConfig({
    required this.wakeHour,
    required this.sleepHour,
    required this.travelMultiplier,
  }) : wakingMinutes = (sleepHour - wakeHour) * 60;
}

/// Extension mapping each [TravelPace] to its [PaceConfig].
extension TravelPaceConfig on TravelPace {
  PaceConfig get config => switch (this) {
        TravelPace.intensive => const PaceConfig(
              wakeHour: 7,
              sleepHour: 23,
              travelMultiplier: 0.7,
            ),
        TravelPace.relaxing => const PaceConfig(
              wakeHour: 10,
              sleepHour: 20,
              travelMultiplier: 1.5,
            ),
      };
}

/// Safe-parses a pace string, defaulting to [TravelPace.intensive].
TravelPace parsePace(String? paceName) {
  if (paceName == null) return TravelPace.intensive;
  try {
    return TravelPace.values.byName(paceName);
  } on ArgumentError {
    // Log to console — Crashlytics picks this up via captureConsoleIntegration-like
    // behavior if a logging observer is wired. In debug mode, this prints visibly.
    debugPrint('WARNING: Unknown pace value "$paceName" in database, '
        'defaulting to intensive. This may indicate data from a newer app '
        'version or a schema corruption.');
    return TravelPace.intensive;
  }
}
