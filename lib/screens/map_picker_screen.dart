import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_places_sdk/flutter_places_sdk.dart' hide LatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/places_service.dart';

/// Result returned by [MapPickerScreen] when the user confirms a place.
class MapPickerResult {
  final LatLng coordinates;
  final String name;

  const MapPickerResult({required this.coordinates, required this.name});
}

/// Full-screen map picker for selecting an attraction's GPS coordinates.
/// User taps the map → a pin appears → "Confirm" returns the position.
/// Falls back to manual text entry if the map doesn't load within 5 seconds.
///
/// Use [show] to open as a route. Pass [searchQuery] to pre-fill the search
/// field (e.g., from the attraction name the user already typed).
class MapPickerScreen extends StatefulWidget {
  final String? searchQuery;

  const MapPickerScreen({super.key, this.searchQuery});

  /// Opens the map picker as a full-screen route and returns the selected
  /// result (coordinates + name), or null if the user cancelled.
  ///
  /// If [searchQuery] is provided, it pre-fills the search bar and triggers
  /// an autocomplete lookup immediately.
  static Future<MapPickerResult?> show(BuildContext context,
      {String? searchQuery}) {
    return Navigator.push<MapPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(searchQuery: searchQuery),
      ),
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
  GoogleMapController? _controller;

  // Search fields.
  final _searchController = TextEditingController();
  Timer? _searchTimer;
  int _searchSeq = 0;
  List<AutocompletePrediction> _predictions = [];
  bool _searching = false;
  String? _searchError;
  String? _selectedName;

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

    // Pre-fill search if a query was passed from the attraction dialog.
    if (widget.searchQuery != null && widget.searchQuery!.trim().isNotEmpty) {
      _searchController.text = widget.searchQuery!.trim();
      _searchTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted) _performSearch(_searchController.text);
      });
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _searchTimer?.cancel();
    _searchController.dispose();
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
    if (result != null) {
      final name = _selectedName ?? '';
      Navigator.pop(context, MapPickerResult(coordinates: result, name: name));
    }
  }

  bool get _fallbackCoordsValid {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());
    return lat != null &&
        lon != null &&
        lat.abs() <= 90 &&
        lon.abs() <= 180;
  }

  Future<void> _openInMaps() async {
    final pos = _timedOut
        ? _fallbackCoordsValid
            ? '${_latController.text.trim()},${_lonController.text.trim()}'
            : null
        : _position != null
            ? '${_position!.latitude},${_position!.longitude}'
            : null;
    final uri = Uri.parse(pos != null
        ? 'https://www.google.com/maps?q=$pos'
        : 'https://www.google.com/maps');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('Failed to open maps: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: (_timedOut && _fallbackCoordsValid) ||
                    (!_timedOut && _position != null)
                ? _confirm
                : null,
            child: const Text('Confirm'),
          ),
        ],
      ),
      body: _timedOut ? _buildFallback() : _buildMap(),
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: const CameraPosition(
            target: LatLng(52.0, 19.0), // center of Poland/Europe
            zoom: 5,
          ),
          onMapCreated: (controller) {
            _controller = controller;
            if (mounted) setState(() => _mapLoaded = true);
          },
          onTap: (pos) => setState(() {
            _position = pos;
            _predictions = [];
            _selectedName = null;
          }),
          markers: _position != null
              ? {Marker(markerId: const MarkerId('picked'), position: _position!)}
              : <Marker>{},
        ),
        if (!_timedOut) ...[
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Column(
              children: [
                _buildSearchBar(),
                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _searchError!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        backgroundColor: Colors.white70,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_predictions.isNotEmpty)
            Positioned(
              top: 64,
              left: 8,
              right: 8,
              child: _buildPredictionsOverlay(),
            ),
        ],
      ],
    );
  }

  Widget _buildSearchBar() {
    return Card(
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search for a place...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searching
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _predictions = [];
                          _searchError = null;
                        });
                      },
                    )
                  : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        onChanged: (value) {
          _searchError = null;
          _searchTimer?.cancel();
          if (value.trim().length < 3) {
            setState(() => _predictions = []);
            return;
          }
          _searchTimer = Timer(const Duration(milliseconds: 300), () {
            _performSearch(value.trim());
          });
        },
      ),
    );
  }

  Widget _buildPredictionsOverlay() {
    return Card(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 250),
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: _predictions.length,
          itemBuilder: (context, index) {
            final p = _predictions[index];
            return ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: Text(p.primaryText,
                  style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(p.secondaryText,
                  style: const TextStyle(fontSize: 12)),
              dense: true,
              onTap: () => _onPredictionTap(p),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onPredictionTap(AutocompletePrediction prediction) async {
    setState(() {
      _searching = true;
      _predictions = [];
    });

    final details =
        await getPlacesService().details(prediction.placeId);
    if (!mounted) return;

    if (details != null) {
      final latLng = LatLng(details.latitude, details.longitude);
      setState(() {
        _position = latLng;
        _selectedName =
            details.name.isNotEmpty ? details.name : prediction.primaryText;
        _searchController.text = _selectedName ?? '';
        _searching = false;
      });
      _controller?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
    } else {
      setState(() {
        _searching = false;
        _searchError = 'Could not load place details. Try again.';
      });
    }
  }

  Future<void> _performSearch(String query) async {
    if (!getPlacesService().isAvailable) {
      setState(() => _searchError =
          'Places search not available. Enter coordinates manually.');
      return;
    }

    final seq = ++_searchSeq;
    setState(() => _searching = true);
    try {
      final results = await getPlacesService().autocomplete(query);
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _predictions = results;
        _searching = false;
        if (results.isEmpty) {
          _searchError = 'No places found.';
        }
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _searching = false;
        _searchError = 'Failed to search. Check your connection.';
      });
    }
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
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lonController,
            decoration: const InputDecoration(
              labelText: 'Longitude (−180…180)',
              hintText: 'e.g. 2.3522',
            ),
            keyboardType: const TextInputType.numberWithOptions(
                decimal: true, signed: true),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
