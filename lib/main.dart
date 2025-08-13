import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/service_selection_screen.dart';
import 'screens/provider_list_screen.dart';
import 'screens/map_screen.dart';
import 'screens/provider_dashboard_screen.dart';
import 'screens/provider_details_screen.dart';
import 'models/provider_model.dart';

void main() {
  runApp(const EmergencyResourceLocatorApp());
}

class EmergencyResourceLocatorApp extends StatelessWidget {
  const EmergencyResourceLocatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Emergency Resource Locator',
      debugShowCheckedModeBanner: false,

      // Material 3 theme
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

      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/auth':
            return MaterialPageRoute(builder: (_) => const AuthScreen());
          case '/service-selection':
            return MaterialPageRoute(
              builder: (_) => const ServiceSelectionScreen(),
            );
          case '/provider-list':
            final args = settings.arguments as String; // serviceType
            return MaterialPageRoute(
              builder: (_) => ProvidersListScreen(serviceType: args),
            );
            case '/provider-details':
              final provider = settings.arguments as Provider;
              return MaterialPageRoute(
                builder: (_) => ProviderDetailsScreen(provider: provider),
              );

          case '/map':
            return MaterialPageRoute(builder: (_) => const MapScreen());
          case '/provider-dashboard':
            return MaterialPageRoute(
              builder: (_) => const ProviderDashboardScreen(),
            );
          default:
            return MaterialPageRoute(
              builder: (_) => const Scaffold(
                body: Center(child: Text('404 - Page not found')),
              ),
            );
        }
      },
    );
  }
}
