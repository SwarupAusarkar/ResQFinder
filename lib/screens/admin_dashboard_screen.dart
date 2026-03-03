// lib/screens/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'admin_verification_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout Admin",
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) Navigator.pushReplacementNamed(context, '/');
            },
          )
        ],
      ),
      // Listen for ONLY 'pending' providers
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('providers')
            .where('verificationStatus', isEqualTo: 'pending')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.business, color: Colors.orange, size: 36),
                  title: Text(data['name'] ?? 'Unknown Provider', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['providerType']?.toString().toUpperCase() ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Open the detailed verification view
                    Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AdminVerificationScreen(providerId: doc.id, providerData: data),
                    ));
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_user, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text("All caught up!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text("No pending providers to verify.", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}