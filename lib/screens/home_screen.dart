import 'package:flutter/material.dart';
import 'history_screen.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import 'contacts_screen.dart';
import 'incident_report_screen.dart';
import 'safe_places_screen.dart';
import 'safe_walk_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.firebaseReady});

  final bool firebaseReady;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _sosLoading = false;

  void _message(String value) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(value)));
  }

  Future<void> _sos() async {
    setState(() => _sosLoading = true);
    Future.delayed(const Duration(seconds: 20), () {
  if (mounted && _sosLoading) {
    setState(() => _sosLoading = false);
  }
});
    try {
      final position = await LocationService().currentPosition();
      final url = LocationService().mapUrl(position.latitude, position.longitude);
      if (widget.firebaseReady) {
        await FirestoreService().saveIncident(
          description: 'SOS initiated from SafeWalk home screen.',
          location: url,
          createdAt: DateTime.now(),
        );
      }
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('SOS location ready'),
          content: SelectableText(
            'Your current coordinates:\n${position.latitude}, ${position.longitude}\n\nMap link:\n$url\n\nThis prototype has not automatically sent an alert. Use your contact/call or share action to contact someone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      _message('Could not get location: $e');
    } finally {
      if (mounted) setState(() => _sosLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.firebaseReady ? AuthService().currentUser : null;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.shield_rounded, color: Color(0xFF087F6E)),
            SizedBox(width: 8),
            Text('SafeWalk', style: TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          if (widget.firebaseReady)
            IconButton(
              tooltip: 'Log out',
              onPressed: () async {
                await AuthService().logout();
              },
              icon: const Icon(Icons.logout_rounded),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            if (!widget.firebaseReady)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF2D7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'Preview mode — Firebase account and database actions are disabled until setup is complete.',
                ),
              ),
            const SizedBox(height: 16),
            Text(
              user == null ? 'Your safety, in one place' : 'Hello, ${user.displayName ?? 'there'}',
              style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay aware, stay connected, and let trusted people know when you need help.',
              style: TextStyle(color: Colors.blueGrey.shade600, height: 1.4),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF087F6E), Color(0xFF0D9A83)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                children: [
                  const Icon(Icons.shield_moon_rounded, size: 36, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Need help right now?',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Get your current location and prepare an emergency record.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: FilledButton(
                      onPressed: _sosLoading ? null : _sos,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFE5484D),
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(
                          side: BorderSide(color: Colors.white, width: 5),
                        ),
                      ),
                      child: _sosLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sos_rounded, size: 42),
                                Text('SOS',
                                    style: TextStyle(
                                        fontSize: 26, fontWeight: FontWeight.w900)),
                                Text('Tap for location',
                                    style: TextStyle(fontSize: 11)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your safety tools',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.05,
              children: [
                _FeatureCard(
                  icon: Icons.directions_walk_rounded,
                  title: 'Safe Walk',
                  subtitle: 'Start a journey',
                  color: const Color(0xFFE0F6EE),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => SafeWalkScreen(firebaseReady: widget.firebaseReady))),
                ),
                _FeatureCard(
                  icon: Icons.people_alt_rounded,
                  title: 'Contacts',
                  subtitle: 'Trusted people',
                  color: const Color(0xFFE7EDFF),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ContactsScreen(firebaseReady: widget.firebaseReady))),
                ),
                _FeatureCard(
                  icon: Icons.place_rounded,
                  title: 'Safe Places',
                  subtitle: 'Find nearby help',
                  color: const Color(0xFFFFEEDC),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const SafePlacesScreen())),
                ),
                _FeatureCard(
                  icon: Icons.assignment_rounded,
                  title: 'Incident Report',
                  subtitle: 'Record an event',
                  color: const Color(0xFFF1E7FF),
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => IncidentReportScreen(firebaseReady: widget.firebaseReady))),
                ),
                _FeatureCard(
  icon: Icons.history_rounded,
  title: 'Past Reports',
  subtitle: 'SOS & incident history',
  color: const Color(0xFFDDF5F0),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const HistoryScreen(),
    ),
  ),
),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'If you are in immediate danger, contact local emergency services directly. SafeWalk is a student-project prototype.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: const Color(0xFF087F6E), size: 26),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
            ],
          ),
        ),
      ),
    );
  }
}
