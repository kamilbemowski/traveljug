import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:drift/native.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/database/daos/attraction_dao.dart';
import 'package:travelapp/database/daos/trip_dao.dart';
import 'package:travelapp/database/tables.dart';
import 'package:travelapp/screens/trip_detail_screen.dart';

/// Widget tests for S-05 intensity bar and Keep Together toggle.
void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    setTestDatabase(db);
  });

  tearDown(() async {
    clearTestDatabase();
    await db.close();
  });

  Future<Trip> seedTripWithAttractions() async {
    final tripDao = TripDao(db);
    final attrDao = AttractionDao(db);
    final id = await tripDao.createTrip(
      name: 'Test Trip',
      destination: 'Paris',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 2),
    );
    await attrDao.createAttraction(
      name: 'Louvre', durationMin: 120, tripId: id,
      category: AttractionCategory.museum, priority: 0,
    );
    await attrDao.createAttraction(
      name: 'Eiffel Tower', durationMin: 90, tripId: id, priority: 1,
    );
    return (await tripDao.getTripById(id))!;
  }

  testWidgets('S-05: timeline renders with day sections and lock toggle',
      (tester) async {
    final trip = await seedTripWithAttractions();

    await tester.pumpWidget(MaterialApp(
      home: TripDetailScreen(trip: trip),
    ));
    await tester.pumpAndSettle();

    // Day header with lock toggle should be visible.
    expect(find.textContaining('Day 1'), findsOneWidget);

    // Lock open icon visible (toggle starts unlocked).
    expect(find.byIcon(Icons.lock_open), findsWidgets);

    // Overstuffing banner not shown for 2 attractions on 2 days.
    expect(find.text('This day is overstuffed'), findsNothing);
  });

  testWidgets('S-05: overstuffing shown for packed 1-day trip', (tester) async {
    final tripDao = TripDao(db);
    final attrDao = AttractionDao(db);
    final id = await tripDao.createTrip(
      name: 'Packed Trip',
      destination: 'London',
      startDate: DateTime(2026, 8, 1),
      endDate: DateTime(2026, 8, 1),
    );
    for (var i = 0; i < 10; i++) {
      await attrDao.createAttraction(
        name: 'Attr $i', durationMin: 120, tripId: id,
      );
    }
    final trip = (await tripDao.getTripById(id))!;

    await tester.pumpWidget(MaterialApp(
      home: TripDetailScreen(trip: trip),
    ));
    await tester.pumpAndSettle();

    // Overstuffing warning visible for packed day.
    expect(find.text('This day is overstuffed'), findsOneWidget);

    // Lock toggle visible.
    final lockButtons = find.byIcon(Icons.lock_open);
    expect(lockButtons, findsWidgets);
  });
}
