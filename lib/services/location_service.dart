import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Fetches the current location. Returns null if permissions are denied.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('❌ Location services are disabled.');
      return Future.error('Location services are disabled.');
    }

    // 2. Check and request permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('❌ Location permissions are denied');
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('❌ Location permissions are permanently denied');
      return null;
    }

    // 3. Get exact current location
    // Use LocationAccuracy.high for the best results
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  static Future<String> getAddressFromLatLng(
      double latitude,
      double longitude,
      ) async {
    try {
      final placemarks =
      await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isEmpty) {
        return "No address found";
      }

      final place = placemarks.first;

      final List<String> addressParts = [];

      if (place.name != null && place.name!.isNotEmpty) {
        addressParts.add(place.name!);
      }

      if (place.subLocality != null && place.subLocality!.isNotEmpty) {
        addressParts.add(place.subLocality!);
      }

      if (place.locality != null && place.locality!.isNotEmpty) {
        addressParts.add(place.locality!);
      }

      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty) {
        addressParts.add(place.administrativeArea!);
      }

      if (place.postalCode != null && place.postalCode!.isNotEmpty) {
        addressParts.add(place.postalCode!);
      }

      if (place.country != null && place.country!.isNotEmpty) {
        addressParts.add(place.country!);
      }

      return addressParts.join(", ");
    } catch (e) {
      print("Geocoding error: $e");
      return "Unable to fetch address";
    }
  }

}