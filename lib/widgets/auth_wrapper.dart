import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/home_screen.dart';
import '../screens/auth_screen.dart';
import '../screens/service_selection_screen.dart';
import '../screens/provider_dashboard_screen.dart';
import '../screens/manage_services_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print("🔍 AuthWrapper - Connection state: ${snapshot.connectionState}");
        print("🔍 AuthWrapper - Has data: ${snapshot.hasData}");
        print("🔍 AuthWrapper - User: ${snapshot.data?.email}");
        
        // Show loading indicator while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // If user is logged in, determine their role and route accordingly
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(snapshot.data!.uid)
                .get(),
            builder: (context, userDoc) {
              print("🔍 User doc - Connection state: ${userDoc.connectionState}");
              print("🔍 User doc - Has data: ${userDoc.hasData}");
              
              if (userDoc.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (userDoc.hasError) {
                print("❌ Error loading user data: ${userDoc.error}");
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, size: 64, color: Colors.red),
                        const SizedBox(height: 16),
                        Text('Error: ${userDoc.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!userDoc.hasData || !userDoc.data!.exists) {
                print("⚠️ User document doesn't exist");
                return Scaffold(
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.warning, size: 64, color: Colors.orange),
                        const SizedBox(height: 16),
                        const Text('User data not found'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                          },
                          child: const Text('Sign Out and Try Again'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final userData = userDoc.data!.data() as Map<String, dynamic>?;
              
              if (userData == null) {
                print("⚠️ User data is null");
                return const Scaffold(
                  body: Center(
                    child: Text('Error loading user data'),
                  ),
                );
              }

              final userType = userData['userType'] as String?;
              print("✓ User type: $userType");

              // Route based on user type
              if (userType == 'provider') {
                final profileComplete = userData['profileComplete'] as bool? ?? false;
                print("✓ Provider profile complete: $profileComplete");
                
                if (!profileComplete) {
                  // New provider needs to set up services
                  return const ManageServicesScreen();
                }
                // Existing provider goes to dashboard
                return ProviderDashboardScreen();
              } else {
                // Requester goes to service selection
                print("✓ Routing to ServiceSelectionScreen");
                return const ServiceSelectionScreen();
              }
            },
          );
        }
        
        // If user is not logged in, show home screen (which leads to auth)
        print("ℹ️ No user logged in, showing HomeScreen");
        return const HomeScreen();
      },
    );
  }
}