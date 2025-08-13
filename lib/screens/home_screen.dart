import 'package:flutter/material.dart';

// Home screen where users choose between Requester and Provider roles
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Gradient background for visual appeal
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2), // Blue
              Color(0xFF4CAF50), // Green
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App logo and title
                const Icon(
                  Icons.local_hospital,
                  size: 80,
                  color: Colors.white,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Emergency Resource\nLocator',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Find help when you need it most',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 60),
                
                // User type selection cards
                const Text(
                  'Who are you?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Requester card
                _buildUserTypeCard(
                  context: context,
                  title: 'I Need Help',
                  subtitle: 'Find emergency services near me',
                  icon: Icons.search,
                  userType: 'requester',
                  color: Colors.white,
                ),
                
                const SizedBox(height: 16),
                
                // Provider card
                _buildUserTypeCard(
                  context: context,
                  title: 'I Provide Service',
                  subtitle: 'Respond to emergency requests',
                  icon: Icons.medical_services,
                  userType: 'provider',
                  color: Colors.white,
                ),
                
                const Spacer(),
                
                // Footer text
                const Text(
                  'Emergency services available 24/7',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build user type selection card
  Widget _buildUserTypeCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required String userType,
    required Color color,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to auth screen with user type parameter
          Navigator.pushNamed(
            context,
            '/auth',
            arguments: {'userType': userType},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: userType == 'requester' 
                      ? Colors.blue.withOpacity(0.1)
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: userType == 'requester' ? Colors.blue : Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}