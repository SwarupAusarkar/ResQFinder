import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/provider_model.dart';

class LiveDataService {
  static const String _overpassUrl = "https://overpass-api.de/api/interpreter";

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