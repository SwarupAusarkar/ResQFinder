import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LiveDataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _overpassUrl = "https://overpass-api.de/api/interpreter";

  // Add these methods to your existing LiveDataService class

/// Search providers by service with location data
static Future<List<Provider>> searchProvidersByService({
  required String service,
  required double latitude,
  required double longitude,
}) async {
  try {
    final query = _firestore
        .collection('users')
        .where('role', isEqualTo: 'provider')
        .where('profileComplete', isEqualTo: true)
        .where('services', arrayContains: service);

    final querySnapshot = await query.get();
    
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return Provider(
        id: doc.id,
        name: data['name'] ?? '',
        type: data['type'] ?? 'hospital',
        phone: data['phone'] ?? '',
        address: data['address'] ?? '',
        latitude: data['latitude']?.toDouble() ?? 0.0,
        longitude: data['longitude']?.toDouble() ?? 0.0,
        distance: 0.0, // Will be calculated in the screen
        isAvailable: data['isAvailable'] ?? true,
        rating: data['rating'] ?? 5,
        description: data['description'] ?? '',
        services: List<String>.from(data['services'] ?? []),
      );
    }).toList();
  } catch (e) {
    print('Error searching providers by service: $e');
    throw Exception('Failed to search providers by service');
  }
}

  /// Fetch providers (hospital, police, ambulance) near given coordinates
  static Future<List<Provider>> fetchProviders({
    required String serviceType,
    double latitude = 19.0760, // Mumbai lat
    double longitude = 72.8777, // Mumbai lon
    double radiusInMeters = 5000, // 5 km radius
  }) async {
    String osmKey = "";
    switch (serviceType.toLowerCase()) {
      case "hospital":
        osmKey = 'amenity=hospital';
        break;
      case "police":
        osmKey = 'amenity=police';
        break;
      case "ambulance":
        osmKey = 'amenity=clinic'; // OSM has ambulance under clinics/medical
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

    if (response.statusCode != 200) {
      throw Exception("Failed to fetch providers: ${response.body}");
    }

    final data = json.decode(response.body);
    final elements = data["elements"] as List<dynamic>;

    return elements.map((e) {
      return Provider(
        id: e["id"].toString(),
        name: e["tags"]?["name"] ?? "Unknown ${serviceType.capitalize()}",
        type: serviceType,
        phone: e["tags"]?["phone"] ?? "N/A",
        address: e["tags"]?["addr:full"] ??
            "${e["lat"]}, ${e["lon"]}", // fallback to coords
        latitude: e["lat"]?.toDouble() ?? latitude,
        longitude: e["lon"]?.toDouble() ?? longitude,
        distance: 0.0, // we’ll calculate later
        isAvailable: true,
        rating: 4,
        description: "Live $serviceType from OpenStreetMap",
      );
    }).toList();
  }
}

extension StringCapitalize on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}