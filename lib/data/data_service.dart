import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/provider_model.dart';
import '../models/request_model.dart';
import '../models/inventory_item_model.dart';

class DataService {
  static List<Provider> _providers = [];
  static List<EmergencyRequest> _requests = [];

  // Load all providers from JSON file
  static Future<List<Provider>> loadProviders() async {
    if (_providers.isEmpty) {
      try {
        final String jsonString =
        await rootBundle.loadString('assets/data/providers.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);

        final List<dynamic> providersJson = jsonData['providers'];
        _providers = providersJson
            .map((json) => Provider.fromJson(json['id'] ?? '', json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error loading providers from JSON, using fallback: $e');
        _providers = _getFallbackProviders();
      }
    }
    return _providers;
  }

  // Load all emergency requests (dummy/fallback only for now)
  static Future<List<EmergencyRequest>> loadRequests() async {
    if (_requests.isEmpty) {
      try {
        // If you have a requests.json, load that instead
        final String jsonString =
        await rootBundle.loadString('assets/data/requests.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        final List<dynamic> requestsJson = jsonData['requests'];
        _requests = requestsJson
            .map((json) => EmergencyRequest.fromJson(json['id'] ?? '', json as Map<String, dynamic>))
            .toList();
      } catch (e) {
        print('Error loading requests from JSON, using fallback: $e');
        _requests = _getFallbackRequests();
      }
    }
    return _requests;
  }

  // Fallback providers
  static List<Provider> _getFallbackProviders() {
    return [
      Provider(
        id: 'h001',
        name: 'King Edward Memorial Hospital',
        type: 'hospital',
        phone: '+91-22-2410-7000',
        address: 'Acharya Donde Marg, Parel, Mumbai, Maharashtra 400012',
        latitude: 19.0176,
        longitude: 72.8443,
        distance: 2.5,
        isAvailable: true,
        rating: 5,
        description: 'Major government hospital with 24/7 emergency services.',
        inventory: [
          InventoryItem(
              name: 'ICU Bed',
              quantity: 10,
              unit: 'beds',
              lastUpdated: DateTime.now()),
          InventoryItem(
              name: 'Emergency Surgery',
              quantity: 5,
              unit: 'rooms',
              lastUpdated: DateTime.now()),
        ], noOfApprovedRequests: 0,
      ),
      Provider(
        id: 'h002',
        name: 'Lilavati Hospital',
        type: 'hospital',
        phone: '+91-22-2640-5000',
        address: 'A-791, Bandra Reclamation, Bandra West, Mumbai, Maharashtra 400050',
        latitude: 19.0544,
        longitude: 72.8266,
        distance: 3.2,
        isAvailable: true,
        rating: 5,
        description: 'Premium private hospital with advanced medical facilities.',
        inventory: [
          InventoryItem(
              name: 'ICU Bed',
              quantity: 20,
              unit: 'beds',
              lastUpdated: DateTime.now()),
          InventoryItem(
              name: 'MRI Scan',
              quantity: 2,
              unit: 'machines',
              lastUpdated: DateTime.now()),
        ], noOfApprovedRequests: 0,
      ),
    ];
  }

  // Fallback requests
  static List<EmergencyRequest> _getFallbackRequests() {
    return [
      EmergencyRequest(
        id: 'r001-fallback',
        masterRequestId: 'fallback-master-001',
        requesterId: 'fallback-user-001',
        requesterName: 'Rajesh Kumar (Dummy)',
        description: 'Heart attack symptoms, urgent.',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'pending',
        requesterPhone: '+91-98765-43210',
        latitude: 19.0596,
        longitude: 72.8295,
        itemName: 'ICU Bed',
        itemQuantity: 1,
        itemUnit: 'beds',
        providerId: null, acceptedAt: DateTime.now(), acceptedBy: '', locationName: '', // not yet accepted
      ),
    ];
  }

  static void clearCache() {
    _providers.clear();
    _requests.clear();
  }
  // Get providers filtered by service type
  static Future<List<Provider>> getProvidersByType(String serviceType) async {
    final allProviders = await loadProviders();
    return allProviders.where((provider) =>
    provider.type.toLowerCase() == serviceType.toLowerCase()
    ).toList();
  }

  static void updateProviderAvailability(String providerId, bool isAvailable) {
    final index = _providers.indexWhere((p) => p.id == providerId);
    if (index != -1) {
      final oldProvider = _providers[index];
      _providers[index] = Provider(
        id: oldProvider.id,
        name: oldProvider.name,
        type: oldProvider.type,
        phone: oldProvider.phone,
        address: oldProvider.address,
        latitude: oldProvider.latitude,
        longitude: oldProvider.longitude,
        distance: oldProvider.distance,
        isAvailable: isAvailable,
        rating: oldProvider.rating,
        description: oldProvider.description,
        inventory: oldProvider.inventory, noOfApprovedRequests: 0,
      );
    }
  }
}

