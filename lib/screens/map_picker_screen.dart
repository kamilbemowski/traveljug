import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen map picker for selecting an attraction's GPS coordinates.
/// User taps the map → a pin appears → "Confirm" returns the position.
/// Falls back to manual text entry if the map doesn't load within 5 seconds.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  /// Opens the map picker as a full-screen route and returns the selected
  /// [LatLng], or null if the user cancelled.
  static Future<LatLng?> show(BuildContext context) {
    return Navigator.push<LatLng>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
  }

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  LatLng? _position;
  bool _mapLoaded = false;
  bool _timedOut = false;
  Timer? _timeoutTimer;

  // Manual fallback controllers.
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!_mapLoaded && mounted) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _confirm() {
    LatLng? result;
    if (_timedOut) {
      final lat = double.tryParse(_latController.text.trim());
      final lon = double.tryParse(_lonController.text.trim());
      if (lat != null && lon != null && lat.abs() <= 90 && lon.abs() <= 180) {
        result = LatLng(lat, lon);
      }
    } else {
      result = _position;
    }
    if (result != null) Navigator.pop(context, result);
  }

  Future<void> _openInMaps() async {
    final url = Uri.parse('https://www.google.com/maps');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: (_timedOut || _position != null) ? _confirm : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: _timedOut ? _buildFallback() : _buildMap(),
    );
  }

  Widget _buildMap() {
    return GoogleMap(
      initialCameraPosition: const CameraPosition(
        target: LatLng(52.0, 19.0), // center of Poland/Europe
        zoom: 5,
      ),
      onMapCreated: (_) {
        if (mounted) setState(() => _mapLoaded = true);
      },
      onTap: (pos) => setState(() => _position = pos),
      markers: _position != null
          ? {Marker(markerId: const MarkerId('picked'), position: _position!)}
          : <Marker>{},
    );
  }

  Widget _buildFallback() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'Map could not be loaded.\n'
            'You can enter coordinates manually or open Google Maps.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openInMaps,
            icon: const Icon(Icons.map),
            label: const Text('Open in Google Maps'),
          ),
          const SizedBox(height: 24),
          const Text('Or enter coordinates manually:'),
          const SizedBox(height: 12),
          TextFormField(
            controller: _latController,
            decoration: const InputDecoration(
              labelText: 'Latitude (−90…90)',
              hintText: 'e.g. 48.8566',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lonController,
            decoration: const InputDecoration(
              labelText: 'Longitude (−180…180)',
              hintText: 'e.g. 2.3522',
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
          ),
        ],
      ),
    );
  }
}
