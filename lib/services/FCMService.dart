import 'dart:ui' show Color;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'auth_service.dart';

class FCMService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _androidChannelId = 'emergency_requests_channel';
  static const String _androidChannelName = 'Emergency Requests';
  static const String _androidChannelDescription = 'Notifications for new emergency requests';

  static Future<void> initialize() async {
    print('🔔 Initializing FCM Service...');

    // 1. Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ Notification permission denied');
      return;
    }

    // 2. Initialize local notifications (Only for Mobile)
    if (!kIsWeb) {
      await _initializeLocalNotifications();
    }

    // 3. Get FCM token
    String? token;
    if (kIsWeb) {
      // Replace with your VAPID key from Firebase Console -> Project Settings -> Cloud Messaging
      token = await _messaging.getToken(vapidKey: "YOUR_PUBLIC_VAPID_KEY_HERE");
    } else {
      token = await _messaging.getToken();
    }

    if (token != null) {
      print('📱 FCM Token: $token');
      await _saveTokenToDatabase(token);
    }

    // 4. Set up listeners
    _messaging.onTokenRefresh.listen(_saveTokenToDatabase);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    _handleInitialMessage();

    print('✅ FCM Service initialized successfully');
  }

  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // ✅ FIX: Using the correct named parameter 'onDidReceiveNotificationResponse'
    await _localNotifications.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        _handleLocalNotificationTap(response);
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _androidChannelId,
      _androidChannelName,
      description: _androidChannelDescription,
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
   await _localNotifications.show(// 3rd positional: body
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDescription,
            importance: Importance.max,
            priority: Priority.high,
            color: const Color(0xFFFF0000), // Emergency Red
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['requestId'], id: message.data['requestId'],
      );
    }
  }

  // --- Utility & Database Logic ---

  static Future<void> _saveTokenToDatabase(String token) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'fcmToken': token,
        'platform': kIsWeb ? 'web' : 'mobile',
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('❌ Error saving token: $e');
    }
  }

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!kIsWeb) await _showLocalNotification(message);
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    if (message.data.containsKey('requestId')) {
      print('🚀 Navigating to Request ID: ${message.data['requestId']}');
    }
  }

  static void _handleLocalNotificationTap(NotificationResponse response) {
    if (response.payload != null) {
      print('🚀 Local payload tapped: ${response.payload}');
    }
  }

  static Future<void> _handleInitialMessage() async {
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) await _handleNotificationTap(initialMessage);
  }

  static Future<void> subscribeToTopic(String topic) async => await _messaging.subscribeToTopic(topic);
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Required for Android background execution
  print("Handling background message: ${message.messageId}");
}