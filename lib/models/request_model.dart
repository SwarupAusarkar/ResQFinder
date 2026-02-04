import 'package:cloud_firestore/cloud_firestore.dart';

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
  final List<String> declinedBy; // NEW FIELD
  final DateTime acceptedAt;
  final String acceptedBy;

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
    required providerId,
    required String requesterId,
    required this.requesterPhone,
    required this.acceptedAt,
    required this.acceptedBy, // Default to empty list
  });
  factory EmergencyRequest.fromJson(String id, Map<String, dynamic> data) {
    return EmergencyRequest(
      id: id,
      masterRequestId: data['masterRequestId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? '',
      providerId: data['providerId'],
      description: data['description'] ?? '',
      timestamp:
          (data['timestamp'] is DateTime)
              ? data['timestamp']
              : DateTime.tryParse(data['timestamp'] ?? '') ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      requesterPhone: data['requesterPhone'] ?? '',
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      itemName: data['itemName'] ?? '',
      itemQuantity: (data['itemQuantity'] as num?)?.toInt() ?? 0,
      itemUnit: data['itemUnit'] ?? '',
      acceptedAt: DateTime.now(),
      acceptedBy: '',
      declinedBy: [],
      locationName: '',
    );
  } // Default to empty list}
  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyRequest(
      id: doc.id,
      itemName: data['itemName'] ?? '',
      itemQuantity: data['itemQuantity'] ?? 0,
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
      providerId: null,
      requesterPhone: data['requesterPhone'] ?? '',
      requesterId: '',
      acceptedAt: (data['timestamp'] as Timestamp).toDate(),
      acceptedBy: '',
    );
  } }
