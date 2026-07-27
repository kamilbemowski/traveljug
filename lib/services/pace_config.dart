import '../database/tables.dart';

/// Default travel time between consecutive attractions (in minutes).
/// Flat constant for MVP — will be replaced by per-trip context in S-04.
const int kDefaultTravelMinutes = 30;

/// Concrete hour and budget parameters for each [TravelPace].
class PaceConfig {
  final int wakeHour;
  final int sleepHour;
  final int wakingMinutes;
  final double travelMultiplier;
  final int maxAttractionsPerDay;

  const PaceConfig({
    required this.wakeHour,
    required this.sleepHour,
    required this.travelMultiplier,
    required this.maxAttractionsPerDay,
  }) : wakingMinutes = (sleepHour - wakeHour) * 60;
}

/// Extension mapping each [TravelPace] to its [PaceConfig].
extension TravelPaceConfig on TravelPace {
  PaceConfig get config => switch (this) {
        TravelPace.intensive => const PaceConfig(
              wakeHour: 7,
              sleepHour: 23,
              travelMultiplier: 0.7,
              maxAttractionsPerDay: 6,
            ),
        TravelPace.relaxing => const PaceConfig(
              wakeHour: 10,
              sleepHour: 20,
              travelMultiplier: 1.5,
              maxAttractionsPerDay: 3,
            ),
      };
}

/// Safe-parses a pace string, defaulting to [TravelPace.intensive].
TravelPace parsePace(String? paceName) {
  if (paceName == null) return TravelPace.intensive;
  return TravelPace.values.byName(paceName);
}
