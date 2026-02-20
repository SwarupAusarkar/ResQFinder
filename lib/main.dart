import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
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

void main() async {
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();

    print("✓ Flutter binding initialized");

    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    //
    // // Initialize Notifications
    // await FCMService.initialize();
    print("✓ Firebase initialized");

    // Request location permissions on startup (non-blocking)
    _requestLocationPermission().catchError((error) {
      print("⚠️ Location permission error: $error");
    });

    print("✓ Starting app...");
    runApp(const EmergencyResourceLocatorApp());
  } catch (e, stackTrace) {
    print("❌ Error in main: $e");
    print("Stack trace: $stackTrace");

    // Run a minimal error screen
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    "Initialization Error",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "$e",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "Please restart the app",
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper function to handle location permissions
Future<void> _requestLocationPermission() async {
  try {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('⚠️ Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('⚠️ Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('⚠️ Location permissions are permanently denied');
      return;
    }
    Position position = await Geolocator.getCurrentPosition();
    print(position.latitude);
    print(position.longitude);
    print("✓ Location permissions granted");
  } catch (e) {
    print("⚠️ Location permission error: $e");
  }
}

class EmergencyResourceLocatorApp extends StatelessWidget {
  const EmergencyResourceLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Resource Locator',
      debugShowCheckedModeBanner: false,

      // App Theme
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: Colors.green,
          brightness: Brightness.light,
        ),
      ),

      // Use the AuthWrapper to handle routing
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/service-selection': (context) => const ServiceSelectionScreen(),
        '/provider-list': (context) => const ProviderListScreen(),
        '/admin-dashboard': (context) => const AdminDashboardScreen(),
        '/provider-details': (context) => const ProviderDetailsScreen(),
        '/map': (context) => const MapScreen(),
        '/provider-dashboard': (context) => ProviderDashboardScreen(),
        '/manage-services': (context) => const ManageServicesScreen(),
        '/manage-inventory': (context) => const ManageInventoryScreen(),
        '/send-request':
            (context) => SendRequestScreen(
              // provider: Provider(id: '', name: '', type: '', phone: '', address: '', latitude: 0, longitude: 0, distance: 0, isAvailable: false, rating: 0, description: ''), // Placeholder
              inventoryItem: InventoryItem(
                name: '',
                quantity: 0,
                unit: '',
                lastUpdated: DateTime.now(),
              ), // Placeholder
            ),
      },
    );
  }
}
