import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_res_loc_new/models/RequestOffer.dart';

class EmergencyRequest {
  final String id;
  final String itemName;
  final int itemQuantity;
  final String itemUnit;
  final String requesterName;
  final String requesterPhone;
  final String status;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String locationName;
  final String masterRequestId;
  final String description;
  final List<String> declinedBy;
  final DateTime acceptedAt;
  final String confirmedProviderId;
  final List<RequestOffer> offers;
  final String? verificationCode;
  final double radius; // <--- NEW FIELD

  EmergencyRequest({
    required this.id,
    required this.itemName,
    required this.itemQuantity,
    required this.itemUnit,
    required this.requesterName,
    required this.status,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.masterRequestId,
    required this.description,
    this.declinedBy = const [],
    required String providerId,
    required String requesterId,
    required this.requesterPhone,
    required this.acceptedAt,
    required this.confirmedProviderId,
    this.offers = const [],
    this.verificationCode,
    this.radius = 5.0, // Default radius
  });

  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyRequest(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      itemQuantity: (data['itemQuantity'] as num?)?.toInt() ?? 0,
      itemUnit: data['itemUnit'] ?? '',
      requesterName: data['requesterName'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      locationName: data['locationName'] ?? '',
      masterRequestId: data['masterRequestId'] ?? '',
      description: data['description'] ?? '',
      declinedBy: List<String>.from(data['declinedBy'] ?? []),
      providerId: '',
      requesterPhone: data['requesterPhone'] ?? '',
      requesterId: data['requesterId'] ?? '',
      acceptedAt: (data['timestamp'] as Timestamp).toDate(),
      confirmedProviderId: '',
      offers: (data['offers'] as List? ?? [])
              .map((o) => RequestOffer.fromMap(o as Map<String, dynamic>))
              .toList(),
      verificationCode: data['verificationCode'],
      radius: (data['radius'] as num?)?.toDouble() ?? 5.0, // <--- READ IT HERE
    );
  }

  bool hasProviderOffered(String providerId) {
    return offers.any((offer) => offer.providerId == providerId);
  }
}