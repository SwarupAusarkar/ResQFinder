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

  // Fallback providers with Mumbai data
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
      ),
      Provider(
        id: 'p001',
        name: 'Bandra Police Station',
        type: 'police',
        phone: '+91-22-2640-5020',
        address: 'Turner Road, Bandra West, Mumbai, Maharashtra 400050',
        latitude: 19.0544,
        longitude: 72.8266,
        distance: 1.2,
        isAvailable: true,
        rating: 4,
        description: 'Main police station serving Bandra area with 24/7 response.',
      ),
      Provider(
        id: 'a001',
        name: '108 Emergency Ambulance Service',
        type: 'ambulance',
        phone: '108',
        address: 'MCGM Emergency Services, Dadar, Mumbai, Maharashtra 400014',
        latitude: 19.0178,
        longitude: 72.8478,
        distance: 1.5,
        isAvailable: true,
        rating: 5,
        description: 'Government emergency ambulance service providing free medical transport.',
      ),
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
      EmergencyRequest(
        id: 'r002',
        requesterName: 'Priya Sharma',
        requesterPhone: '+91-87654-32109',
        serviceType: 'police',
        description: 'Road accident near Bandra-Kurla Complex, multiple vehicles involved',
        latitude: 19.0728,
        longitude: 72.8826,
        address: 'Bandra Kurla Complex, Bandra East, Mumbai, Maharashtra 400051',
        timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
        status: 'pending',
        priority: 'high',
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