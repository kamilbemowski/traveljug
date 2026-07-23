import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../database/daos/attraction_dao.dart';
import '../database/tables.dart';

class TripDetailScreen extends StatefulWidget {
  final Trip trip;

  const TripDetailScreen({super.key, required this.trip});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  List<Attraction> _attractions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAttractions();
  }

  Future<void> _loadAttractions() async {
    final db = await getDatabase();
    final dao = AttractionDao(db);
    final list = await dao.listAttractionsByTrip(widget.trip.id);
    if (!mounted) return;
    setState(() {
      _attractions = list;
      _loading = false;
    });
  }

  String _formatDate(DateTime? d) {
    if (d == null) return '—';
    return '${d.day}.${d.month}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.trip;
    return Scaffold(
      appBar: AppBar(title: Text(t.name)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Attractions',
                    style: Theme.of(context).textTheme.titleMedium),
                ElevatedButton.icon(
                  onPressed: () => _addAttraction(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _attractions.isEmpty
                    ? const Center(
                        child: Text('No attractions yet.',
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _attractions.length,
                        itemBuilder: (context, index) {
                          final a = _attractions[index];
                          return ListTile(
                            leading: const Icon(Icons.place),
                            title: Text(a.name),
                            subtitle: Text(
                                '${a.category} · ${a.durationMin} min · ${_priorityLabel(a.priority)}'),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(int p) {
    return switch (p) {
      0 => 'Must-have',
      1 => 'Nice-to-have',
      2 => 'Optional',
      _ => '?',
    };
  }

  Future<void> _addAttraction(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AddAttractionDialog(tripId: widget.trip.id),
    );
    if (result == true) {
      _loadAttractions();
    }
  }
}

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
  int _priority = 1; // Nice-to-have

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
