import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

class NotificationHelper {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send notification to nearby providers when a new request is created
  static Future<void> notifyNearbyProviders({
    required String requestId,
    required String itemName,
    required int itemQuantity,
    required String itemUnit,
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String requesterName,
  }) async {
    try {
      print('🔔 Finding nearby providers to notify...');

      // Calculate radius in degrees (approximate)
      final radiusDegrees = radiusKm / 111; // 1 degree ≈ 111km

      // Query providers within the radius
      final providersSnapshot = await _firestore
          .collection('users')
          .where('userType', isEqualTo: 'provider')
          .where('isAvailable', isEqualTo: true)
          .where('latitude', isGreaterThanOrEqualTo: latitude - radiusDegrees)
          .where('latitude', isLessThanOrEqualTo: latitude + radiusDegrees)
          .get();

      // Filter by longitude and distance in Dart
      final nearbyProviders = providersSnapshot.docs.where((doc) {
        final data = doc.data();
        final providerLat = (data['latitude'] as num?)?.toDouble() ?? 0.0;
        final providerLon = (data['longitude'] as num?)?.toDouble() ?? 0.0;

        // Check longitude bounds
        if (providerLon < longitude - radiusDegrees ||
            providerLon > longitude + radiusDegrees) {
          return false;
        }

        // Calculate actual distance
        final distance = Geolocator.distanceBetween(
          latitude,
          longitude,
          providerLat,
          providerLon,
        ) / 1000; // Convert to km

        return distance <= radiusKm;
      }).toList();

      print('📍 Found ${nearbyProviders.length} providers within ${radiusKm}km');

      // Create notification documents for each provider
      for (var providerDoc in nearbyProviders) {
        final providerData = providerDoc.data();
        final fcmToken = providerData['fcmToken'] as String?;

        if (fcmToken != null && fcmToken.isNotEmpty) {
          // Create notification document in Firestore
          // This will trigger Cloud Function to send FCM notification
          await _firestore.collection('notifications').add({
            'recipientId': providerDoc.id,
            'fcmToken': fcmToken,
            'requestId': requestId,
            'type': 'new_request',
            'title': '🚨 New Emergency Request',
            'body': '$requesterName needs $itemQuantity $itemUnit of $itemName',
            'data': {
              'requestId': requestId,
              'itemName': itemName,
              'itemQuantity': itemQuantity,
              'itemUnit': itemUnit,
              'distance': Geolocator.distanceBetween(
                latitude,
                longitude,
                (providerData['latitude'] as num?)?.toDouble() ?? 0.0,
                (providerData['longitude'] as num?)?.toDouble() ?? 0.0,
              ) / 1000,
            },
            'timestamp': FieldValue.serverTimestamp(),
            'sent': false, // Cloud function will set to true after sending
          });

          print('✅ Notification queued for provider: ${providerData['fullName']}');
        } else {
          print('⚠️ Provider ${providerData['fullName']} has no FCM token');
        }
      }

      print('🎉 Notifications queued for ${nearbyProviders.length} providers');
    } catch (e) {
      print('❌ Error notifying providers: $e');
    }
  }

  /// Send notification when request is accepted
  static Future<void> notifyRequesterAccepted({
    required String requesterId,
    required String providerName,
    required String itemName,
  }) async {
    try {
      final requesterDoc = await _firestore.collection('users').doc(requesterId).get();
      final requesterData = requesterDoc.data();
      final fcmToken = requesterData?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'recipientId': requesterId,
          'fcmToken': fcmToken,
          'type': 'request_accepted',
          'title': '✅ Request Accepted',
          'body': '$providerName has accepted your request for $itemName',
          'timestamp': FieldValue.serverTimestamp(),
          'sent': false,
        });
        print('✅ Acceptance notification queued for requester');
      }
    } catch (e) {
      print('❌ Error notifying requester: $e');
    }
  }

  /// Send notification when request is declined
  static Future<void> notifyRequesterDeclined({
    required String requesterId,
    required String providerName,
    required String itemName,
  }) async {
    try {
      final requesterDoc = await _firestore.collection('users').doc(requesterId).get();
      final requesterData = requesterDoc.data();
      final fcmToken = requesterData?['fcmToken'] as String?;

      if (fcmToken != null && fcmToken.isNotEmpty) {
        await _firestore.collection('notifications').add({
          'recipientId': requesterId,
          'fcmToken': fcmToken,
          'type': 'request_declined',
          'title': '❌ Request Declined',
          'body': '$providerName declined your request for $itemName',
          'timestamp': FieldValue.serverTimestamp(),
          'sent': false,
        });
        print('✅ Decline notification queued for requester');
      }
    } catch (e) {
      print('❌ Error notifying requester: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _firestore.collection('notifications').doc(notificationId).update({
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  /// Get unread notification count for user
  static Stream<int> getUnreadCountStream(String userId) {
    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Delete old notifications (older than 30 days)
  static Future<void> cleanupOldNotifications() async {
    try {
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final oldNotifications = await _firestore
          .collection('notifications')
          .where('timestamp', isLessThan: Timestamp.fromDate(thirtyDaysAgo))
          .get();

      for (var doc in oldNotifications.docs) {
        await doc.reference.delete();
      }

      print('✅ Cleaned up ${oldNotifications.docs.length} old notifications');
    } catch (e) {
      print('❌ Error cleaning up notifications: $e');
    }
  }
}