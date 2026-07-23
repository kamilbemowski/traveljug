import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:travelapp/database/app_database.dart';
import 'package:travelapp/database/daos/trip_dao.dart';
import 'package:travelapp/screens/trip_list_screen.dart';

void main() {
  late AppDatabase db;
  late TripDao tripDao;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.customStatement('PRAGMA foreign_keys = ON');
    setTestDatabase(db);
    tripDao = TripDao(db);
  });

  tearDown(() async {
    clearTestDatabase();
    await db.close();
  });

  testWidgets('shows empty state when no trips', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TripListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Trips'), findsOneWidget);
    expect(find.textContaining('No trips yet'), findsOneWidget);
  });

  testWidgets('shows FAB to add trip', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: TripListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });

  testWidgets('shows trips in list', (tester) async {
    await tripDao.createTrip(
      name: 'Rome City Break',
      destination: 'Rome, Italy',
    );
    await tripDao.createTrip(
      name: 'Paris Weekend',
      destination: 'Paris, France',
    );

    await tester.pumpWidget(
      const MaterialApp(home: TripListScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Rome City Break'), findsOneWidget);
    expect(find.text('Paris Weekend'), findsOneWidget);
    expect(find.text('Rome, Italy'), findsOneWidget);
    expect(find.text('Paris, France'), findsOneWidget);
  });
}
