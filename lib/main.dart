import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

import 'database/app_database.dart';

const bool kCrashlyticsDisabled = false;

AppDatabase? _db;

/// Returns the singleton [AppDatabase], initializing it on first call.
Future<AppDatabase> getDatabase() async {
  if (_db != null) return _db!;
  _db = AppDatabase(openAppDatabase());
  return _db!;
}

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

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello World!'),
        ),
      ),
    );
  }
}
