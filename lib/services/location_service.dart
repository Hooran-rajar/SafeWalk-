
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Gets the user's current GPS location.
  Future<Position> currentPosition() async {
    // Step 1: Check whether GPS/location services are enabled.
    final serviceEnabled = await Geolocator.isLocationServiceEnabled()
        .timeout(const Duration(seconds: 3));

    if (!serviceEnabled) {
      throw Exception(
        'Please turn on Location/GPS on your device.',
      );
    }

    // Step 2: Check and request location permission.
    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission denied. Please enable it in Settings.',
      );
    }

    // Step 3: Use a recent cached location if it is reliable.
    try {
      final lastPosition = await Geolocator.getLastKnownPosition();

      if (lastPosition != null) {
        final age = DateTime.now().difference(lastPosition.timestamp);

        if (age >= Duration.zero &&
            age <= const Duration(seconds: 30) &&
            lastPosition.accuracy <= 100) {
          return lastPosition;
        }
      }
    } catch (_) {
      // If cached location is unavailable, request a fresh location.
    }

    // Step 4: Request a fresh, high-accuracy location.
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 12),
      ),
    );
  }

  /// Creates a Google Maps URL for the supplied coordinates.
  String mapUrl(double latitude, double longitude) {
    return 'https://www.google.com/maps/search/'
        '?api=1&query=$latitude,$longitude';
  }

  /// Returns a readable latitude/longitude string.
  String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, '
        '${longitude.toStringAsFixed(6)}';
  }
}
