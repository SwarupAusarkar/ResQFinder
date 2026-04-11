import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:emergency_res_loc_new/models/RequestOffer.dart';

class EmergencyRequest {
  final String id;
  final String itemName;
  final int itemQuantity;
  final String itemUnit;
  final String requesterName;
  final String requesterPhone;
  final String requesterId;
  final String status;
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final String locationName;
  final String masterRequestId;
  final String description;
  final List<String> declinedBy;
  final DateTime? acceptedAt;
  final String? confirmedProviderId;
  final List<RequestOffer> offers;
  final String? verificationCode;
  final double radius;
  final DateTime? completedAt;   // ✅ Nullable
  final DateTime? expiredAt;     // ✅ Nullable
  final bool? isReviewed;
  EmergencyRequest({
    required this.id,
    required this.itemName,
    required this.itemQuantity,
    required this.itemUnit,
    required this.requesterName,
    required this.requesterPhone,
    required this.requesterId,
    required this.status,
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.masterRequestId,
    required this.description,
    this.declinedBy = const [],
    this.acceptedAt,
    this.confirmedProviderId,
    this.offers = const [],
    this.verificationCode,
    this.radius = 5.0,
    this.completedAt,
    this.expiredAt, this.isReviewed,
  });

  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return EmergencyRequest(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      itemQuantity: (data['itemQuantity'] as num?)?.toInt() ?? 0,
      itemUnit: data['itemUnit'] ?? '',
      requesterName: data['requesterName'] ?? '',
      requesterPhone: data['requesterPhone'] ?? '',
      requesterId: data['requesterId'] ?? '',
      status: data['status'] ?? 'pending',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: data['locationName'] ?? '',
      masterRequestId: data['masterRequestId'] ?? '',
      description: data['description'] ?? '',
      declinedBy: List<String>.from(data['declinedBy'] ?? []),
      acceptedAt: (data['acceptedAt'] as Timestamp?)?.toDate(),
      confirmedProviderId: data['confirmedProviderId'],
      offers: (data['offers'] as List? ?? [])
          .map((o) => RequestOffer.fromMap(o as Map<String, dynamic>))
          .toList(),
      verificationCode: data['verificationCode'],
      radius: (data['radius'] as num?)?.toDouble() ?? 5.0,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
      expiredAt: (data['expiredAt'] as Timestamp?)?.toDate(),
    );
  }

  bool hasProviderOffered(String providerId) {
    return offers.any((offer) => offer.providerId == providerId);
  }

  bool get isCompleted => status == 'completed';

  bool get isExpired => status == 'expired';

  bool get isActive => status == 'pending' || status == 'confirmed';
}