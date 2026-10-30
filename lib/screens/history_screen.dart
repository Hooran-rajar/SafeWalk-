
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Future<void> _deleteReport(
    BuildContext context,
    DocumentReference<Map<String, dynamic>> reference,
    String title,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete report?'),
        content: Text(
          'Are you sure you want to delete this $title? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted || confirmed != true) return;

    try {
      await reference.delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$title deleted successfully.')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not delete report: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Past Reports')),
        body: const Center(
          child: Text('Please log in to view your history.'),
        ),
      );
    }

    final reportsStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Past Reports & SOS History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: reportsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Unable to load reports. Check your connection '
                'and Firestore permissions.',
                textAlign: TextAlign.center,
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final documents = snapshot.data?.docs ?? [];

          if (documents.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No past reports yet.\nYour saved reports and SOS logs '
                  'will appear here.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: documents.length,
            itemBuilder: (context, index) {
              final document = documents[index];
              final report = document.data();

              final description =
                  report['description']?.toString() ?? 'Incident report';

              final type = report['type']?.toString();
              final isSos = type == 'sos' ||
                  (type == null &&
                      description.toLowerCase().contains('sos'));

              final legacyLocation =
                  report['location']?.toString() ?? '';

              final incidentLat = _asDouble(report['incidentLatitude']);
              final incidentLng = _asDouble(report['incidentLongitude']);
              final myLat = _asDouble(report['myLocationLatitude']);
              final myLng = _asDouble(report['myLocationLongitude']);

              final createdAt = report['createdAt'];
              DateTime? dateTime;

              if (createdAt is Timestamp) {
                dateTime = createdAt.toDate();
              } else if (createdAt is DateTime) {
                dateTime = createdAt;
              }

              final dateText = dateTime == null
                  ? 'Date unavailable'
                  : '${dateTime.day.toString().padLeft(2, '0')}/'
                      '${dateTime.month.toString().padLeft(2, '0')}/'
                      '${dateTime.year}  '
                      '${dateTime.hour.toString().padLeft(2, '0')}:'
                      '${dateTime.minute.toString().padLeft(2, '0')}';

              return Card(
                margin: const EdgeInsets.only(bottom: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: isSos
                                ? Colors.red.shade50
                                : Colors.teal.shade50,
                            child: Icon(
                              isSos
                                  ? Icons.sos_rounded
                                  : Icons.assignment_rounded,
                              color: isSos ? Colors.red : Colors.teal,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSos ? 'SOS Log' : 'Incident Report',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateText,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Delete button
                          IconButton(
                            tooltip: 'Delete report',
                            onPressed: () => _deleteReport(
                              context,
                              document.reference,
                              isSos ? 'SOS log' : 'incident report',
                            ),
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Description',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(description),
                      const SizedBox(height: 12),
                      if (incidentLat != null && incidentLng != null)
                        _MapButton(
                          label: 'View Incident Location',
                          onTap: () => _openCoordinates(
                            context,
                            incidentLat,
                            incidentLng,
                          ),
                        )
                      else if (legacyLocation.isNotEmpty)
                        _MapButton(
                          label: 'Open saved location',
                          onTap: () => _openLegacyMap(
                            context,
                            legacyLocation,
                          ),
                        ),
                      if (myLat != null && myLng != null) ...[
                        const SizedBox(height: 8),
                        _MapButton(
                          label: 'View My Location',
                          onTap: () => _openCoordinates(
                            context,
                            myLat,
                            myLng,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  Future<void> _openCoordinates(
    BuildContext context,
    double latitude,
    double longitude,
  ) async {
    final uri = Uri.https(
      'www.google.com',
      '/maps/search/',
      {'api': '1', 'query': '$latitude,$longitude'},
    );

    await _openUri(context, uri);
  }

  Future<void> _openLegacyMap(
    BuildContext context,
    String location,
  ) async {
    final uri = Uri.tryParse(location);

    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != 'www.google.com' &&
            uri.host != 'maps.google.com')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This report has no valid saved map link.'),
        ),
      );
      return;
    }

    await _openUri(context, uri);
  }

  Future<void> _openUri(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the map.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to open the map.')),
        );
      }
    }
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.teal),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.teal,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, size: 18),
          ],
        ),
      ),
    );
  }
}
