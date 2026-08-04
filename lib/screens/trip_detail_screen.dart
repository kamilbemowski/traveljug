import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/attraction_dao.dart';
import '../database/daos/timeline_override_dao.dart';
import '../database/daos/trip_dao.dart';
import '../database/tables.dart';
import '../models/timeline_day.dart';
import '../services/pace_config.dart';
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade700),
    );
  }

  Future<void> _loadTimeline() async {
    final db = await getDatabase();
    final tripDao = TripDao(db);
    final attractionDao = AttractionDao(db);

    final trip = await tripDao.getTripById(widget.trip.id);
    final attractions = await attractionDao.listAttractionsByTrip(widget.trip.id);

    if (!mounted) return;

    if (trip == null) {
      setState(() { _error = 'Trip not found'; _loading = false; });
      return;
    }

    if (trip.startDate == null || trip.endDate == null) {
      setState(() { _trip = trip; _error = 'Add trip dates to see your plan'; _loading = false; });
      return;
    }

    if (attractions.isEmpty) {
      setState(() { _trip = trip; _error = 'Add attractions to see your plan'; _loading = false; });
      return;
    }

    final computed = TimelineService.computeTimeline(trip, attractions);
    final overrideDao = TimelineOverrideDao(db);
    final overrides = await overrideDao.loadOverridesByTrip(widget.trip.id);
    final baseTravel = travelMinutesForContext(parseTravelContext(trip.travelContext));
    final timeline = TimelineService.reapplyOverrides(
      computed, overrides,
      pace: trip.pace,
      baseTravel: baseTravel,
    );

    setState(() { _trip = trip; _timeline = timeline; _error = null; _loading = false; });
  }

  Future<void> _handleReorder(int dayIndex, int oldIndex, int newIndex) async {
    final day = _timeline[dayIndex];
    final slots = List<TimelineSlot>.from(day.slots);
    final item = slots.removeAt(oldIndex);
    slots.insert(newIndex, item);

    try {
      final db = await getDatabase();
      final dao = TimelineOverrideDao(db);
      for (var i = 0; i < slots.length; i++) {
        await dao.upsertOverride(slots[i].attraction.id, dayIndex, i);
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to reorder attractions. Please try again.');
      return;
    }
    if (!mounted) return;
    _loadTimeline();
  }

  Future<void> _handleMoveDay(int dayIndex, int slotIndex, int direction) async {
    try {
      final db = await getDatabase();
      final dao = TimelineOverrideDao(db);
      final slot = _timeline[dayIndex].slots[slotIndex];
      final targetDay = dayIndex + direction;
      await dao.upsertOverride(slot.attraction.id, targetDay, 0);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to move attraction. Please try again.');
      return;
    }
    if (!mounted) return;
    _loadTimeline();
  }

  Future<void> _handleDelete(int slotIndex, int dayIndex) async {
    final slot = _timeline[dayIndex].slots[slotIndex];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from plan?'),
        content: Text('Remove "${slot.attraction.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final db = await getDatabase();
      final attractionDao = AttractionDao(db);
      await attractionDao.deleteAttraction(slot.attraction.id);
      final overrideDao = TimelineOverrideDao(db);
      await overrideDao.deleteOverride(slot.attraction.id);
    } catch (e) {
      if (!mounted) return;
      _showError('Failed to remove attraction. Please try again.');
      return;
    }
    if (!mounted) return;
    _loadTimeline();
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
            Icon(_error!.contains('dates') ? Icons.calendar_today : Icons.place, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey)),
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
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.destination, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text('${_formatDate(t.startDate)} → ${_formatDate(t.endDate)}', style: const TextStyle(color: Colors.grey)),
              Text('Pace: ${t.pace}', style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _timeline.length,
            itemBuilder: (context, index) {
              return _DaySection(
                key: ValueKey(_timeline[index].date),
                day: _timeline[index],
                dayIndex: index,
                dayNumber: index + 1,
                totalDays: _timeline.length,
                onReorder: (oldIdx, newIdx) => _handleReorder(index, oldIdx, newIdx),
                onMoveDay: (slotIdx, dir) => _handleMoveDay(index, slotIdx, dir),
                onDelete: (slotIdx) => _handleDelete(slotIdx, index),
              );
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
    if (result == true) _loadTimeline();
  }
}

/// A single day section in the timeline — interactive with intensity bar
/// and Keep Together toggle (S-05).
class _DaySection extends StatefulWidget {
  final TimelineDay day;
  final int dayIndex;
  final int dayNumber;
  final int totalDays;
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int slotIndex, int direction) onMoveDay;
  final void Function(int slotIndex) onDelete;

  const _DaySection({
    super.key,
    required this.day,
    required this.dayIndex,
    required this.dayNumber,
    required this.totalDays,
    required this.onReorder,
    required this.onMoveDay,
    required this.onDelete,
  });

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
  bool _keepTogether = false;

  @override
  Widget build(BuildContext context) {
    final day = widget.day;
    final dateStr = '${day.date.day}.${day.date.month}.${day.date.year}';
    final hours = day.totalMin ~/ 60;
    final mins = day.totalMin % 60;

    final intensityColor = switch (day.intensity) {
      DayIntensity.low => Colors.green,
      DayIntensity.medium => Colors.amber,
      DayIntensity.high => Colors.orange,
    };

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Intensity bar (S-05)
          Container(height: 4, color: intensityColor),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: day.overstuffed ? Colors.red.shade50 : Colors.blue.shade50,
              borderRadius: day.overstuffed
                  ? BorderRadius.zero
                  : const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text('Day ${widget.dayNumber} — $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                IconButton(
                  icon: Icon(_keepTogether ? Icons.lock : Icons.lock_open, size: 20),
                  tooltip: _keepTogether ? 'Warning hidden' : 'Show warning',
                  onPressed: () => setState(() => _keepTogether = !_keepTogether),
                  visualDensity: VisualDensity.compact,
                ),
                Text('${hours}h ${mins}m', style: TextStyle(color: day.overstuffed ? Colors.red : Colors.grey.shade700, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          if (day.overstuffed && !_keepTogether)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade100,
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(child: Text('This day is overstuffed', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          if (day.overstuffed && _keepTogether)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.blue.shade50,
              child: const Row(
                children: [
                  Icon(Icons.lock, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(child: Text('Overstuffing warning hidden', style: TextStyle(color: Colors.blue, fontSize: 13))),
                ],
              ),
            ),
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: day.slots.length,
            onReorderItem: widget.onReorder,
            proxyDecorator: (child, index, animation) => Material(elevation: 4, child: child),
            itemBuilder: (context, index) {
              final slot = day.slots[index];
              return _SlotTile(
                key: ValueKey(slot.attraction.id),
                slot: slot,
                dayIndex: widget.dayIndex,
                slotIndex: index,
                totalDays: widget.totalDays,
                onMoveDay: widget.onMoveDay,
                onDelete: widget.onDelete,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Interactive attraction slot with move-day and delete buttons.
class _SlotTile extends StatelessWidget {
  final TimelineSlot slot;
  final int dayIndex;
  final int slotIndex;
  final int totalDays;
  final void Function(int slotIndex, int direction) onMoveDay;
  final void Function(int slotIndex) onDelete;

  const _SlotTile({
    super.key,
    required this.slot,
    required this.dayIndex,
    required this.slotIndex,
    required this.totalDays,
    required this.onMoveDay,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _categoryIcon(slot.attraction.category),
      title: Row(
        children: [
          Expanded(child: Text(slot.attraction.name)),
          if (slot.isMustHave) const Icon(Icons.star, size: 18, color: Colors.amber),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${slot.startTime} · ${slot.attraction.category} · ${slot.attraction.durationMin} min', style: const TextStyle(fontSize: 13)),
          if (slot.travelFromPrevMin != null) Text('← ${slot.travelFromPrevMin} min travel', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
      isThreeLine: slot.travelFromPrevMin != null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dayIndex > 0)
            IconButton(icon: const Icon(Icons.arrow_back, size: 18), onPressed: () => onMoveDay(slotIndex, -1), tooltip: 'Move to previous day', visualDensity: VisualDensity.compact),
          if (dayIndex < totalDays - 1)
            IconButton(icon: const Icon(Icons.arrow_forward, size: 18), onPressed: () => onMoveDay(slotIndex, 1), tooltip: 'Move to next day', visualDensity: VisualDensity.compact),
          IconButton(icon: const Icon(Icons.close, size: 18, color: Colors.red), onPressed: () => onDelete(slotIndex), tooltip: 'Remove from plan', visualDensity: VisualDensity.compact),
        ],
      ),
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

// ── _AddAttractionDialog ──

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
    try {
      final db = await getDatabase();
      final dao = AttractionDao(db);
      final existing = await dao.listAttractionsByTrip(widget.tripId);
      await dao.createAttraction(
        name: _nameController.text.trim(),
        durationMin: int.parse(_durationController.text.trim()),
        tripId: widget.tripId, category: _category, priority: _priority,
        position: existing.length,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save attraction. Please try again.')),
      );
      return;
    }
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
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name *'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null),
            DropdownButtonFormField<AttractionCategory>(initialValue: _category, decoration: const InputDecoration(labelText: 'Category'), items: AttractionCategory.values.map((c) => DropdownMenuItem(value: c, child: Text(c.name[0].toUpperCase() + c.name.substring(1)))).toList(), onChanged: (v) { if (v != null) setState(() => _category = v); }),
            TextFormField(controller: _durationController, decoration: const InputDecoration(labelText: 'Duration (minutes) *'), keyboardType: TextInputType.number, validator: (v) { if (v == null || v.trim().isEmpty) return 'Duration is required'; final n = int.tryParse(v.trim()); if (n == null || n <= 0) return 'Must be a positive number'; return null; }),
            DropdownButtonFormField<int>(initialValue: _priority, decoration: const InputDecoration(labelText: 'Priority'), items: const [DropdownMenuItem(value: 0, child: Text('Must-have')), DropdownMenuItem(value: 1, child: Text('Nice-to-have')), DropdownMenuItem(value: 2, child: Text('Optional'))], onChanged: (v) { if (v != null) setState(() => _priority = v); }),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
