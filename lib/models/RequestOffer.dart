import 'package:cloud_firestore/cloud_firestore.dart';

class RequestOffer {
  final String providerId;
  final String providerName;
  final String providerPhone;
  final DateTime acceptedAt;
  final String status; // 'waiting', 'confirmed', 'rejected'

  RequestOffer({
    required this.providerId,
    required this.providerName,
    required this.providerPhone,
    required this.acceptedAt,
    this.status = 'waiting',
  });

  /// Convert to Firestore map
  Map<String, dynamic> toMap() => {
    'providerId': providerId,
    'providerName': providerName,
    'providerPhone': providerPhone,
    'acceptedAt': Timestamp.fromDate(acceptedAt),
    'status': status,
  };

  /// Create from Firestore map
  factory RequestOffer.fromMap(Map<String, dynamic> map) {
    return RequestOffer(
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      providerPhone: map['providerPhone'] ?? '',
      acceptedAt: (map['acceptedAt'] is Timestamp)
          ? (map['acceptedAt'] as Timestamp).toDate()
          : DateTime.now(),
      status: map['status'] ?? 'waiting',
    );
  }

  /// Create a copy with updated fields
  RequestOffer copyWith({
    String? providerId,
    String? providerName,
    String? providerPhone,
    DateTime? acceptedAt,
    String? status,
  }) {
    return RequestOffer(
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      status: status ?? this.status,
    );
  }
}