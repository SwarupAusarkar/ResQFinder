// lib/data/live_data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart'; // Import the new model

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
      final query = _firestore
          .collection('users')
          // ** START: MODIFICATION **
          .where('userType', isEqualTo: 'provider') // Corrected from 'role'
          // ** END: MODIFICATION **
          .where('profileComplete', isEqualTo: true)
          .where('inventory.name', arrayContains: service);

      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return Provider.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print('Error searching providers by service: $e');
      throw Exception('Failed to search providers by service');
    }
  }

  /// Fetch providers (hospital, police, ambulance) near given coordinates
  /// Fetch providers from BOTH Firestore AND OpenStreetMap
  static Future<List<Provider>> fetchProviders({
    required String serviceType,
    double latitude = 19.0760,
    double longitude = 72.8777,
    double radiusInMeters = 5000,
  }) async {
    List<Provider> allProviders = [];

    // 1. Fetch from Firestore (registered providers)
    try {
      final firestoreProviders = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'provider')
          .where('type', isEqualTo: serviceType)
          .where('profileComplete', isEqualTo: true)
          .get();

      allProviders.addAll(firestoreProviders.docs.map((doc) {
        final data = doc.data();
        return Provider.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }));
    } catch (e) {
      print('Error fetching Firestore providers: $e');
    }

    // 2. Fetch from OpenStreetMap (existing code)
    try {
      String osmKey = "";
      switch (serviceType.toLowerCase()) {
        case "hospital":
          osmKey = 'amenity=hospital';
          break;
        case "police":
          osmKey = 'amenity=police';
          break;
        case "ambulance":
          osmKey = 'amenity=clinic';
          break;
        default:
          osmKey = 'amenity=hospital';
      }

      final query = """
        [out:json];
        node[$osmKey](around:$radiusInMeters,$latitude,$longitude);
        out body;
      """;

      final response = await http.post(
        Uri.parse(_overpassUrl),
        body: {"data": query},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final elements = data["elements"] as List<dynamic>;

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
            inventory: [], noOfApprovedRequests: 0, // OSM data won't have inventory
          );
        }));
      }
    } catch (e) {
      print('Error fetching OSM providers: $e');
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