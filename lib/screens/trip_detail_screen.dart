import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/attraction_dao.dart';
import '../database/daos/trip_dao.dart';
import '../database/tables.dart';
import '../models/timeline_day.dart';
import '../services/timeline_service.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  Trip? _trip;
  List<TimelineDay> _timeline = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTimeline();
  }

  Future<void> _loadTimeline() async {
    final db = await getDatabase();
    final tripDao = TripDao(db);
    final attractionDao = AttractionDao(db);

    final trip = await tripDao.getTripById(widget.trip.id);
    final attractions = await attractionDao.listAttractionsByTrip(widget.trip.id);

    if (!mounted) return;

    if (trip == null) {
      setState(() {
        _error = 'Trip not found';
        _loading = false;
      });
      return;
    }

    if (trip.startDate == null || trip.endDate == null) {
      setState(() {
        _trip = trip;
        _error = 'Add trip dates to see your plan';
        _loading = false;
      });
      return;
    }

    if (attractions.isEmpty) {
      setState(() {
        _trip = trip;
        _error = 'Add attractions to see your plan';
        _loading = false;
      });
      return;
    }

    final timeline = TimelineService.computeTimeline(trip, attractions);

    setState(() {
      _trip = trip;
      _timeline = timeline;
      _error = null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = _trip ?? widget.trip;
    return Scaffold(
      appBar: AppBar(title: Text(t.name)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildPlaceholder()
              : _buildTimeline(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addAttraction(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _error!.contains('dates') ? Icons.calendar_today : Icons.place,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    final t = _trip!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Trip info header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.destination,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${_formatDate(t.startDate)} → ${_formatDate(t.endDate)}',
                  style: const TextStyle(color: Colors.grey)),
              Text('Pace: ${t.pace}',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        // Day-by-day timeline
        Expanded(
          child: ListView.builder(
            itemCount: _timeline.length,
            itemBuilder: (context, index) {
              final day = _timeline[index];
              return _DaySection(day: day, dayNumber: index + 1);
            },
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}.${d.month}.${d.year}';
  }

  Future<void> _addAttraction(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AddAttractionDialog(tripId: widget.trip.id),
    );
    if (result == true) {
      _loadTimeline();
    }
  }
}

/// A single day section in the timeline.
class _DaySection extends StatelessWidget {
  final TimelineDay day;
  final int dayNumber;

  const _DaySection({required this.day, required this.dayNumber});

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${day.date.day}.${day.date.month}.${day.date.year}';
    final hours = day.totalMin ~/ 60;
    final mins = day.totalMin % 60;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: day.overstuffed
                  ? Colors.red.shade50
                  : Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Day $dayNumber — $dateStr',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  '${hours}h ${mins}m',
                  style: TextStyle(
                    color: day.overstuffed ? Colors.red : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Overstuffing warning
          if (day.overstuffed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade100,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This day is overstuffed',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Tight schedule (near-full but not overstuffed)
          if (day.tightSchedule && !day.overstuffed)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              color: Colors.orange.shade50,
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tight schedule',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Attraction slots
          ...day.slots.map((slot) => _SlotTile(slot: slot)),
        ],
      ),
    );
  }
}

/// A single attraction slot within a day.
class _SlotTile extends StatelessWidget {
  final TimelineSlot slot;

  const _SlotTile({required this.slot});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _categoryIcon(slot.attraction.category),
      title: Row(
        children: [
          Expanded(child: Text(slot.attraction.name)),
          if (slot.isMustHave)
            const Icon(Icons.star, size: 18, color: Colors.amber),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${slot.startTime} · ${slot.attraction.category} · ${slot.attraction.durationMin} min',
            style: const TextStyle(fontSize: 13),
          ),
          if (slot.travelFromPrevMin != null)
            Text(
              '← ${slot.travelFromPrevMin} min travel',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
        ],
      ),
      isThreeLine: slot.travelFromPrevMin != null,
    );
  }

  Icon _categoryIcon(String? category) {
    return switch (category) {
      'museum' => const Icon(Icons.account_balance),
      'restaurant' => const Icon(Icons.restaurant),
      'nature' => const Icon(Icons.park),
      'landmark' => const Icon(Icons.place),
      _ => const Icon(Icons.place),
    };
  }
}

// ── _AddAttractionDialog (unchanged from S-01) ──

class _AddAttractionDialog extends StatefulWidget {
  final int tripId;

  const _AddAttractionDialog({required this.tripId});

  @override
  State<_AddAttractionDialog> createState() => _AddAttractionDialogState();
}

class _AddAttractionDialogState extends State<_AddAttractionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController();
  AttractionCategory _category = AttractionCategory.other;
  int _priority = 1;

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final db = await getDatabase();
    final dao = AttractionDao(db);
    final existing = await dao.listAttractionsByTrip(widget.tripId);
    final position = existing.length;

    await dao.createAttraction(
      name: _nameController.text.trim(),
      durationMin: int.parse(_durationController.text.trim()),
      tripId: widget.tripId,
      category: _category,
      priority: _priority,
      position: position,
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Attraction'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
            DropdownButtonFormField<AttractionCategory>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: AttractionCategory.values.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text(c.name[0].toUpperCase() + c.name.substring(1)),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _category = v);
              },
            ),
            TextFormField(
              controller: _durationController,
              decoration:
                  const InputDecoration(labelText: 'Duration (minutes) *'),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Duration is required';
                }
                final n = int.tryParse(v.trim());
                if (n == null || n <= 0) {
                  return 'Must be a positive number';
                }
                return null;
              },
            ),
            DropdownButtonFormField<int>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Must-have')),
                DropdownMenuItem(value: 1, child: Text('Nice-to-have')),
                DropdownMenuItem(value: 2, child: Text('Optional')),
              ],
              onChanged: (v) {
                if (v != null) setState(() => _priority = v);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
