import 'package:cloud_firestore/cloud_firestore.dart';

class ExpirationLogicService {
  static const int expiryMinutes = 20;

  static Future<void> checkAndExpireRequest(DocumentSnapshot doc) async {
    final data = doc.data() as Map<String, dynamic>?;

    if (data == null) return;
    if (data['status'] != 'pending') return;

    final Timestamp? createdAt = data['timestamp'];
    if (createdAt == null) return;

    final DateTime createdTime = createdAt.toDate();
    final DateTime expiryTime =
    createdTime.add(const Duration(minutes: expiryMinutes));

    if (DateTime.now().isAfter(expiryTime)) {
      await doc.reference.update({
        'status': 'expired',
        'expiredAt': FieldValue.serverTimestamp(),
      });
    }
  }

  static Duration getRemainingTime(Timestamp createdAt) {
    final createdTime = createdAt.toDate();
    final expiryTime =
    createdTime.add(const Duration(minutes: expiryMinutes));

    return expiryTime.difference(DateTime.now());
  }
}