// lib/data/data_service.dart

import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/provider_model.dart';
import '../models/request_model.dart';
import '../models/inventory_item_model.dart'; // Import the new model

// Service class to handle loading dummy data from JSON files
class DataService {
  static List<Provider> _providers = [];
  static List<EmergencyRequest> _requests = [];

  // Load all providers from JSON file
  static Future<List<Provider>> loadProviders() async {
    if (_providers.isEmpty) {
      try {
        // Load JSON file from assets (consistent filename)
        final String jsonString = await rootBundle.loadString('assets/data/providers.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        
        // Parse providers list
        final List<dynamic> providersJson = jsonData['providers'];
        _providers = providersJson.map((json) => Provider.fromJson(json)).toList();
      } catch (e) {
        print('Error loading providers: $e');
        _providers = _getFallbackProviders();
      }
    }
    return _providers;
  }

  // Load all emergency requests from JSON file
  static Future<List<EmergencyRequest>> loadRequests() async {
    if (_requests.isEmpty) {
      try {
        // Use same file for consistency
        final String jsonString = await rootBundle.loadString('assets/data/providers.json');
        final Map<String, dynamic> jsonData = json.decode(jsonString);
        
        // Parse requests list
        final List<dynamic> requestsJson = jsonData['requests'];
        _requests = requestsJson.map((json) => EmergencyRequest.fromJson(json)).toList();
      } catch (e) {
        print('Error loading requests: $e');
        _requests = _getFallbackRequests();
      }
    }
    return _requests;
  }

  // Get providers filtered by service type
  static Future<List<Provider>> getProvidersByType(String serviceType) async {
    final allProviders = await loadProviders();
    return allProviders.where((provider) => 
      provider.type.toLowerCase() == serviceType.toLowerCase()
    ).toList();
  }

  // NEW: Search providers by specific service/inventory
  // Uses the services array in provider data
  static Future<List<Provider>> searchProvidersByService(String service) async {
    final allProviders = await loadProviders();
    return allProviders.where((provider) => 
      provider.offersService(service)
    ).toList();
  }

  // NEW: Get all available services from all providers
  // Useful for building search suggestions
  static Future<List<String>> getAllAvailableServices() async {
    final allProviders = await loadProviders();
    final Set<String> allServices = {};
    
    for (final provider in allProviders) {
      allServices.addAll(provider.inventory.map((item) => item.name));
    }
    
    return allServices.toList()..sort();
  }

  // NEW: Search service suggestions with partial matching
  static Future<List<String>> searchServiceSuggestions(String query) async {
    try {
      final allServices = await getAllAvailableServices();
      
      return allServices
          .where((service) => service.toLowerCase().contains(query.toLowerCase()))
          .take(10)
          .toList();
    } catch (e) {
      print('Error searching service suggestions: $e');
      return [];
    }
  }

  // Get provider by ID
  static Future<Provider?> getProviderById(String id) async {
    final allProviders = await loadProviders();
    try {
      return allProviders.firstWhere((provider) => provider.id == id);
    } catch (e) {
      return null;
    }
  }

  // Get available providers only
  static Future<List<Provider>> getAvailableProviders(String serviceType) async {
    final providers = await getProvidersByType(serviceType);
    return providers.where((provider) => provider.isAvailable).toList();
  }

  // Sort providers by distance (closest first)
  static List<Provider> sortProvidersByDistance(List<Provider> providers) {
    providers.sort((a, b) => a.distance.compareTo(b.distance));
    return providers;
  }

  // Sort providers by rating (highest first)
  static List<Provider> sortProvidersByRating(List<Provider> providers) {
    providers.sort((a, b) => b.rating.compareTo(a.rating));
    return providers;
  }

  // Sort providers by availability (available first)
  static List<Provider> sortProvidersByAvailability(List<Provider> providers) {
    providers.sort((a, b) {
      if (a.isAvailable == b.isAvailable) return 0;
      return a.isAvailable ? -1 : 1;
    });
    return providers;
  }

  // Get nearest providers within a certain radius
  static Future<List<Provider>> getNearestProviders(
    String serviceType, 
    double maxDistance,
  ) async {
    final providers = await getProvidersByType(serviceType);
    return providers
        .where((provider) => provider.distance <= maxDistance)
        .toList();
  }

  // Search providers by name or address
  static Future<List<Provider>> searchProviders(String query) async {
    final allProviders = await loadProviders();
    final lowerQuery = query.toLowerCase();
    
    return allProviders.where((provider) =>
        provider.name.toLowerCase().contains(lowerQuery) ||
        provider.address.toLowerCase().contains(lowerQuery) ||
        provider.type.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  // Get providers statistics
  static Future<Map<String, dynamic>> getProvidersStats() async {
    final allProviders = await loadProviders();
    final available = allProviders.where((p) => p.isAvailable).length;
    final hospitals = allProviders.where((p) => p.type == 'hospital').length;
    final police = allProviders.where((p) => p.type == 'police').length;
    final ambulances = allProviders.where((p) => p.type == 'ambulance').length;
    
    return {
      'total': allProviders.length,
      'available': available,
      'busy': allProviders.length - available,
      'hospitals': hospitals,
      'police': police,
      'ambulances': ambulances,
      'averageRating': allProviders.isEmpty 
          ? 0.0 
          : allProviders.map((p) => p.rating).reduce((a, b) => a + b) / allProviders.length,
    };
  }

  // Fallback providers with Mumbai data - UPDATED with services array
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
          InventoryItem(name: 'ICU Bed', quantity: 10, unit: 'beds', lastUpdated: DateTime.now()),
          InventoryItem(name: 'Emergency Surgery', quantity: 5, unit: 'rooms', lastUpdated: DateTime.now()),
        ],
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
          InventoryItem(name: 'ICU Bed', quantity: 20, unit: 'beds', lastUpdated: DateTime.now()),
          InventoryItem(name: 'MRI Scan', quantity: 2, unit: 'machines', lastUpdated: DateTime.now()),
        ],
      ),
      // ... more fallback providers
    ];
  }

  // Fallback requests with Mumbai data
  static List<EmergencyRequest> _getFallbackRequests() {
    return [
      EmergencyRequest(
        id: 'r001',
        requesterName: 'Rajesh Kumar',
        requesterPhone: '+91-98765-43210',
        serviceType: 'ambulance',
        description: 'Heart attack symptoms, need immediate medical attention',
        latitude: 19.0596,
        longitude: 72.8295,
        address: 'Linking Road, Bandra West, Mumbai, Maharashtra 400050',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'pending',
        priority: 'critical',
      ),
    ];
  }

  // Clear cache (useful for testing or refresh)
  static void clearCache() {
    _providers.clear();
    _requests.clear();
  }

  // Mock method to update provider availability (for demo purposes)
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
        inventory: oldProvider.inventory,
      );
    }
  }
}