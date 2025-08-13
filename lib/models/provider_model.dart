// Model class for service providers (hospitals, police, ambulances)
class Provider {
  final String id;
  final String name;
  final String type; // 'hospital', 'police', 'ambulance'
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  final double distance; // Distance from user in km
  final bool isAvailable;
  final int rating; // Rating out of 5
  final String description;

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
    };
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
}