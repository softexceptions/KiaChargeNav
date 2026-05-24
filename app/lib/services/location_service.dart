import 'package:geolocator/geolocator.dart';

typedef GpsPosition = ({double lat, double lon, double heading});

class LocationException implements Exception {
  final String message;
  const LocationException(this.message);
  @override
  String toString() => message;
}

class LocationService {
  Future<GpsPosition> getPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationException('GPS ist deaktiviert. Bitte GPS einschalten.');
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw const LocationException('Standortzugriff verweigert.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Standortberechtigung dauerhaft verweigert — bitte in den App-Einstellungen aktivieren.');
    }

    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
    return (lat: pos.latitude, lon: pos.longitude, heading: pos.heading);
  }
}
