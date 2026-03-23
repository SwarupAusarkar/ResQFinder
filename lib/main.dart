// import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
// import 'package:emergency_res_loc_new/screens/provider_registration_screen.dart';
// import 'package:emergency_res_loc_new/screens/requester_registeration.dart'; // Ensure spelling matches your file
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'firebase_options.dart';
// import 'screens/home_screen.dart';
// import 'screens/auth_screen.dart';
// import 'screens/service_selection_screen.dart';
// import 'screens/provider_list_screen.dart';
// import 'screens/admin_dashboard_screen.dart';
// import 'screens/provider_details_screen.dart';
// import 'screens/map_screen.dart';
// import 'screens/provider_dashboard_screen.dart';
// import 'screens/manage_inventory_screen.dart';
// import 'screens/manage_services_screen.dart';
// import 'widgets/auth_wrapper.dart';
// import 'package:geolocator/geolocator.dart';
// import 'screens/send_request_screen.dart';
// import 'services/NotificationHelper.dart';
//
// final GlobalKey<NavigatorState> navigatorKey =
// GlobalKey<NavigatorState>();
// void main() async {
//   try {
//     WidgetsFlutterBinding.ensureInitialized();
//     print("✓ Flutter binding initialized");
//
//     await Firebase.initializeApp(
//       options: DefaultFirebaseOptions.currentPlatform,
//     );
//     await NotificationHelper.instance.init();
//     print("✓ Firebase initialized");
//
//     // Request location permissions on startup (non-blocking)
//     _requestLocationPermission().catchError((error) {
//       print("⚠️ Location permission error: $error");
//     });
//
//     print("✓ Starting app...");
//     runApp(const EmergencyResourceLocatorApp());
//   } catch (e, stackTrace) {
//     print("❌ Error in main: $e");
//     print("Stack trace: $stackTrace");
//
//     runApp(
//       MaterialApp(
//         navigatorKey: navigatorKey,
//         home: Scaffold(
//           body: Center(
//             child: Padding(
//               padding: const EdgeInsets.all(24.0),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.error_outline, size: 64, color: Colors.red),
//                   const SizedBox(height: 16),
//                   const Text(
//                     "Initialization Error",
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text("$e", textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
//                   const SizedBox(height: 24),
//                   const Text("Please restart the app", style: TextStyle(fontSize: 14)),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// Future<void> _requestLocationPermission() async {
//   try {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       print('⚠️ Location services are disabled.');
//       return;
//     }
//
//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         print('⚠️ Location permissions are denied');
//         return;
//       }
//     }
//
//     if (permission == LocationPermission.deniedForever) {
//       print('⚠️ Location permissions are permanently denied');
//       return;
//     }
//
//     print("✓ Location permissions granted");
//   } catch (e) {
//     print("⚠️ Location permission error: $e");
//   }
// }
//
// class EmergencyResourceLocatorApp extends StatelessWidget {
//   const EmergencyResourceLocatorApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Emergency Resource Locator',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: const Color(0xFF00897B), // Updated to your brand Teal
//           secondary: Colors.green,
//           brightness: Brightness.light,
//         ),
//       ),
//       initialRoute: '/',
//       routes: {
//         '/': (context) => const AuthWrapper(),
//         '/home': (context) => const HomeScreen(),
//         '/auth': (context) => const AuthScreen(),
//         '/provider-registration': (context) => const ProviderRegistrationScreen(),
//         '/service-selection': (context) => const ServiceSelectionScreen(),
//         '/provider-list': (context) => const ProviderListScreen(),
//         '/admin-dashboard': (context) => const AdminDashboardScreen(),
//         '/provider-details': (context) => const ProviderDetailsScreen(),
//         '/map': (context) => const MapScreen(),
//         '/citizen-registration': (context) => const CitizenRegisterScreen(),
//         '/provider-dashboard': (context) => const ProviderDashboardScreen(initialTab: '',),
//         '/manage-services': (context) => const ManageServicesScreen(),
//         '/manage-inventory': (context) => const ManageInventoryScreen(),
//         '/send-request': (context) => SendRequestScreen(
//           inventoryItem: InventoryItem(
//             name: '',
//             quantity: 0,
//             unit: '',
//             lastUpdated: DateTime.now(),
//           ),
//         ),
//       },
//     );
//   } }
import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
import 'package:emergency_res_loc_new/screens/provider_registration_screen.dart';
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

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();


/// 🔥 Background Handler (REQUIRED)
Future<void> _firebaseMessagingBackgroundHandler(
    RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔙 Background message received: ${message.data}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.onBackgroundMessage(
      _firebaseMessagingBackgroundHandler);

  await NotificationHelper.instance.init();

  _requestLocationPermission();

  runApp(const EmergencyResourceLocatorApp());
}

Future<void> _requestLocationPermission() async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  LocationPermission permission =
  await Geolocator.checkPermission();

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
      navigatorKey.currentState?.pushNamed(
        '/provider-dashboard',
      );
    }

    if (type == "offer_received") {
      navigatorKey.currentState?.pushNamed(
        '/provider-list',
      );
    }

    if (type == "offer_approved") {
      navigatorKey.currentState?.pushNamed(
        '/provider-dashboard',
      );
    }

    if (type == "inventory_reminder") {
      navigatorKey.currentState?.pushNamed(
        '/manage-inventory',
      );
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
        '/provider-registration': (context) =>
        const ProviderRegistrationScreen(),
        '/service-selection': (context) =>
        const ServiceSelectionScreen(),
        '/provider-list': (context) =>
        const ProviderListScreen(),
        '/admin-dashboard': (context) =>
        const AdminDashboardScreen(),
        '/provider-details': (context) =>
        const ProviderDetailsScreen(),
        '/map': (context) => const MapScreen(),
        '/citizen-registration': (context) =>
        const CitizenRegisterScreen(),
        '/provider-dashboard': (context) =>
        const ProviderDashboardScreen(initialTab: ''),
        '/manage-services': (context) =>
        const ManageServicesScreen(),
        '/manage-inventory': (context) =>
        const ManageInventoryScreen(),
        '/send-request': (context) => SendRequestScreen(
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