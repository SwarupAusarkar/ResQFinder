import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../data/live_data_service.dart';

class OfflineCacheService {
  
  static Future<void> saveRegion({
    required String regionName,
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    final user = AuthService().currentUser;
    if (user == null) throw Exception("Must be logged in to save trips.");

    // 1. CACHE FIRESTORE PROVIDERS (Auto-caches to local Firebase DB)
    double latDelta = radiusKm / 111.0; 
    await FirebaseFirestore.instance.collection('providers')
        .where('verificationStatus', isEqualTo: 'approved')
        .where('latitude', isGreaterThanOrEqualTo: lat - latDelta)
        .where('latitude', isLessThanOrEqualTo: lat + latDelta)
        .get();

    // 2. CACHE OPENSTREETMAP API HOSPITALS
    // Fetch live from the API while we still have internet
    final osmProviders = await LiveDataService.fetchProviders(
      serviceType: 'hospital',
      latitude: lat,
      longitude: lng,
      radiusInMeters: radiusKm * 1000,
    );

    // Filter out Firebase providers (we only want to save the OSM ones here)
    final onlyOsm = osmProviders.where((p) => p.id.startsWith('osm_')).toList();

    // Convert the Provider objects to a JSON string
    final List<Map<String, dynamic>> providerJsonList = onlyOsm.map((p) => {
      'id': p.id,
      'name': p.name,
      'type': p.type,
      'phone': p.phone,
      'address': p.address,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'distance': p.distance,
      'isAvailable': p.isAvailable,
      'rating': p.rating,
      'description': p.description,
      'inventory': p.inventory, 
      'noOfApprovedRequests': p.noOfApprovedRequests ?? 0,
    }).toList();

    // Save to device storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_api_$regionName', jsonEncode(providerJsonList));

    // 3. SAVE METADATA TO USER PROFILE
    final newLocation = {
      'name': regionName,
      'latitude': lat,
      'longitude': lng,
      'radius': radiusKm,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance.collection('requesters').doc(user.uid).update({
      'savedLocations': FieldValue.arrayUnion([newLocation])
    });
  }
}