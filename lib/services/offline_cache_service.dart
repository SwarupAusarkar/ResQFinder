import 'dart:convert';
import 'package:flutter/material.dart';
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

    List<Map<String, dynamic>> providerJsonList = [];

    // 1. FETCH AND SERIALIZE FIREBASE PROVIDERS
    try {
      double latDelta = radiusKm / 111.0; 
      
      // Fetch all approved providers. We filter the coordinates locally in Dart 
      // below to completely avoid Firebase complex index crashes.
      final snap = await FirebaseFirestore.instance.collection('providers')
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      for (var doc in snap.docs) {
        final data = doc.data();
        final pLat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
        final pLng = (data['longitude'] as num?)?.toDouble() ?? 0.0;
        
        // Filter by our coordinate bounding box locally
        if (pLat >= lat - latDelta && pLat <= lat + latDelta && 
            pLng >= lng - latDelta && pLng <= lng + latDelta) {
          data['id'] = doc.id;
          providerJsonList.add(data);
        }
      }
    } catch (e) {
      debugPrint("Firebase Fetch Failed: $e");
    }

    // 2. FETCH AND SERIALIZE OPENSTREETMAP API HOSPITALS
    try {
      final osmProviders = await LiveDataService.fetchProviders(
        serviceType: 'hospital',
        latitude: lat,
        longitude: lng,
        radiusInMeters: radiusKm * 1000,
      );

      final onlyOsm = osmProviders.where((p) => p.id.startsWith('osm_')).toList();
      
      providerJsonList.addAll(onlyOsm.map((p) => {
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
      }));
    } catch (e) {
      debugPrint("OSM API Fetch Failed: $e");
    }

    // 3. SAVE EVERYTHING TO DEVICE STORAGE (Bulletproof local JSON)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('offline_api_$regionName', jsonEncode(providerJsonList));

    // 4. SAVE METADATA TO USER PROFILE
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