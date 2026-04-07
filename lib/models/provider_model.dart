// import 'package:emergency_res_loc_new/models/reviews.dart';
//
// import 'inventory_item_model.dart';
//
// class Provider {
//   final String id;
//   final String name;
//   final String type;
//   final String phone;
//   final String address;
//   final double latitude;
//   final double longitude;
//   double distance;
//   final bool isAvailable;
//   final int rating;
//   final String description;
//   final List<InventoryItem> inventory;
//   final int noOfApprovedRequests;
//   final String? fcmToken;
//   final List<Review> provider_reviews;
//   final String? hfrId;
//   final String? nmcId;
//   final bool isHFRVerified;
//   final bool isNMCVerified;
//   final String verificationType;
//   Provider({
//     required this.id,
//     required this.name,
//     required this.type,
//     required this.phone,
//     required this.address,
//     required this.latitude,
//     required this.longitude,
//     required this.distance,
//     required this.isAvailable,
//     required this.rating,
//     required this.description,
//     this.inventory = const [],
//     required this.noOfApprovedRequests,
//     this.hfrId,
//     this.nmcId,
//     this.isHFRVerified = false,
//     this.isNMCVerified = false,
//     required this.verificationType,
//     required this.fcmToken,
//     required this.provider_reviews,
//   });
//
//   factory Provider.fromJson(String id, Map<String, dynamic> json) {
//     return Provider(
//       id: id,
//       name: json['fullName'] ?? '',
//       type: json['type'] ?? '',
//       phone: json['phone'] ?? '',
//       address: json['address'] ?? '',
//       latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
//       longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
//       distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
//       isAvailable: json['isAvailable'] ?? true,
//       rating: (json['rating'] as num?)?.toInt() ?? 0,
//       description: json['description'] ?? '',
//       inventory:
//           (json['inventory'] as List<dynamic>? ?? [])
//               .map(
//                 (item) => InventoryItem.fromMap(item as Map<String, dynamic>),
//               )
//               .toList(),
//       noOfApprovedRequests: json['noOfApprovedRequests'] ?? 0,
//       fcmToken: json['fcmToken'] ?? '',
//       hfrId: json['hfrId'],
//       nmcId: json['nmcId'],
//       isHFRVerified: json['isHFRVerified'] ?? false,
//       isNMCVerified: json['isNMCVerified'] ?? false,
//       verificationType: 'json["verificationType"]',
//       provider_reviews: json['provider_reviews'] ?? [],
//     );
//   }
//
//   Map<String, dynamic> toJson() {
//     return {
//       'id': id,
//       'fullName': name,
//       'type': type,
//       'phone': phone,
//       'address': address,
//       'latitude': latitude,
//       'longitude': longitude,
//       'distance': distance,
//       'isAvailable': isAvailable,
//       'rating': rating,
//       'description': description,
//       'inventory': inventory.map((item) => item.toMap()).toList(),
//       'noOfApprovedRequests': noOfApprovedRequests,
//       'hfrId': hfrId,
//       'nmcId': nmcId,
//       'isHFRVerified': isHFRVerified,
//       'isNMCVerified': isNMCVerified,
//     };
//   }
//
//   String get iconPath {
//     switch (type.toLowerCase()) {
//       case 'hospital':
//         return '🏥';
//       case 'police':
//         return '🚓';
//       case 'ambulance':
//         return '🚑';
//       default:
//         return '📍';
//     }
//   }
//
//   Provider copyWith({
//     double? distance,
//     bool? isAvailable,
//     List<InventoryItem>? inventory,
//   }) {
//     return Provider(
//       id: this.id,
//       name: this.name,
//       type: this.type,
//       phone: this.phone,
//       address: this.address,
//       latitude: this.latitude,
//       longitude: this.longitude,
//       distance: distance ?? this.distance,
//       isAvailable: isAvailable ?? this.isAvailable,
//       rating: this.rating,
//       description: this.description,
//       inventory: inventory ?? this.inventory,
//       noOfApprovedRequests: 0,
//       verificationType: this.verificationType,
//       fcmToken: this.fcmToken,
//       provider_reviews:this.provider_reviews,
//     );
//   }
//
//   bool get isFullyVerified => isHFRVerified || isNMCVerified;
// }
import 'inventory_item_model.dart';

