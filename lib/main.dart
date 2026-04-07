
import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
import 'package:emergency_res_loc_new/screens/InventoryManagementScreen.dart';
import 'package:emergency_res_loc_new/screens/ProviderHistoryPage.dart';
import 'package:emergency_res_loc_new/screens/ProviderMapScreen.dart';
import 'package:emergency_res_loc_new/screens/myOffersPage.dart';
import 'package:emergency_res_loc_new/screens/provider_main_screen.dart';
import 'package:emergency_res_loc_new/screens/provider_profile_edit_screen.dart';
import 'package:emergency_res_loc_new/screens/provider_registration_screen.dart';
import 'package:emergency_res_loc_new/screens/request_history_screen.dart';
import 'package:emergency_res_loc_new/screens/requester_profile_screen.dart';
import 'package:emergency_res_loc_new/screens/requester_registeration.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/service_selection_screen.dart';
import 'screens/provider_list_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/provider_details_screen.dart';
import 'screens/map_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/manage_inventory_screen.dart';
import 'screens/manage_services_screen.dart';
import 'widgets/auth_wrapper.dart';
import 'package:geolocator/geolocator.dart';
import 'screens/send_request_screen.dart';
import 'services/NotificationHelper.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// 🔥 Background Handler (REQUIRED)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔙 Background message received: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await NotificationHelper.instance.init();

  _requestLocationPermission();

  runApp(const EmergencyResourceLocatorApp());
}

Future<void> _requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  LocationPermission permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
}

class EmergencyResourceLocatorApp extends StatefulWidget {
  const EmergencyResourceLocatorApp({super.key});

  @override
  State<EmergencyResourceLocatorApp> createState() =>
      _EmergencyResourceLocatorAppState();
}

class _EmergencyResourceLocatorAppState
    extends State<EmergencyResourceLocatorApp> {
  @override
  void initState() {
    super.initState();
    _setupInteractedMessage();
    _setupForegroundListener();
  }

  /// 🔥 When app is opened from terminated state
  Future<void> _setupInteractedMessage() async {
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    /// When app opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleMessage(message);
    });
  }

  /// 🔥 Foreground Notification Listener
  void _setupForegroundListener() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📲 Foreground message: ${message.data}");
      NotificationHelper.instance.showLocalNotification(message);
    });
  }

  /// 🔥 Handle Routing Based On Data
  void _handleMessage(RemoteMessage message) {
    final type = message.data['type'];
    final requestId = message.data['requestId'];

    if (type == "new_request") {
      navigatorKey.currentState?.pushNamed('/provider-dashboard');
    }

    if (type == "offer_received") {
      navigatorKey.currentState?.pushNamed('/provider-list');
    }

    if (type == "offer_approved") {
      navigatorKey.currentState?.pushNamed('/provider-dashboard');
    }

    if (type == "inventory_reminder") {
      navigatorKey.currentState?.pushNamed('/manage-inventory');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, // ✅ VERY IMPORTANT
      title: 'Emergency Resource Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00897B),
          brightness: Brightness.light,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/provider-registration':
            (context) => const ProviderRegistrationScreen(),
        '/service-selection': (context) => const ServiceSelectionScreen(),
        '/provider-list': (context) => const ProviderListScreen(),
        '/requester-history':(context)=> const RequesterHistoryScreen(),
        '/my-offers':(context)=>const MyOffersPage(),
        '/provider-history':(context)=> const HistoryPage(),
        '/requester-profile':(context)=> const RequesterProfileScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/provider-main': (context) => const ProviderMainScreen(),
        '/provider-profile':(context)=> const ProviderProfileEditScreen(),
        '/provider-details': (context) => const ProviderDetailsScreen(),
        '/map': (context) => const MapScreen(),
        '/citizen-registration': (context) => const CitizenRegisterScreen(),
        '/provider-dashboard':
            (context) => const ProviderDashboardScreen(initialTab: ''),
        '/provider-registration':(context)=> const ProviderRegistrationScreen(),
        '/provider_map':(context)=> const ProviderMapScreen(),
        '/manage-services': (context) => const ManageServicesScreen(),
        '/manage-inventory': (context) => const InventoryMgmtScreen(),
        '/send-request':
            (context) => SendRequestScreen(
              inventoryItem: InventoryItem(
                name: '',
                quantity: 0,
                unit: '',
                lastUpdated: DateTime.now(),
              ),
            ),
      },
    );
  }
}
