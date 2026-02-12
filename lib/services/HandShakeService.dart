import 'package:cloud_firestore/cloud_firestore.dart';

class HandshakeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Verifies the OTP entered by the provider against the DB record.
  /// Returns a Map containing 'success' (bool) and 'message' (String).
  Future<Map<String, dynamic>> verifyAndCompleteRequest({
    required String requestId,
    required String providerInputCode,
  }) async {
    try {
      // 1. Fetch the latest document to get the correct verificationCode
      DocumentSnapshot doc = await _firestore
          .collection('emergency_requests')
          .doc(requestId)
          .get();

      if (!doc.exists) {
        return {'success': false, 'message': 'Request no longer exists.'};
      }

      final data = doc.data() as Map<String, dynamic>;
      final String? serverCode = data['verificationCode'];
      final String? status = data['status'];

      // 2. Lifecycle Check: Prevent completing if already done or expired
      if (status == 'completed') {
        return {'success': false, 'message': 'Request is already completed.'};
      }

      // 3. Comparison Logic
      if (serverCode != null && serverCode == providerInputCode) {
        // 4. Update Database Status (Request LC: confirmed -> completed)
        await _firestore.collection('emergency_requests').doc(requestId).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        return {'success': true, 'message': 'Verification successful!'};
      } else {
        return {'success': false, 'message': 'Invalid code. Please try again.'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}