import 'package:emergency_res_loc_new/screens/provider_dashboard_screen.dart';
import 'package:emergency_res_loc_new/screens/provider_main_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; 
import '../screens/home_screen.dart';
import '../screens/service_selection_screen.dart';
import '../screens/manage_services_screen.dart';
import '../screens/admin_dashboard_screen.dart';
import '../MainWrapper.dart'; // NEW: Import MainWrapper

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          final currentUser = snapshot.data!;

          // ADMIN BYPASS
          if (currentUser.email == 'admin@resqfinder.com') {
            return const AdminDashboardScreen();
          }

          return FutureBuilder<DocumentSnapshot?>(
            future: authService.getUserData(currentUser.uid),
            builder: (context, userDocSnapshot) {
              
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userDocSnapshot.hasError) {
                return _buildErrorScreen("Error loading profile: ${userDocSnapshot.error}");
              }

              if (!userDocSnapshot.hasData || userDocSnapshot.data == null || !userDocSnapshot.data!.exists) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              final userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
              
              if (userData == null) {
                return _buildErrorScreen("User data is corrupted.");
              }

              final userType = userData['userType'] as String?;

              if (userType == 'provider') {
                final profileComplete = userData['profileComplete'] as bool? ?? false;
                
                if (!profileComplete) {
                  return const ManageServicesScreen();
                }
                // FIX: Route directly to the unified Dashboard! No more double nav bars.
                return const ProviderDashboardScreen(initialTab: 'new');
              } else {
                return const ServiceSelectionScreen();
              }
            },
          );
        }
        
        // If not logged in, go to Home Screen
        return const HomeScreen();
      },
    );
  }

  Widget _buildErrorScreen(String message) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
                child: const Text('Sign Out & Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}