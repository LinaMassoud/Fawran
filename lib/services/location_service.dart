import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static Future<String> getCurrentCityName() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'Riyadh'; // Default fallback
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return 'Riyadh'; // Default fallback
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return 'Riyadh'; // Default fallback
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      // Get city name from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        String cityName = placemarks.first.locality ?? 
                         placemarks.first.administrativeArea ?? 
                         'Riyadh';
        return cityName;
      }
    } catch (e) {
      print('Error getting location: $e');
    }
    
    return 'Riyadh'; // Default fallback
  }
}