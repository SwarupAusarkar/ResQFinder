// lib/data/live_data_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/provider_model.dart';
import '../models/inventory_item_model.dart';

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
          .collection('providers')
          .where('profileComplete', isEqualTo: true)
      // Note: This works if inventory is a list of strings.
      // If inventory is a list of objects, Firestore has limitations here.
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
      // FIX: Removed strict 'type' query. Fetch all approved and filter smartly.
      final firestoreProviders = await _firestore
          .collection('providers')
          .where('profileComplete', isEqualTo: true)
          .where('verificationStatus', isEqualTo: 'approved')
          .get();

      final targetType = serviceType.toLowerCase();

      // Smart filter: checks both 'providerType' and 'type' for the keyword
      final matchedDocs = firestoreProviders.docs.where((doc) {
        final data = doc.data();
        final dbType = (data['providerType'] ?? data['type'] ?? '').toString().toLowerCase();
        
        return dbType.contains(targetType) || targetType == 'all';
      }).toList();

      allProviders.addAll(matchedDocs.map((doc) {
        return Provider.fromJson(doc.id, doc.data() as Map<String, dynamic>);
      }));
    } catch (e) {
      print('Error fetching Firestore providers: $e');
    }

    // 2. Fetch from OpenStreetMap
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

        final osmProviders = elements.map((e) {
          final tags = e["tags"] ?? {};
          return Provider(
            id: "osm_${e["id"]}",
            name: tags["name"] ?? "Unknown ${serviceType.capitalize()}",
            type: serviceType,
            phone: tags["phone"] ?? tags["contact:phone"] ?? "N/A",
            address: tags["addr:full"] ?? tags["addr:street"] ?? "${e["lat"]}, ${e["lon"]}",
            latitude: e["lat"]?.toDouble() ?? latitude,
            longitude: e["lon"]?.toDouble() ?? longitude,
            distance: 0.0,
            isAvailable: true,
            rating: 4.0,
            description: "Public $serviceType data from OpenStreetMap",
            inventory: [], 
            noOfApprovedRequests: 0,
            verificationType: tags["verificationType"] ?? 'osm_verified',
            fcmToken: '',
          );
        }).toList();

        allProviders.addAll(osmProviders);
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
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
}