import 'package:flutter/material.dart';

// Model class for emergency requests
class EmergencyRequest {
  final String id;
  final String requesterName;
  final String requesterPhone;
  final String serviceType; // 'hospital', 'police', 'ambulance'
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String status; // 'pending', 'accepted', 'declined', 'completed'
  final String priority; // 'low', 'medium', 'high', 'critical'

  EmergencyRequest({
    required this.id,
    required this.requesterName,
    required this.requesterPhone,
    required this.serviceType,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.timestamp,
    required this.status,
    required this.priority,
  });

  // Create EmergencyRequest object from JSON data
  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      id: json['id'] ?? '',
      requesterName: json['requesterName'] ?? '',
      requesterPhone: json['requesterPhone'] ?? '',
      serviceType: json['serviceType'] ?? '',
      description: json['description'] ?? '',
      latitude: json['latitude']?.toDouble() ?? 0.0,
      longitude: json['longitude']?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
    );
  }

  // Convert EmergencyRequest object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requesterName': requesterName,
      'requesterPhone': requesterPhone,
      'serviceType': serviceType,
      'description': description,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'timestamp': timestamp.toIso8601String(),
      'status': status,
      'priority': priority,
    };
  }

  // Get priority color based on priority level
  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFD32F2F); // Red
      case 'high':
        return const Color(0xFFFF5722); // Deep Orange
      case 'medium':
        return const Color(0xFFFF9800); // Orange
      case 'low':
        return const Color(0xFF4CAF50); // Green
      default:
        return const Color(0xFF757575); // Gray
    }
  }

  // Get service type icon
  String get serviceIcon {
    switch (serviceType.toLowerCase()) {
      case 'hospital':
        return '🏥';
      case 'police':
        return '🚓';
      case 'ambulance':
        return '🚑';
      default:
        return '📞';
    }
  }
}