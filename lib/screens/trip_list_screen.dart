import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/trip_dao.dart';
import '../database/tables.dart';
import '../services/pace_config.dart';
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
    final nameController = TextEditingController(text: trip.name);
    final destController = TextEditingController(text: trip.destination);
    DateTime? startDate = trip.startDate;
    DateTime? endDate = trip.endDate;
    TravelPace pace = parsePace(trip.pace);
    TravelContext? travelContext = parseTravelContext(trip.travelContext);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Trip'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 8),
                TextField(controller: destController, decoration: const InputDecoration(labelText: 'Destination')),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DateField(
                        label: 'Start date', value: startDate,
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (d != null) setDialogState(() => startDate = d);
                        },
                        onClear: () => setDialogState(() => startDate = null),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _DateField(
                        label: 'End date', value: endDate,
                        onTap: () async {
                          final d = await showDatePicker(context: ctx, initialDate: endDate ?? startDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2035));
                          if (d != null) setDialogState(() => endDate = d);
                        },
                        onClear: () => setDialogState(() => endDate = null),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TravelPace>(
                  initialValue: pace,
                  decoration: const InputDecoration(labelText: 'Pace'),
                  items: TravelPace.values.map((p) => DropdownMenuItem(value: p, child: Text(p.name[0].toUpperCase() + p.name.substring(1)))).toList(),
                  onChanged: (v) { if (v != null) setDialogState(() => pace = v); },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TravelContext?>(
                  initialValue: travelContext,
                  decoration: const InputDecoration(labelText: 'Travel context'),
                  items: [null, TravelContext.city, TravelContext.roadTrip].map((c) => DropdownMenuItem(value: c, child: Text(travelContextLabel(c)))).toList(),
                  onChanged: (v) => setDialogState(() => travelContext = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (saved != true) return;

    try {
      final db = await getDatabase();
      await TripDao(db).updateTrip(trip.id,
        name: nameController.text.trim(),
        destination: destController.text.trim(),
        startDate: startDate,
        endDate: endDate,
        pace: pace,
        travelContext: travelContext,
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
                        );
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

/// A small tappable widget showing a date or a placeholder.
/// Mirrors the same widget in create_trip_screen.dart.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value != null
                        ? '${value!.day}.${value!.month}.${value!.year}'
                        : '—',
                    style: TextStyle(
                      color: value != null ? Colors.black87 : Colors.grey,
                    ),
                  ),
                ),
                if (value != null)
                  GestureDetector(
                    onTap: onClear,
                    child: const Icon(Icons.clear, size: 16),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
