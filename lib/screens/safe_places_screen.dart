import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SafePlacesScreen extends StatelessWidget {
  const SafePlacesScreen({super.key});

  Future<void> _search(String query) async {
    final searchQuery = '$query, Jamshoro, Sindh, Pakistan';

    final uri = Uri.https(
      'www.openstreetmap.org',
      '/search',
      {'query': searchQuery},
    );

    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened) {
      debugPrint('Could not open OpenStreetMap.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final places = [
      (
        'Police stations',
        Icons.local_police_rounded,
        'police station'
      ),
      (
        'Hospitals',
        Icons.local_hospital_rounded,
        'hospital'
      ),
      (
        'University security',
        Icons.school_rounded,
        'university security office'
      ),
      (
        'Pharmacies',
        Icons.local_pharmacy_rounded,
        'pharmacy'
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Safe Places')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFDDF7EF),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.map_rounded,
                  size: 34,
                  color: Color(0xFF087F6E),
                ),
                SizedBox(height: 10),
                Text(
                  'Find nearby support',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Search for nearby services around Jamshoro. '
                  'Verify the place and its availability before relying on it.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...places.map(
            (p) => Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFFE5F4EF),
                  child: Icon(
                    p.$2,
                    color: const Color(0xFF087F6E),
                  ),
                ),
                title: Text(
                  p.$1,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: const Text('Search on OpenStreetMap'),
                trailing: const Icon(Icons.open_in_new_rounded),
                onTap: () => _search(p.$3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}