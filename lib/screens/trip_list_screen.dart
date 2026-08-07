import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/trip_dao.dart';
import '../widgets/edit_trip_dialog.dart';
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

  Future<void> _editTrip(Trip trip) async {
    final result = await showEditTripDialog(context, trip);
    if (result == null) return;

    try {
      final db = await getDatabase();
      await TripDao(db).updateTrip(trip.id,
        name: result.name,
        destination: result.destination,
        startDate: result.startDate,
        endDate: result.endDate,
        pace: result.pace,
        travelContext: result.travelContext,
        isActive: result.isActive,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update trip. Please try again.')),
      );
      return;
    }
    _loadTrips();
  }

  Future<void> _deleteTrip(Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete trip?'),
        content: Text('Delete "${trip.name}" and all its attractions?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final db = await getDatabase();
      await TripDao(db).deleteTrip(trip.id);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to delete trip. Please try again.')),
      );
      return;
    }
    _loadTrips();
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
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 18),
                            onPressed: () => _editTrip(trip),
                            tooltip: 'Edit trip',
                            visualDensity: VisualDensity.compact,
                          ),
                          if (trip.startDate != null)
                            Text(
                              '${trip.startDate!.day}.${trip.startDate!.month}.${trip.startDate!.year}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TripDetailScreen(trip: trip),
                          ),
                        ).then((_) => _loadTrips());
                      },
                      onLongPress: () => _deleteTrip(trip),
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
