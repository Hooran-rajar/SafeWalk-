
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../services/firestore_service.dart';
import '../widgets/primary_button.dart';
import 'map_picker_screen.dart';

class IncidentReportScreen extends StatefulWidget {
  const IncidentReportScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<IncidentReportScreen> createState() =>
      _IncidentReportScreenState();
}

class _IncidentReportScreenState extends State<IncidentReportScreen> {
  final _description = TextEditingController();

  LatLng? _incidentLocation;
  LatLng? _myLocation;
  bool _loading = false;
  bool _gettingLocation = false;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _selectIncidentLocation() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLocation: _incidentLocation,
        ),
      ),
    );

    if (!mounted || result == null) return;
    setState(() => _incidentLocation = result);
  }

  Future<void> _getMyLocation() async {
    setState(() => _gettingLocation = true);

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception('Please turn on GPS/location services.');
      }

      var permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      if (!mounted) return;

      setState(() {
        _myLocation = LatLng(
          position.latitude,
          position.longitude,
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('My Location added.')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $e')),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  Future<void> _save() async {
    if (_description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an incident description.'),
        ),
      );
      return;
    }

    if (_incidentLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the Incident Location on the map.'),
        ),
      );
      return;
    }

    if (!widget.firebaseReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connect Firebase and log in to save incident reports.',
          ),
        ),
      );
      return;
    }

    setState(() => _loading = true);

    final incident = _incidentLocation!;

    final incidentMapUrl =
        'https://www.google.com/maps/search/?api=1&query='
        '${incident.latitude},${incident.longitude}';

    try {
      await FirestoreService().saveIncident(
        description: _description.text,
        location: incidentMapUrl,
        createdAt: DateTime.now(),
        type: 'incident',
        incidentLatitude: incident.latitude,
        incidentLongitude: incident.longitude,
        myLocationLatitude: _myLocation?.latitude,
        myLocationLongitude: _myLocation?.longitude,
      );

      if (!mounted) return;

      _description.clear();
      setState(() {
        _incidentLocation = null;
        _myLocation = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incident report saved to your account.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save report: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incident Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Record what happened',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select where the incident happened. Your current location '
            'is optional and is saved separately.',
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _description,
            minLines: 6,
            maxLines: 10,
            decoration: const InputDecoration(
              labelText: 'Incident description',
              hintText: 'Write what happened and when...',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _selectIncidentLocation,
            icon: const Icon(Icons.map_outlined),
            label: Text(
              _incidentLocation == null
                  ? 'Select Incident Location *'
                  : 'Change Incident Location',
            ),
          ),
          if (_incidentLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              'Incident coordinates: '
              '${_incidentLocation!.latitude.toStringAsFixed(6)}, '
              '${_incidentLocation!.longitude.toStringAsFixed(6)}',
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'My Location (optional)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Use this only if you want to save where you are now. '
            'It does not replace the incident location.',
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _gettingLocation ? null : _getMyLocation,
            icon: _gettingLocation
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _gettingLocation
                  ? 'Getting location...'
                  : _myLocation == null
                      ? 'Use My Current Location'
                      : 'Refresh My Location',
            ),
          ),
          if (_myLocation != null) ...[
            const SizedBox(height: 8),
            Text(
              'My coordinates: '
              '${_myLocation!.latitude.toStringAsFixed(6)}, '
              '${_myLocation!.longitude.toStringAsFixed(6)}',
            ),
            TextButton(
              onPressed: () => setState(() => _myLocation = null),
              child: const Text('Remove My Location'),
            ),
          ],
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Save incident report',
            icon: Icons.save_outlined,
            isLoading: _loading,
            onPressed: _save,
          ),
          const SizedBox(height: 12),
          const Text(
            '* Incident Location is required. My Location is optional.',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ],
      ),
    );
  }
}
