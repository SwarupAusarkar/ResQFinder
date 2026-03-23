import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationHelper {
  NotificationHelper._();
  static final NotificationHelper instance = NotificationHelper._();

  final FlutterLocalNotificationsPlugin _localNotifications =
  FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  Future<void> init() async {
    await _requestPermission();
    await _initLocalNotifications();
    await _saveFCMToken();
  }

  // 🔔 Request Permission
  Future<void> _requestPermission() async {
    await _messaging.requestPermission();
  }

  // 🔔 Initialize Local Notifications
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings settings =
    InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        print("Notification clicked: ${details.payload}");
      },
    );

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'emergency_channel',
      'Emergency Notifications',
      description: 'Emergency alerts and updates',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  // 🔔 Show Local Notification (FOR FOREGROUND)
  Future<void> showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails =
    AndroidNotificationDetails(
      'emergency_channel',
      'Emergency Notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformDetails =
    NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      platformDetails,
      payload: jsonEncode(message.data),
    );
  }

  // 🔔 Save FCM Token (IMPORTANT)
  Future<void> _saveFCMToken() async {
    String? token = await _messaging.getToken();
    print("FCM Token: $token");

    _messaging.onTokenRefresh.listen((newToken) {
      print("FCM Token Refreshed: $newToken");
    });
  }
}