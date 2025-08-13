class Request {
  final String id;
  final String requesterName;
  final String requesterPhone;
  final String serviceType;
  final String description;
  final double latitude;
  final double longitude;
  final String address;
  final DateTime timestamp;
  final String status;
  final String priority;

  Request({
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

  factory Request.fromJson(Map<String, dynamic> json) {
    return Request(
      id: json['id'] ?? '',
      requesterName: json['requesterName'] ?? '',
      requesterPhone: json['requesterPhone'] ?? '',
      serviceType: json['serviceType'] ?? '',
      description: json['description'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] ?? '',
      timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? '',
      priority: json['priority'] ?? '',
    );
  }

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
}