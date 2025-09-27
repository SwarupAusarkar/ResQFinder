import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart'; 
import 'widgets/auth_wrapper.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/service_selection_screen.dart';
import 'screens/provider_list_screen.dart';
import 'screens/provider_details_screen.dart';
import 'screens/map_screen.dart';
import 'screens/provider_dashboard_screen.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Request location permissions on app start
  await Geolocator.requestPermission();

  runApp(const EmergencyResourceLocatorApp());
}

class EmergencyResourceLocatorApp extends StatelessWidget {
  const EmergencyResourceLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Resource Locator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          secondary: Colors.green,
          brightness: Brightness.light,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      // Use AuthWrapper as the home, which will handle routing
      home: const AuthWrapper(),
      routes: {
        // Keep other routes for navigation from within the app
        '/home': (context) => const HomeScreen(),
        '/auth': (context) => const AuthScreen(),
        '/service-selection': (context) => const ServiceSelectionScreen(),
        '/provider-list': (context) => const ProviderListScreen(),
        '/provider-details': (context) => const ProviderDetailsScreen(),
        '/map': (context) => const MapScreen(),
        '/provider-dashboard': (context) => const ProviderDashboardScreen(),
      },
    );
  }
}