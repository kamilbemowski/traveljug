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
    return null;
  }
}

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