class Provider {
  final String id;
  final String name;
  final String type;
  final String phone;
  final String address;
  final double latitude;
  final double longitude;
  double distance;
  final bool isAvailable;
  final double rating;
  final String description;
  final List<InventoryItem> inventory;
  final int noOfApprovedRequests;
  final String? fcmToken;
  final String? hfrId;
  final String? nmcId;
  final bool isHFRVerified;
  final bool isNMCVerified;
  final String verificationType;

  // NEW: Review fields (with defaults for backwards compatibility)
  final double avgRating;
  final int reviewCount;
  final String summarizedReview;

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
    this.inventory = const [],
    required this.noOfApprovedRequests,
    this.hfrId,
    this.nmcId,
    this.isHFRVerified = false,
    this.isNMCVerified = false,
    required this.verificationType,
    this.fcmToken,
    this.avgRating = 0.0,           // Default 0
    this.reviewCount = 0,            // Default 0
    this.summarizedReview = '',      // Default empty
  });

  factory Provider.fromJson(String id, Map<String, dynamic> json) {
    return Provider(
      id: id,
      name: json['fullName'] ?? '',
      type: json['type'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distance: (json['distance'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['isAvailable'] ?? true,
      rating: (json['rating'] as double?) ?? 0,
      description: json['description'] ?? '',
      inventory: (json['inventory'] as List<dynamic>? ?? [])
          .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      noOfApprovedRequests: (json['noOfApprovedRequests'] as num?)?.toInt() ?? 0,
      fcmToken: json['fcmToken'],
      hfrId: json['hfrId'],
      nmcId: json['nmcId'],
      isHFRVerified: json['isHFRVerified'] ?? false,
      isNMCVerified: json['isNMCVerified'] ?? false,
      verificationType: json['verificationType'] ?? 'Individual',

      // NEW: Parse review fields with null safety
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      summarizedReview: json['summarizedReview'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': name,
      'type': type,
      'phone': phone,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'distance': distance,
      'isAvailable': isAvailable,
      'rating': rating,
      'description': description,
      'inventory': inventory.map((item) => item.toMap()).toList(),
      'noOfApprovedRequests': noOfApprovedRequests,
      'hfrId': hfrId,
      'nmcId': nmcId,
      'isHFRVerified': isHFRVerified,
      'isNMCVerified': isNMCVerified,
      'verificationType': verificationType,
      'fcmToken': fcmToken,

      // Include review fields
      'avgRating': avgRating,
      'reviewCount': reviewCount,
      'summarizedReview': summarizedReview,
    };
  }

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

  Provider copyWith({
    double? distance,
    bool? isAvailable,
    List<InventoryItem>? inventory,
    double? avgRating,
    int? reviewCount,
    String? summarizedReview,
  }) {
    return Provider(
      id: id,
      name: name,
      type: type,
      phone: phone,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distance: distance ?? this.distance,
      isAvailable: isAvailable ?? this.isAvailable,
      rating: rating,
      description: description,
      inventory: inventory ?? this.inventory,
      noOfApprovedRequests: noOfApprovedRequests,
      verificationType: verificationType,
      fcmToken: fcmToken,
      hfrId: hfrId,
      nmcId: nmcId,
      isHFRVerified: isHFRVerified,
      isNMCVerified: isNMCVerified,

      // NEW: Include in copyWith
      avgRating: avgRating ?? this.avgRating,
      reviewCount: reviewCount ?? this.reviewCount,
      summarizedReview: summarizedReview ?? this.summarizedReview,
    );
  }

  bool get isFullyVerified => isHFRVerified || isNMCVerified;

  // Helper to display rating
  String get displayRating => avgRating > 0 ? avgRating.toStringAsFixed(1) : 'New';
}