import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/home_screen.dart';
import '../screens/service_selection_screen.dart';
import '../screens/provider_dashboard_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // User is not logged in
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (!snapshot.hasData) {
          return const HomeScreen();
        }

        // User is logged in, determine their role
        final user = snapshot.data!;
        return FutureBuilder<String?>(
          future: authService.getUserType(user.uid),
          builder: (context, userTypeSnapshot) {
            if (userTypeSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            if (userTypeSnapshot.hasData) {
              final userType = userTypeSnapshot.data;
              if (userType == 'provider') {
                return const ProviderDashboardScreen();
              } else {
                return const ServiceSelectionScreen();
              }
            }

            // Default to home if something goes wrong
            return const HomeScreen();
          },
        );
      },
    );
  }
}