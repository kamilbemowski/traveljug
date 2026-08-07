import 'package:flutter/material.dart';
import '../database/app_database.dart';
import '../database/tables.dart';
import '../services/pace_config.dart';

class EditTripResult {
  final String name;
  final String destination;
  final DateTime? startDate;
  final DateTime? endDate;
  final TravelPace pace;
  final TravelContext? travelContext;
  final bool isActive;
  const EditTripResult({
    required this.name,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.pace,
    this.travelContext,
    this.isActive = false,
  });
}

/// Shows a shared Edit Trip dialog. Returns the updated fields on save, or
/// null on cancel. The caller handles the DAO update and reload.
Future<EditTripResult?> showEditTripDialog(
  BuildContext context,
  Trip trip,
) {
  return showDialog<EditTripResult>(
    context: context,
    builder: (_) => _EditTripDialog(trip: trip),
  );
}

class _EditTripDialog extends StatefulWidget {
  final Trip trip;
  const _EditTripDialog({required this.trip});

  @override
  State<_EditTripDialog> createState() => _EditTripDialogState();
}

class _EditTripDialogState extends State<_EditTripDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _destController;
  late DateTime? _startDate;
  late DateTime? _endDate;
  late TravelPace _pace;
  late TravelContext? _travelContext;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.trip.name);
    _destController = TextEditingController(text: widget.trip.destination);
    _startDate = widget.trip.startDate;
    _endDate = widget.trip.endDate;
    _pace = parsePace(widget.trip.pace);
    _travelContext = parseTravelContext(widget.trip.travelContext) ?? TravelContext.city;
    _isActive = widget.trip.isActive;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _destController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final d = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (d != null) {
      setState(() {
        if (isStart) {
          _startDate = d;
          if (_endDate != null && _endDate!.isBefore(d)) _endDate = d;
        } else {
          _endDate = d;
        }
      });
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      EditTripResult(
        name: _nameController.text.trim(),
        destination: _destController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        pace: _pace,
        travelContext: _travelContext,
        isActive: _isActive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Trip'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _destController,
                decoration: const InputDecoration(labelText: 'Destination'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Destination is required' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start date',
                      value: _startDate,
                      onTap: () => _pickDate(true),
                      onClear: _startDate != null
                          ? () => setState(() => _startDate = null)
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateField(
                      label: 'End date',
                      value: _endDate,
                      onTap: () => _pickDate(false),
                      onClear: _endDate != null
                          ? () => setState(() => _endDate = null)
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TravelPace>(
                initialValue: _pace,
                decoration: const InputDecoration(labelText: 'Pace'),
                items: TravelPace.values
                    .map((p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.name[0].toUpperCase() + p.name.substring(1)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _pace = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<TravelContext?>(
                initialValue: _travelContext,
                decoration: const InputDecoration(labelText: 'Travel context'),
                items: [TravelContext.city, TravelContext.roadTrip]
                    .map((c) => DropdownMenuItem(
                          value: c,
                          child: Text(travelContextLabel(c)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _travelContext = v),
              ),
              SwitchListTile(
                title: const Text('Active trip',
                    style: TextStyle(fontSize: 14)),
                subtitle: const Text(
                    'Shown in Android Auto by default',
                    style: TextStyle(fontSize: 12)),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

/// A small tappable widget showing a date or a placeholder with optional clear.
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    this.onClear,
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
                if (value != null && onClear != null)
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
