import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/service_selection_screen.dart';
import '../screens/provider_dashboard_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/manage_services_screen.dart'; // Import the new screen
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // User is NOT logged in → go to AuthScreen
        if (!snapshot.hasData) {
          return const AuthScreen();
        }

        // User is logged in → check their role and profile status
        final user = snapshot.data!;
        return FutureBuilder<DocumentSnapshot?>(
          future: authService.getUserData(user.uid),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
              final userData = userDocSnapshot.data!.data() as Map<String, dynamic>;
              final userType = userData['userType'];
              final profileComplete = userData['profileComplete'] ?? false;

              if (userType == 'provider') {
                if (profileComplete) {
                  // Provider with complete profile goes to dashboard
                  return const ProviderDashboardScreen();
                } else {
                  // New provider must set up services
                  return const ManageServicesScreen();
                }
              } else {
                // Requester goes to service selection
                return const ServiceSelectionScreen();
              }
            }

            // Fallback if role lookup fails (should not happen in normal flow)
            // Log them out to be safe
            authService.signOut();
            return const AuthScreen();
          },
        );
      },
    );
  }
}