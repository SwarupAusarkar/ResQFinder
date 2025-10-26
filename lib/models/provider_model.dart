// lib/models/provider_model.dart

import 'inventory_item_model.dart'; // Import the new model

// Updated Model class for service providers with services array
class Provider {
  final String id;
  final String name;
  final String type; // 'hospital', 'police', 'ambulance'
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  double distance; // Made non-final to allow live distance calculation
  final bool isAvailable;
  final int rating; // Rating out of 5
  final String description;
  final List<InventoryItem> inventory; // ** MODIFIED: from List<String> to List<InventoryItem> **

  Provider({
    required this.id,
    required this.name,
    required this.type,
    required this.phone,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.isAvailable,
    required this.rating,
    required this.description,
    this.inventory = const [], // Default to empty list
  });

  // Create Provider object from JSON data
  factory Provider.fromJson(Map<String, dynamic> json) {
    return Provider(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      distance: json['distance']?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] ?? true,
      rating: json['rating'] ?? 5,
      description: json['description'] ?? '',
      // ** MODIFIED: Parse the inventory list **
      inventory: (json['inventory'] as List<dynamic>? ?? [])
          .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }
  
  // Method to create a copy of the instance with updated distance
  Provider copyWith({
    double? distance,
    bool? isAvailable,
    List<InventoryItem>? inventory,
  }) {
    return Provider(
      id: this.id,
      name: this.name,
      type: this.type,
      phone: this.phone,
      address: this.address,
      latitude: this.latitude,
      longitude: this.longitude,
      distance: distance ?? this.distance,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: this.rating,
      description: this.description,
      inventory: inventory ?? this.inventory,
    );
  }

  // Convert Provider object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'isAvailable': isAvailable,
      'rating': rating,
      'description': description,
      'inventory': inventory.map((item) => item.toMap()).toList(), // ** MODIFIED **
    };
  }

  // Check if provider offers a specific service
  bool offersService(String service) {
    return inventory.any((item) => item.name.toLowerCase().contains(service.toLowerCase()));
  }

  // Get services as a formatted string
  String get servicesDisplay {
    if (inventory.isEmpty) return 'No services listed';
    final itemNames = inventory.map((item) => item.name).toList();
    if (itemNames.length <= 3) return itemNames.join(', ');
    return '${itemNames.take(3).join(', ')} +${itemNames.length - 3} more';
  }

  // Get icon based on provider type
  String get iconPath {
    switch (type.toLowerCase()) {
      case 'hospital':
        return '🏥';
      case 'police':
        return '🚓';
      case 'ambulance':
        return '🚑';
      default:
        return '📍';
    }
  }

  // Get primary service category for display
  String get primaryService {
    if (inventory.isEmpty) return type;
    return inventory.first.name;
  }
}