import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Trips, Attractions, TimelineOverrides])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(timelineOverrides);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

/// Opens the production database on the device via drift_flutter.
QueryExecutor openAppDatabase() {
  return driftDatabase(name: 'travelapp_db');
}

AppDatabase? _db;

/// Returns the singleton [AppDatabase], initializing it on first call.
Future<AppDatabase> getDatabase() async {
  if (_db != null) return _db!;
  _db = AppDatabase(openAppDatabase());
  return _db!;
}

/// Injects a test database so widget tests don't hit the real SQLite file.
/// Call in test setUp, then call [clearTestDatabase] in tearDown.
void setTestDatabase(AppDatabase db) {
  _db = db;
}

/// Resets the database singleton after a test.
void clearTestDatabase() {
  _db = null;
}
