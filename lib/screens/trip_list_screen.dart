import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/trip_dao.dart';
import 'create_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatefulWidget {
  const TripListScreen({super.key});

  @override
  State<TripListScreen> createState() => _TripListScreenState();
}

class _TripListScreenState extends State<TripListScreen> {
  List<Trip> _trips = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  Future<void> _loadTrips() async {
    final db = await getDatabase();
    final tripDao = TripDao(db);
    final trips = await tripDao.listAllTrips();
    if (!mounted) return;
    setState(() {
      _trips = trips;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Trips')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _trips.isEmpty
              ? const Center(
                  child: Text(
                    'No trips yet.\nTap + to create your first trip.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  itemCount: _trips.length,
                  itemBuilder: (context, index) {
                    final trip = _trips[index];
                    return ListTile(
                      title: Text(trip.name),
                      subtitle: Text(trip.destination),
                      trailing: trip.startDate != null
                          ? Text(
                              '${trip.startDate!.day}.${trip.startDate!.month}.${trip.startDate!.year}',
                            )
                          : null,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(trip: trip),
                          ),
                        );
                      },
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateTripScreen(),
            ),
          ).then((_) => _loadTrips());
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
