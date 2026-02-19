// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
//
// class NotificationService {
//   final FirebaseMessaging _fcm = FirebaseMessaging.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   // Local notification for foreground display
//   final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
//
//   Future<void> initialize() async {
//     // 1. Request Permissions
//     NotificationSettings settings = await _fcm.requestPermission(
//       alert: true, badge: true, sound: true,
//     );
//
//     if (settings.authorizationStatus == AuthorizationStatus.authorized) {
//       // 2. Get and Save Token
//       String? token = await _fcm.getToken();
//       _saveToken(token);
//
//       // 3. Handle Foreground Messages
//       FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//         _showLocalNotification(message);
//       });
//     }
//   }
//
//   Future<void> _saveToken(String? token) async {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user != null && token != null) {
//       await _db.collection('users').doc(user.uid).set({
//         'fcmToken': token,
//         'lastUpdated': FieldValue.serverTimestamp(),
//       }, SetOptions(merge: true));
//     }
//   }
//
//   void _showLocalNotification(RemoteMessage message) {
//     const androidDetails = AndroidNotificationDetails(
//       'emergency_channel', 'Emergency Alerts',
//       importance: Importance.max,
//       priority: Priority.high,
//       playSound: true,
//       fullScreenIntent: true, // Crucial for emergency visibility
//     );
//
//     _localNotifications.show(
//       id: message.hashCode, // This is the 'id' (must be an int)
//       title:message.notification?.title, // 'title'
//       body:message.notification?.body,  // 'body'
//       notificationDetails: NotificationDetails(
//         android: AndroidNotificationDetails(
//           'emergency_channel_id',
//           'Emergency Notifications',
//           importance: Importance.max,
//           priority: Priority.high,
//         ),
//       ),
//     );
//   } }
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Initialize local notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap when app is in foreground
        if (response.payload != null) {
          // You can handle navigation here if needed
        }
      },
    );

    // 2. Request permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');

      // 3. Get and save FCM token
      String? token = await _fcm.getToken();
      print('📱 FCM Token: $token');
      await _saveToken(token);

      // 4. Listen for token refresh
      _fcm.onTokenRefresh.listen(_saveToken);

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('📩 Foreground message received: ${message.notification?.title}');
        _showLocalNotification(message);
      });
    } else {
      print('❌ Notification permission denied');
    }
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
      }
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'emergency_channel_id',
      'Emergency Alerts',
      channelDescription: 'Critical emergency notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.alarm,
      icon: '@mipmap/ic_launcher',
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      id:message.hashCode,
      title:message.notification?.title ?? 'Emergency Alert',
      body:message.notification?.body ?? 'New emergency request nearby',
      notificationDetails: notificationDetails,
      payload: message.data['requestId'],
    );
  }

  // Call this when provider toggles availability
  Future<void> updateAvailability(bool isAvailable) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).update({
        'isAvailable': isAvailable,
      });
    }
  }
}