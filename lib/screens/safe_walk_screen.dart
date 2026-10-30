import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../widgets/primary_button.dart';

class SafeWalkScreen extends StatefulWidget {
  final bool firebaseReady;

  const SafeWalkScreen({
    super.key,
    required this.firebaseReady,
  });

  @override
  State<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

class _SafeWalkScreenState extends State<SafeWalkScreen> {
  final TextEditingController _destinationController =
      TextEditingController();

  final FirestoreService _service = FirestoreService();
  final LocationService _locationService = LocationService();

  Timer? _timer;

  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;

  bool _active = false;
  bool _saving = false;

  String? _journeyId;
  double? _startLatitude;
  double? _startLongitude;
  // String? _startLocationMapUrl;

  @override
  void dispose() {
    _timer?.cancel();
    _destinationController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes =
        (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds =
        (duration.inSeconds % 60).toString().padLeft(2, '0');

    return '$hours:$minutes:$seconds';
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _startedAt == null) return;

      setState(() {
        _elapsed = DateTime.now().difference(_startedAt!);
      });
    });
  }

  // ==================== START JOURNEY ====================

  Future<void> _startJourney() async {
    if (_saving || _active) return;

    final destination = _destinationController.text.trim();

    if (destination.isEmpty) {
      _showMessage('Please enter your destination first.');
      return;
    }

    if (!widget.firebaseReady ||
        FirebaseAuth.instance.currentUser == null) {
      _showMessage(
        'Firebase is not ready. Please sign in and try again.',
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    Position? position;
    String? locationError;

    // Fetch the device's current GPS location.
    try {
      position = await _locationService.currentPosition();
    } catch (e) {
      locationError =
          e.toString().replaceFirst('Exception: ', '');
    }

    if (!mounted) return;

    final startTime = DateTime.now();

    // Create the Google Maps URL if GPS is available.
    String? mapUrl;

    if (position != null) {
      mapUrl = 'https://www.google.com/maps/search/?api=1'
          '&query=${position.latitude},${position.longitude}';
    }

    try {
      // Save the journey and its starting location to Firestore.
      final journeyId = await _service.saveJourney(
        destination: destination,
        status: 'started',
        startedAt: startTime,
        startLatitude: position?.latitude,
        startLongitude: position?.longitude,
        startLocationMapUrl: mapUrl,
      );

      if (!mounted) return;

      setState(() {
        _journeyId = journeyId;
        _startedAt = startTime;
        _elapsed = Duration.zero;

        _startLatitude = position?.latitude;
        _startLongitude = position?.longitude;
        // _startLocationMapUrl = mapUrl;

        _active = true;
        _saving = false;
      });

      _destinationController.clear();
      _startTimer();

      if (position == null) {
        _showMessage(
          'Journey saved, but GPS location was unavailable. '
          '${locationError ?? "Please check location permission."}',
        );
      } else {
        _showMessage(
          'Journey started. Starting GPS location saved.',
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _showMessage('Could not save journey: $e');
    }
  }

  // ==================== FINISH JOURNEY ====================

  Future<void> _finishJourney() async {
    if (_saving ||
        !_active ||
        _journeyId == null ||
        _startedAt == null) {
      return;
    }

    setState(() {
      _saving = true;
    });

    _timer?.cancel();

    final finishedAt = DateTime.now();
    final duration = finishedAt.difference(_startedAt!);

    try {
      await _service.finishJourney(
        id: _journeyId!,
        finishedAt: finishedAt,
        duration: duration,
      );

      if (!mounted) return;

      setState(() {
        _active = false;
        _saving = false;
        _journeyId = null;
        _startedAt = null;
        _elapsed = Duration.zero;
        _startLatitude = null;
        _startLongitude = null;
        // _startLocationMapUrl = null;
      });

      _showMessage('Journey completed and saved to history.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _startTimer();
      _showMessage('Could not finish journey: $e');
    }
  }

  // ==================== CANCEL JOURNEY ====================

  Future<void> _cancelJourney() async {
    if (_saving || !_active || _journeyId == null) return;

    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Cancel Journey?'),
          content: const Text(
            'This will remove the current journey from your history. '
            'Do you want to continue?',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Keep Journey'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Cancel Journey'),
            ),
          ],
        );
      },
    );

    if (shouldCancel != true || !mounted) return;

    setState(() {
      _saving = true;
    });

    _timer?.cancel();

    try {
      await _service.deleteJourney(_journeyId!);

      if (!mounted) return;

      setState(() {
        _active = false;
        _saving = false;
        _journeyId = null;
        _startedAt = null;
        _elapsed = Duration.zero;
        _startLatitude = null;
        _startLongitude = null;
        // _startLocationMapUrl = null;
      });

      _showMessage('Journey cancelled.');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      _startTimer();
      _showMessage('Could not cancel journey: $e');
    }
  }

  // ==================== GOOGLE MAPS ====================

  Future<void> _openMap(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1'
      '&query=$latitude,$longitude',
    );

    await _launchMapUrl(url);
  }

  Future<void> _openSavedMapUrl(String savedUrl) async {
    final url = Uri.tryParse(savedUrl);

    if (url == null ||
        url.scheme != 'https' ||
        url.host != 'www.google.com') {
      _showMessage('The saved Google Maps link is invalid.');
      return;
    }

    await _launchMapUrl(url);
  }

  Future<void> _launchMapUrl(Uri url) async {
    try {
      final opened = await launchUrl(
        url,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        _showMessage('Could not open Google Maps.');
      }
    } catch (_) {
      _showMessage('Could not open Google Maps.');
    }
  }

  // ==================== DELETE HISTORY RECORD ====================

  Future<void> _confirmDeleteJourney(String id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Journey?'),
          content: const Text(
            'This journey will be permanently removed from your history.',
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Keep'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) return;

    try {
      await _service.deleteJourney(id);
      _showMessage('Journey deleted.');
    } catch (e) {
      _showMessage('Could not delete journey: $e');
    }
  }

  // ==================== DATE HELPERS ====================

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not available';

    final date = dateTime.toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year, $hour:$minute';
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  // ==================== JOURNEY HISTORY ====================

  Widget _buildJourneyHistory() {
    if (!widget.firebaseReady ||
        FirebaseAuth.instance.currentUser == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Sign in to save and view your journey history.',
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.watchJourneys(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Could not load journey history.'),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final journeys = snapshot.data?.docs ?? [];

        if (journeys.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'No journeys yet. Start a journey to see it here.',
              ),
            ),
          );
        }

        return Column(
          children: journeys.map((document) {
            final data = document.data();

            final destination =
                (data['destination'] ?? 'Unknown destination')
                    .toString();

            final status =
                (data['status'] ?? 'unknown').toString();

            final durationText =
                (data['duration'] ?? 'In progress').toString();

            final startedAt = _readDate(data['startedAt']);
            final finishedAt = _readDate(data['finishedAt']);

            final latitude =
                (data['startLatitude'] as num?)?.toDouble();

            final longitude =
                (data['startLongitude'] as num?)?.toDouble();

            final savedMapUrl =
                data['startLocationMapUrl']?.toString();

            final hasCoordinates =
                latitude != null && longitude != null;

            final hasSavedUrl =
                savedMapUrl != null &&
                savedMapUrl.trim().isNotEmpty;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('Status: $status'),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Delete journey',
                          onPressed: () =>
                              _confirmDeleteJourney(document.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    _detailRow(
                      'Started',
                      _formatDateTime(startedAt),
                    ),
                    const SizedBox(height: 6),
                    _detailRow(
                      'Finished',
                      _formatDateTime(finishedAt),
                    ),
                    const SizedBox(height: 6),
                    _detailRow('Duration', durationText),

                    if (hasCoordinates) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Starting location: '
                        '${latitude.toStringAsFixed(6)}, '
                        '${longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],

                    if (hasSavedUrl) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () =>
                              _openSavedMapUrl(savedMapUrl),
                          icon: const Icon(
                            Icons.location_on_outlined,
                          ),
                          label: const Text(
                            'View Starting Location on Google Maps',
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: 8),
                      const Text(
                        'Starting GPS location was not saved.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 78,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: Text(value)),
      ],
    );
  }

  // ==================== SCREEN UI ====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeWalk'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.shield_outlined,
                size: 54,
                color: Colors.green,
              ),
              const SizedBox(height: 8),
              const Text(
                'SafeWalk Journey Tracker',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter your destination and start tracking your journey.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _destinationController,
                enabled: !_active && !_saving,
                decoration: const InputDecoration(
                  labelText: 'Destination',
                  hintText: 'Where are you going?',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Journey Timer',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDuration(_elapsed),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _active
                          ? 'Journey in progress'
                          : 'Not started',
                    ),
                    if (_active && _startedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Started: ${_formatDateTime(_startedAt)}',
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_active &&
                        _startLatitude != null &&
                        _startLongitude != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => _openMap(
                          _startLatitude!,
                          _startLongitude!,
                        ),
                        icon: const Icon(Icons.map_outlined),
                        label: const Text(
                          'View starting location',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!_active)
                PrimaryButton(
                  label: _saving
                      ? 'Starting...'
                      : 'Start Journey',
                  onPressed: _saving ? null : _startJourney,
                )
              else ...[
                PrimaryButton(
                  label: _saving
                      ? 'Please wait...'
                      : 'Finish Journey',
                  onPressed: _saving ? null : _finishJourney,
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: _saving ? null : _cancelJourney,
                  child: const Text('Cancel Journey'),
                ),
              ],
              const SizedBox(height: 30),
              const Text(
                'Journey History',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildJourneyHistory(),
            ],
          ),
        ),
      ),
    );
  }
}