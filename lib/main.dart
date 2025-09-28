import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
// Comment out missing imports temporarily for debugging
// import 'firebase_options.dart';
// import 'screens/home_screen.dart';
// import 'screens/auth_screen.dart';
// import 'screens/service_selection_screen.dart';
// import 'screens/provider_list_screen.dart';
// import 'screens/provider_details_screen.dart';
// import 'screens/map_screen.dart';
// import 'screens/provider_dashboard_screen.dart';
// import 'screens/manage_services_screen.dart';
// import 'widgets/auth_wrapper.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  try {
    // Ensure Flutter is initialized
    WidgetsFlutterBinding.ensureInitialized();
    
    print("Flutter binding initialized");
    
    // Initialize Firebase (temporarily simplified)
    await Firebase.initializeApp();
    print("Firebase initialized");
    
    // Request location permissions on startup (make non-blocking)
    _requestLocationPermission().catchError((error) {
      print("Location permission error: $error");
      // Don't block app startup for location errors
    });
    
    print("Starting app...");
    runApp(const EmergencyResourceLocatorApp());
  } catch (e) {
    print("Error in main: $e");
    // Run a minimal app to show the error
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text("Initialization Error: $e"),
            ],
          ),
        ),
      ),
    ));
  }
}

// Helper function to handle location permissions
Future<void> _requestLocationPermission() async {
  try {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }
    
    print("Location permissions granted");
  } catch (e) {
    print("Location permission error: $e");
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

      // Use a simple home screen for debugging
      home: const DebugHomeScreen(),
      
      // Comment out routes temporarily
      // initialRoute: '/',
      // routes: {
      //   '/': (context) => const AuthWrapper(),
      //   '/home': (context) => const HomeScreen(),
      //   '/auth': (context) => const AuthScreen(),
      //   '/service-selection': (context) => const ServiceSelectionScreen(),
      //   '/provider-list': (context) => const ProviderListScreen(),
      //   '/provider-details': (context) => const ProviderDetailsScreen(),
      //   '/map': (context) => const MapScreen(),
      //   '/provider-dashboard': (context) => const ProviderDashboardScreen(),
      //   '/manage-services': (context) => const ManageServicesScreen(),
      // },
    );
  }
}

class DebugHomeScreen extends StatelessWidget {
  const DebugHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Resource Locator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text(
              'App is running successfully!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('Firebase and location services are being initialized...'),
          ],
        ),
      ),
    );
  }
}