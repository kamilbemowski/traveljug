import 'dart:io' show Platform;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_carplay/flutter_carplay.dart';

import 'database/app_database.dart';
import 'database/daos/attraction_dao.dart';
import 'database/daos/trip_dao.dart';
import 'screens/trip_list_screen.dart';
import 'services/android_auto_service.dart';
import 'services/timeline_service.dart';
import 'services/trip_selection_service.dart';

const bool kCrashlyticsDisabled = false;

/// Initialized once in main() — listens for Android Auto connection events
/// and pushes the correct template when the car connects.
FlutterAndroidAuto? _androidAuto; // ignore: unused_element

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  if (!kCrashlyticsDisabled) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Warm up the database so DAOs are ready when the first screen loads.
  await getDatabase();

  // Initialize Android Auto (no-op on iOS/desktop).
  if (Platform.isAndroid) {
    _androidAuto = FlutterAndroidAuto()
      ..addListenerOnConnectionChange((status) {
        if (status == ConnectionStatusTypes.connected) {
          _onAndroidAutoConnected();
        }
      });
  }

  runApp(const MainApp());
}

/// Called when the phone connects to an Android Auto head unit.
/// Loads the appropriate trip, computes the timeline, and pushes the
/// correct template (today plan, message, or trip list).
Future<void> _onAndroidAutoConnected() async {
  try {
    final db = await getDatabase();
    final tripDao = TripDao(db);

    final trip = await TripSelectionService.resolveForAndroidAuto(tripDao);

    if (trip == null) {
      await AndroidAutoService.showNoTripsMessage();
      return;
    }

    // Guard: trip without dates cannot have a timeline.
    if (trip.startDate == null || trip.endDate == null) {
      await AndroidAutoService.showNoDatesMessage(trip.name);
      return;
    }

    final attractionDao = AttractionDao(db);
    final attractions =
        await attractionDao.listAttractionsByTrip(trip.id);

    if (attractions.isEmpty) {
      await AndroidAutoService.showNoAttractionsMessage(trip.name);
      return;
    }

    final computed =
        TimelineService.computeTimeline(trip, attractions);
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final todayPlan = computed.where((day) {
      final d = day.date;
      return DateTime(d.year, d.month, d.day) == todayDay;
    }).firstOrNull;

    if (todayPlan == null || todayPlan.slots.isEmpty) {
      await AndroidAutoService.showNoAttractionsMessage(trip.name);
      return;
    }

    await AndroidAutoService.showTodayPlan(todayPlan);
  } catch (e) {
    debugPrint('AndroidAuto: failed to load plan: $e');
    await AndroidAutoService.showNoAttractionsMessage('TravelJug');
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: TripListScreen(),
    );
  }
}
