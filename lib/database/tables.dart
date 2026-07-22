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

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  /// Optional — no FR reference; convenience for future UI.
  TextColumn get imageUrl => text().nullable()();
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

  /// Foreign key to [Trips] — cascade delete when trip is removed.
  IntColumn get tripId => integer().references(
        Trips,
        #id,
        onDelete: KeyAction.cascade,
      )();
}
