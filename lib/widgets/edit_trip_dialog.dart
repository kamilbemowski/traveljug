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
  const EditTripResult({
    required this.name,
    required this.destination,
    this.startDate,
    this.endDate,
    required this.pace,
    this.travelContext,
  });
}

/// Shows a shared Edit Trip dialog. Returns the updated fields on save, or
/// null on cancel. The caller handles the DAO update and reload.
Future<EditTripResult?> showEditTripDialog(
  BuildContext context,
  Trip trip,
) async {
  final nameController = TextEditingController(text: trip.name);
  final destController = TextEditingController(text: trip.destination);
  DateTime? startDate = trip.startDate;
  DateTime? endDate = trip.endDate;
  TravelPace pace = parsePace(trip.pace);
  TravelContext? travelContext =
      parseTravelContext(trip.travelContext) ?? TravelContext.city;

  final formKey = GlobalKey<FormState>();

  final saved = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) => AlertDialog(
        title: const Text('Edit Trip'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: destController,
                  decoration: const InputDecoration(labelText: 'Destination'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Destination is required' : null,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateField(
                        ctx,
                        setDialogState,
                        'Start',
                        startDate,
                        (d) {
                          startDate = d;
                          if (endDate != null &&
                              d != null &&
                              endDate!.isBefore(d)) {
                            endDate = d;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildDateField(
                        ctx,
                        setDialogState,
                        'End',
                        endDate,
                        (d) => endDate = d,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TravelPace>(
                  initialValue: pace,
                  decoration: const InputDecoration(labelText: 'Pace'),
                  items: TravelPace.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text(
                                p.name[0].toUpperCase() + p.name.substring(1)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => pace = v);
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<TravelContext?>(
                  initialValue: travelContext,
                  decoration: const InputDecoration(labelText: 'Travel context'),
                  items: [TravelContext.city, TravelContext.roadTrip]
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(travelContextLabel(c)),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => travelContext = v),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );

  if (saved != true) {
    nameController.dispose();
    destController.dispose();
    return null;
  }

  final result = EditTripResult(
    name: nameController.text.trim(),
    destination: destController.text.trim(),
    startDate: startDate,
    endDate: endDate,
    pace: pace,
    travelContext: travelContext,
  );
  nameController.dispose();
  destController.dispose();
  return result;
}

Widget _buildDateField(
  BuildContext dialogCtx,
  void Function(void Function()) setDialogState,
  String label,
  DateTime? current,
  void Function(DateTime?) onChanged,
) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('$label date',
          style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
            context: dialogCtx,
            initialDate: current ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2035),
          );
          if (d != null) setDialogState(() => onChanged(d));
        },
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
                  current != null
                      ? '${current.day}.${current.month}.${current.year}'
                      : '—',
                  style: TextStyle(
                    color: current != null ? Colors.black87 : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
