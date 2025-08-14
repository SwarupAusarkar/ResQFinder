import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/provider_model.dart';
import '../models/request_model.dart';

// Service class to handle loading dummy data from JSON files
class DataService {
  static List<Provider> _providers = [];
  static List<EmergencyRequest> _requests = [];

  // Load all providers from JSON file
  static Future<List<Provider>> loadProviders() async {
    if (_providers.isEmpty) {
      try {
        // Load JSON file from assets (fixed filename to match the actual file)
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
        final String jsonString = await rootBundle.loadString('assets/data/providors.json');
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

  // Fallback providers in case JSON loading fails
  static List<Provider> _getFallbackProviders() {
    return [
      Provider(
        id: 'h001',
        name: 'City General Hospital',
        type: 'hospital',
        phone: '+1-555-0101',
        address: '123 Main St, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        distance: 2.5,
        isAvailable: true,
        rating: 4,
        description: '24/7 emergency care with specialist doctors.',
      ),
      Provider(
        id: 'p001',
        name: 'Downtown Police Station',
        type: 'police',
        phone: '+1-555-0201',
        address: '100 Police Plaza, Downtown',
        latitude: 40.7122,
        longitude: -74.0055,
        distance: 2.1,
        isAvailable: true,
        rating: 4,
        description: 'Main police station with 24/7 response.',
      ),
      Provider(
        id: 'a001',
        name: 'City Ambulance Service',
        type: 'ambulance',
        phone: '+1-555-0301',
        address: 'Emergency Services Building, Downtown',
        latitude: 40.7128,
        longitude: -74.0060,
        distance: 1.2,
        isAvailable: true,
        rating: 5,
        description: 'Advanced life support ambulance service.',
      ),
    ];
  }

  // Fallback requests in case JSON loading fails
  static List<EmergencyRequest> _getFallbackRequests() {
    return [
      EmergencyRequest(
        id: 'r001',
        requesterName: 'John Doe',
        requesterPhone: '+1-555-1001',
        serviceType: 'ambulance',
        description: 'Chest pain, need immediate attention',
        latitude: 40.7128,
        longitude: -74.0060,
        address: '123 Emergency St, Downtown',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        status: 'pending',
        priority: 'critical',
      ),
      EmergencyRequest(
        id: 'r002',
        requesterName: 'Jane Smith',
        requesterPhone: '+1-555-1002',
        serviceType: 'police',
        description: 'Car accident on Main Street, minor injuries',
        latitude: 40.7589,
        longitude: -73.9851,
        address: '456 Main Street, Midtown',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'pending',
        priority: 'medium',
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
      _providers[index] = Provider(
        id: _providers[index].id,
        name: _providers[index].name,
        type: _providers[index].type,
        phone: _providers[index].phone,
        address: _providers[index].address,
        latitude: _providers[index].latitude,
        longitude: _providers[index].longitude,
        distance: _providers[index].distance,
        isAvailable: isAvailable,
        rating: _providers[index].rating,
        description: _providers[index].description,
      );
    }
  }
}