import 'package:drift/drift.dart';

/// Category of an attraction. Stored as text in SQLite.
enum AttractionCategory {
  museum,
  restaurant,
  nature,
  landmark,
  other,
}

/// Travel pace preference set at trip creation.
/// Affects default sleep and wake windows in timeline generation (S-02).
enum TravelPace {
  intensive,
  relaxing,
}

/// Travel context — sets the base travel time between attractions (S-04).
/// Stored as text in SQLite. Null means "use default" (30 min).
enum TravelContext {
  city,
  roadTrip,
}

/// Trips table — one row per planned trip.
class Trips extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get destination => text().withLength(min: 1, max: 200)();

  /// Optional per FR-001 — aspirational/someday trips may omit dates.
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();

  /// Stored as [TravelPace.name], default `intensive`.
  TextColumn get pace =>
      text().withDefault(const Constant('intensive'))();

  /// Stored as [TravelContext.name]. Null = use default (30 min).
  TextColumn get travelContext => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Optional — no FR reference; convenience for future UI.
  TextColumn get imageUrl => text().nullable()();

  /// Whether this trip is marked as the "active" trip for Android Auto display.
  /// Default false. Only one trip should be active at a time (enforced by UI).
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
}

/// Attractions table — one row per attraction within a trip.
class Attractions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 200)();

  /// Stored as [AttractionCategory.name], default `other`.
  TextColumn get category =>
      text().withDefault(const Constant('other'))();

  /// Visit duration in minutes, required per FR-003.
  IntColumn get durationMin => integer()();

  /// Three-tier priority: 0 = must-have, 1 = nice-to-have, 2 = optional.
  /// Default = 1 (nice-to-have). Labels TBD per PRD Open Question #2.
  IntColumn get priority =>
      integer().withDefault(const Constant(1))();

  /// Ordering within a trip per FR-004.
  IntColumn get position =>
      integer().withDefault(const Constant(0))();

  /// GPS latitude, nullable per S-06. REAL (IEEE 754 double) in SQLite.
  RealColumn get latitude => real().nullable()();

  /// GPS longitude, nullable per S-06. REAL (IEEE 754 double) in SQLite.
  RealColumn get longitude => real().nullable()();

  /// Place name from Google Places SDK — stored alongside coordinates
  /// so the user can see what place they picked, even if they rename
  /// the attraction. Nullable (only set when coordinates come from Places SDK).
  TextColumn get placeName => text().nullable()();

  /// Foreign key to [Trips] — cascade delete when trip is removed.
  IntColumn get tripId => integer().references(
        Trips,
        #id,
        onDelete: KeyAction.cascade,
      )();
}

/// Stores user manual edits to the timeline. One row per overridden attraction.
class TimelineOverrides extends Table {
  IntColumn get attractionId => integer().unique().references(
        Attractions,
        #id,
        onDelete: KeyAction.cascade,
      )();

  /// The day index (0-based) where the user wants this attraction.
  IntColumn get userDay => integer()();

  /// The position within that day.
  IntColumn get userPosition => integer()();
}
