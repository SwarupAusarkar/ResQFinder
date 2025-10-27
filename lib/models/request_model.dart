// lib/models/request_model.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Model class for emergency requests
class EmergencyRequest {
  final String id; // This will be the document ID from Firestore
  final String masterRequestId;
  final String requesterId;
  final String requesterName;
  final String providerId;
  final String providerName;
  final Map<String, dynamic> requestedItem;
  final String description;
  final DateTime timestamp;
  final String status;
  final String requesterPhone;
  final String serviceType;
  final String priority;
  final double latitude;
  final double longitude;
  final String address;

  EmergencyRequest({
    required this.id,
    required this.masterRequestId,
    required this.requesterId,
    required this.requesterName,
    required this.providerId,
    required this.providerName,
    required this.requestedItem,
    required this.description,
    required this.timestamp,
    required this.status,
    required this.requesterPhone,
    required this.serviceType,
    required this.priority,
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  // Create EmergencyRequest object from a Firestore document
  factory EmergencyRequest.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return EmergencyRequest(
      id: doc.id, // Use the document ID
      masterRequestId: data['masterRequestId'] ?? '',
      requesterId: data['requesterId'] ?? '',
      requesterName: data['requesterName'] ?? 'Unknown Requester',
      providerId: data['providerId'] ?? '',
      providerName: data['providerName'] ?? '',
      requestedItem: data['requestedItem'] as Map<String, dynamic>? ?? {},
      description: data['description'] ?? '',
      // Correctly handle Firestore Timestamp
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'pending',
      requesterPhone: data['requesterPhone'] ?? '',
      serviceType: data['serviceType'] ?? '',
      priority: data['priority'] ?? 'normal',
      latitude: (data['location'] as GeoPoint?)?.latitude ?? 0.0,
      longitude: (data['location'] as GeoPoint?)?.longitude ?? 0.0,
      address: data['address'] ?? '',
    );
  }
  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'] ?? '',
      masterRequestId: json['masterRequestId'] ?? '',
      requesterId: json['requesterId'] ?? '',
      requesterName: json['requesterName'] ?? '',
      providerId: json['providerId'] ?? '',
      providerName: json['providerName'] ?? '',
      requestedItem: json['requestedItem'] as Map<String, dynamic>? ?? {},
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      requesterPhone: json['requesterPhone'] ?? '',
      serviceType: json['serviceType'] ?? '',
      priority: json['priority'] ?? 'medium',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,   // Corrected from 'data' to 'json'
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0, // Corrected from 'data' to 'json'
      address: json['address'] ?? '',
    );
  }
  // Helper getters for easier access in the UI
  String get itemName => requestedItem['name'] ?? 'Unknown Item';
  int get itemQuantity => requestedItem['quantity'] ?? 0;
  String get itemUnit => requestedItem['unit'] ?? '';

  // Get status color based on status string
  Color get statusColor {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green;
      case 'declined':
      case 'cancelled_by_system':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  // Get priority color
  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }

  // Get service icon (emoji)
  String get serviceIcon {
    switch (serviceType.toLowerCase()) {
      case 'medical':
        return '🏥';
      case 'fire':
        return '🚒';
      case 'police':
        return '👮';
      case 'ambulance':
        return '🚑';
      default:
        return '🆘';
    }
  }
}