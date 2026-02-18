import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart'; // Import AuthService
import '../screens/home_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/service_selection_screen.dart';
import '../screens/provider_dashboard_screen.dart';
import '../screens/manage_services_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        
        // 1. Show loading while checking Firebase Auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        // 2. If User is Logged In -> Fetch Role Data
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot?>(
            // USE THE SERVICE TO CHECK BOTH COLLECTIONS
            future: authService.getUserData(snapshot.data!.uid),
            builder: (context, userDocSnapshot) {
              
              if (userDocSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }

              if (userDocSnapshot.hasError) {
                return _buildErrorScreen("Error loading profile: ${userDocSnapshot.error}");
              }

              // Handle case where user exists in Auth but not in Firestore (e.g. deleted manually)
              if (!userDocSnapshot.hasData || userDocSnapshot.data == null || !userDocSnapshot.data!.exists) {
                return _buildErrorScreen("User profile not found in database.");
              }

              final userData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
              
              if (userData == null) {
                return _buildErrorScreen("User data is corrupted.");
              }

              final userType = userData['userType'] as String?;

              // 3. Routing Logic
              if (userType == 'provider') {
                // Providers: Check if they have finished setup
                // (Note: In our new flow, we set profileComplete = true on signup, 
                // but checking here makes it robust for future edits)
                final profileComplete = userData['profileComplete'] as bool? ?? false;
                
                if (!profileComplete) {
                  return const ManageServicesScreen();
                }
                return ProviderDashboardScreen();
              } else {
                // Requesters: Go to Service Selection
                return const ServiceSelectionScreen();
              }
            },
          );
        }
        
        // 3. If User is Not Logged In -> Show Home (Landing)
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