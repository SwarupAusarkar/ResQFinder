// // import 'package:firebase_messaging/firebase_messaging.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// //
// // class NotificationService {
// //   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
// //   final FirebaseFirestore _db = FirebaseFirestore.instance;
// //
// //   // Local notification for foreground display
// //   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
// //
// //   Future<void> initialize() async {
// //     // 1. Request Permissions
// //     NotificationSettings settings = await _fcm.requestPermission(
// //       alert: true, badge: true, sound: true,
// //     );
// //
// //     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
// //       // 2. Get and Save Token
// //       String? token = await _fcm.getToken();
// //       _saveToken(token);
// //
// //       // 3. Handle Foreground Messages
// //       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
// //         _showLocalNotification(message);
// //       });
// //     }
// //   }
// //
// //   Future<void> _saveToken(String? token) async {
// //     final user = FirebaseAuth.instance.currentUser;
// //     if (user != null && token != null) {
// //       await _db.collection('users').doc(user.uid).set({
// //         'fcmToken': token,
// //         'lastUpdated': FieldValue.serverTimestamp(),
// //       }, SetOptions(merge: true));
// //     }
// //   }
// //
// //   void _showLocalNotification(RemoteMessage message) {
// //     const androidDetails = AndroidNotificationDetails(
// //       'emergency_channel', 'Emergency Alerts',
// //       importance: Importance.max,
// //       priority: Priority.high,
// //       playSound: true,
// //       fullScreenIntent: true, // Crucial for emergency visibility
// //     );
// //
// //     _localNotifications.show(
// //       id: message.hashCode, // This is the 'id' (must be an int)
// //       title:message.notification?.title, // 'title'
// //       body:message.notification?.body,  // 'body'
// //       notificationDetails: NotificationDetails(
// //         android: AndroidNotificationDetails(
// //           'emergency_channel_id',
// //           'Emergency Notifications',
// //           importance: Importance.max,
// //           priority: Priority.high,
// //         ),
// //       ),
// //     );
// //   } }
// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
//
//   // Singleton pattern
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();
//
//   Future<void> initialize() async {
//     // 1. Initialize local notifications
//     const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
//     const initSettings = InitializationSettings(android: androidSettings);
//
//     await _localNotifications.initialize(
//        initSettings,
//       onDidReceiveNotificationResponse: (NotificationResponse response) {
//         // Handle notification tap when app is in foreground
//         if (response.payload != null) {
//           // You can handle navigation here if needed
//         }
//       },
//     );
//
//     // 2. Request permissions
//     NotificationSettings settings = await _fcm.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//       provisional: false,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       print('✅ Notification permission granted');
//
//       // 3. Get and save FCM token
//       String? token = await _fcm.getToken();
//       print('📱 FCM Token: $token');
//       await _saveToken(token);
//
//       // 4. Listen for token refresh
//       _fcm.onTokenRefresh.listen(_saveToken);
//
//       // 5. Handle foreground messages
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         print('📩 Foreground message received: ${message.notification?.title}');
//         _showLocalNotification(message);
//       });
//     } else {
//       print('❌ Notification permission denied');
//     }
//   }
//
//   Future<void> _saveToken(String? token) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null && token != null) {
//       try {
//         await _db.collection('users').doc(user.uid).update({
//           'fcmToken': token,
//           'tokenUpdatedAt': FieldValue.serverTimestamp(),
//         });
//         print('✅ FCM token saved for user: ${user.uid}');
//       } catch (e) {
//         print('❌ Error saving token: $e');
//       }
//     }
//   }
//
//   Future<void> _showLocalNotification(RemoteMessage message) async {
//     const androidDetails = AndroidNotificationDetails(
//       'emergency_channel_id',
//       'Emergency Alerts',
//       channelDescription: 'Critical emergency notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       enableVibration: true,
//       fullScreenIntent: true,
//       category: AndroidNotificationCategory.alarm,
//       icon: '@mipmap/ic_launcher',
//     );
//
//     const notificationDetails = NotificationDetails(android: androidDetails);
//
//     await _localNotifications.show(
//       message.hashCode,
//       message.notification?.title ?? 'Emergency Alert',
//      message.notification?.body ?? 'New emergency request nearby',
//        notificationDetails,
//       payload: message.data['requestId'],
//     );
//   }
//
//   // Call this when provider toggles availability
//   Future<void> updateAvailability(bool isAvailable) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null) {
//       await _db.collection('users').doc(user.uid).update({
//         'isAvailable': isAvailable,
//       });
//     }
//   }
// }


