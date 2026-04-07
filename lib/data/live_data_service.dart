// lib/data/live_data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/provider_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _overpassUrl = "https://overpass-api.de/api/interpreter";

  /// Search providers by service with location data
  static Future<List<Provider>> searchProvidersByService({
    required String service,
    required double latitude,
    required double longitude,
  }) async {
    try {
      // FIX: Changed 'users' to 'providers'
      final query = _firestore
          .collection('providers') 
          .where('profileComplete', isEqualTo: true)
          .where('verificationStatus', isEqualTo: 'approved') // Only get verified ones!
          .where('inventory.name', arrayContains: service);

      final querySnapshot = await query.get();

      return querySnapshot.docs.map((doc) {
        return Provider.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error searching providers by service: $e');
      throw Exception('Failed to search providers by service');
    }
  }

  /// Fetch providers (hospital, police, ambulance) near given coordinates
  static Future<List<Provider>> fetchProviders({
    required String serviceType,
    double latitude = 19.0760,
    double longitude = 72.8777,
    double radiusInMeters = 5000,
  }) async {
    List<Provider> allProviders = [];

      // FIX: Changed 'users' to 'providers'
      final firestoreProviders = await _firestore
          .collection('providers')
          .where('type', isEqualTo: serviceType)
          .where('profileComplete', isEqualTo: true)
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      allProviders.addAll(firestoreProviders.docs.map((doc) {
        return Provider.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }));

    // 2. Fetch from OpenStreetMap (With Offline Fallback!)
    try {
      String osmKey = "";
      switch (serviceType.toLowerCase()) {
        case "hospital": osmKey = 'amenity=hospital'; break;
        case "police": osmKey = 'amenity=police'; break;
        case "ambulance": osmKey = 'amenity=clinic'; break;
        default: osmKey = 'amenity=hospital';
      }

      final query = """
        [out:json];
        node[$osmKey](around:$radiusInMeters,$latitude,$longitude);
        out body;
      """;

      // Try fetching live from the internet
      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {"data": query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data["elements"] as List<dynamic>;


        allProviders.addAll(
          elements.map((e) {
            return Provider(
              id: "osm_${e["id"]}",
              name: e["tags"]?["name"] ?? "Unknown ${serviceType.capitalize()}",
              type: serviceType,
              phone: e["tags"]?["phone"] ?? "N/A",
              address: e["tags"]?["addr:full"] ?? "${e["lat"]}, ${e["lon"]}",
              latitude: e["lat"]?.toDouble() ?? latitude,
              longitude: e["lon"]?.toDouble() ?? longitude,
              distance: 0.0,
              isAvailable: true,
              rating: 4,
              description: "Live $serviceType from OpenStreetMap",
              inventory: [],
              noOfApprovedRequests: 0,
              verificationType: '',
              fcmToken: '',
               // OSM data won't have inventory
            );
          }),
        );

        allProviders.addAll(elements.map((e) {
          return Provider(
            id: "osm_${e["id"]}",
            name: e["tags"]?["name"] ?? "Unknown ${serviceType.capitalize()}",
            type: serviceType,
            phone: e["tags"]?["phone"] ?? "N/A",
            address: e["tags"]?["addr:full"] ?? "${e["lat"]}, ${e["lon"]}",
            latitude: e["lat"]?.toDouble() ?? latitude,
            longitude: e["lon"]?.toDouble() ?? longitude,
            distance: 0.0,
            isAvailable: true,
            rating: 4,
            description: "Live $serviceType from OpenStreetMap",
            inventory: [], 
            noOfApprovedRequests: 0,
            verificationType: '',
            fcmToken: '',
          );
        }));

      }
    } catch (e) {
      // OFFLINE FALLBACK: If HTTP post fails (no internet), load from SharedPreferences
      print('No internet for OSM. Loading cached OSM providers...');
      
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('offline_api_'));
      
      for (String key in keys) {
        final String? cachedData = prefs.getString(key);
        if (cachedData != null) {
          final List<dynamic> decodedList = jsonDecode(cachedData);
          for (var item in decodedList) {
            // Only add if it matches the requested serviceType
            if (item['type'] == serviceType) {
               allProviders.add(Provider.fromJson(item['id'], item as Map<String, dynamic>));
            }
          }
        }
      }
    }

    return allProviders;
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
