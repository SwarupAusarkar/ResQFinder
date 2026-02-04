import 'package:cloud_firestore/cloud_firestore.dart';

class requester_model {
  final String uid;
  final String email;
  final String fullName;
  final String phone;
  final String bloodGrp;
  final String medicalNotes;
  final String alternatePhone;
  final List<EmergencyContact> emergencyContacts;
  final String location;
  requester_model({
    required this.uid,
    required this.email,
    required this.fullName,
    this.phone = '',
    this.alternatePhone = '',
    this.emergencyContacts = const [],
    required this.bloodGrp,
    required this.medicalNotes,
    required this.location,
  });

  // ✅ CORRECT FACTORY PATTERN
  factory requester_model.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return requester_model(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['name'] ?? '',
      phone: data['phone'] ?? '',
      alternatePhone: data['alternatePhone'] ?? '',
      emergencyContacts:
          (data['emergencyContacts'] as List? ?? [])
              .map((e) => EmergencyContact.fromMap(e))
              .toList(),
      bloodGrp: '',
      medicalNotes: '',
      location: '',
    );
  }
}

class EmergencyContact {
  final String name;
  final String phone;
  bool isSelected;

  EmergencyContact({
    required this.name,
    required this.phone,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() => {
    'name': name,
    'phone': phone,
    'isSelected': isSelected,
  };
  factory EmergencyContact.fromMap(Map<String, dynamic> map) =>
      EmergencyContact(
        name: map['name'],
        phone: map['phone'],
        isSelected: map['isSelected'] ?? false,
      );
}