//new
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Initialize local notifications with proper channels
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap when app is in foreground
        if (response.payload != null) {
          print('📱 Notification tapped with payload: ${response.payload}');
          // Navigation will be handled by the screen's listener
        }
      },
    );

    // 2. Create notification channels for different types
    await _createNotificationChannels();

    // 3. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');

      // 4. Get and save FCM token
      String? token = await _fcm.getToken();
      print('📱 FCM Token: $token');
      await _saveToken(token);

      // 5. Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveToken);

      // 6. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground message: ${message.notification?.title}');
        print('📦 Message type: ${message.data['type']}');
        _showLocalNotification(message);
      });
    } else {
      print('❌ Notification permission denied');
    }
  }

  /// Create separate notification channels for different types
  Future<void> _createNotificationChannels() async {
    // Channel 1: Emergency Requests (highest priority)
    const emergencyChannel = AndroidNotificationChannel(
      'emergency_channel_id',
      'Emergency Alerts',
      description: 'Critical emergency requests from citizens',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Channel 2: Offers & Approvals (high priority)
    const offersChannel = AndroidNotificationChannel(
      'offers_channel_id',
      'Offers & Approvals',
      description: 'Notifications about offers and approvals',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Channel 3: Inventory Updates (medium priority)
    const inventoryChannel = AndroidNotificationChannel(
      'inventory_channel_id',
      'Inventory Updates',
      description: 'Low stock and inventory alerts',
      importance: Importance.defaultImportance,
      playSound: true,
      showBadge: true,
    );

    // Channel 4: Verification Codes (high priority)
    const verificationChannel = AndroidNotificationChannel(
      'verification_channel_id',
      'Verification Codes',
      description: 'Important verification codes',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    // Create all channels
    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(offersChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(inventoryChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(verificationChannel);

    print('✅ All notification channels created');
  }

  Future<void> _saveToken(String? token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && token != null) {
      try {
        await _db.collection('users').doc(user.uid).update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ FCM token saved for user: ${user.uid}');
      } catch (e) {
        print('❌ Error saving token: $e');
        // Try set instead of update for new users
        try {
          await _db.collection('users').doc(user.uid).set({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('✅ FCM token saved via set');
        } catch (e) {
          print('❌ Failed to save token: $e');
        }
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final type = message.data['type'] ?? 'default';

    // Get appropriate channel and styling based on notification type
    final channelId = _getChannelId(type);
    final color = _getNotificationColor(type);
    final priority = _getPriority(type);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: priority,
      priority: priority == Importance.max ? Priority.high : Priority.defaultPriority,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: type == 'emergency_request' || type == 'offer_approved',
      category: _getCategory(type),
      icon: '@mipmap/ic_launcher',
      styleInformation: BigTextStyleInformation(
        message.notification?.body ?? '',
        contentTitle: message.notification?.title,
      ),
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? _getDefaultTitle(type),
      message.notification?.body ?? _getDefaultBody(type),
      notificationDetails,
      payload: _createPayload(message.data),
    );

    print('✅ Local notification shown for type: $type');
  }

  // Helper methods for notification configuration

  String _getChannelId(String type) {
    switch (type) {
      case 'emergency_request':
        return 'emergency_channel_id';
      case 'offer_received':
      case 'offer_approved':
        return 'offers_channel_id';
      case 'inventory_update':
        return 'inventory_channel_id';
      case 'verification_code':
        return 'verification_channel_id';
      default:
        return 'emergency_channel_id';
    }
  }

  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'emergency_channel_id':
        return 'Emergency Alerts';
      case 'offers_channel_id':
        return 'Offers & Approvals';
      case 'inventory_channel_id':
        return 'Inventory Updates';
      case 'verification_channel_id':
        return 'Verification Codes';
      default:
        return 'Notifications';
    }
  }

  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'emergency_channel_id':
        return 'Critical emergency requests';
      case 'offers_channel_id':
        return 'Provider offers and approvals';
      case 'inventory_channel_id':
        return 'Low stock alerts';
      case 'verification_channel_id':
        return 'Important verification codes';
      default:
        return 'App notifications';
    }
  }

  int? _getNotificationColor(String type) {
    switch (type) {
      case 'emergency_request':
        return 0xFF00897B; // Teal
      case 'offer_received':
        return 0xFF00897B; // Teal
      case 'offer_approved':
        return 0xFF4CAF50; // Green
      case 'inventory_update':
        return 0xFFFF9800; // Orange
      case 'verification_code':
        return 0xFF2196F3; // Blue
      default:
        return 0xFF00897B; // Teal
    }
  }

  Importance _getPriority(String type) {
    switch (type) {
      case 'emergency_request':
      case 'offer_approved':
      case 'verification_code':
        return Importance.max;
      case 'offer_received':
        return Importance.high;
      case 'inventory_update':
        return Importance.defaultImportance;
      default:
        return Importance.high;
    }
  }

  AndroidNotificationCategory? _getCategory(String type) {
    switch (type) {
      case 'emergency_request':
        return AndroidNotificationCategory.alarm;
      case 'offer_received':
      case 'offer_approved':
        return AndroidNotificationCategory.message;
      case 'verification_code':
        return AndroidNotificationCategory.status;
      default:
        return AndroidNotificationCategory.message;
    }
  }

  String _getDefaultTitle(String type) {
    switch (type) {
      case 'emergency_request':
        return '🚨 Emergency Request';
      case 'offer_received':
        return '🤝 New Offer';
      case 'offer_approved':
        return '🎉 You\'re Selected!';
      case 'inventory_update':
        return '⚠️ Inventory Alert';
      case 'verification_code':
        return '🔐 Verification Code';
      default:
        return 'Notification';
    }
  }

  String _getDefaultBody(String type) {
    switch (type) {
      case 'emergency_request':
        return 'New emergency request nearby';
      case 'offer_received':
        return 'A provider wants to help';
      case 'offer_approved':
        return 'Your offer was approved!';
      case 'inventory_update':
        return 'Check your inventory';
      case 'verification_code':
        return 'Your verification code is ready';
      default:
        return 'Tap to view';
    }
  }

  String _createPayload(Map<String, dynamic> data) {
    // Combine important data into payload for navigation
    return '${data['type'] ?? 'default'}|${data['requestId'] ?? ''}|${data['redirectTo'] ?? ''}';
  }

  // Call this when provider toggles availability
  Future<void> updateAvailability(bool isAvailable) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await _db.collection('users').doc(user.uid).update({
          'isAvailable': isAvailable,
          'availabilityUpdatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ Availability updated: $isAvailable');
      } catch (e) {
        print('❌ Error updating availability: $e');
      }
    }
  }

  // Helper to check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    final settings = await _fcm.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // Helper to manually request permissions again
  Future<bool> requestPermissions() async {
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }
}