import 'package:emergency_res_loc_new/screens/request_history_screen.dart';
import 'package:emergency_res_loc_new/screens/requester_profile_screen.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

// Screen where requesters choose the type of emergency service they need
class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      print("👋 Signing out from ServiceSelectionScreen...");
      await AuthService().signOut();
      
      if (context.mounted) {
        print("→ Navigating to home screen");
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
          (route) => false,
        );
      }
    } catch (e) {
      print("❌ Sign out error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Emergency Service'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RequesterProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Request history',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const RequesterHistoryScreen()),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              const Text(
                'What type of emergency\nservice do you need?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select the appropriate service and we\'ll find the nearest available providers in Mumbai.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 40),

              // Service type cards
              Column(
                children: [
                  _buildServiceCard(
                    context: context,
                    title: 'Hospital',
                    subtitle: 'Medical emergencies & treatment',
                    icon: '🏥',
                    serviceType: 'hospital',
                    color: Colors.red,
                    description: 'Emergency rooms, doctors, medical care',
                  ),
                  const SizedBox(height: 16),

                  _buildServiceCard(
                    context: context,
                    title: 'Police',
                    subtitle: 'Security & law enforcement',
                    icon: '🚓',
                    serviceType: 'police',
                    color: Colors.blue,
                    description: 'Crime reporting, accidents, public safety',
                  ),
                  const SizedBox(height: 16),

                  _buildServiceCard(
                    context: context,
                    title: 'Ambulance',
                    subtitle: 'Emergency medical transport',
                    icon: '🚑',
                    serviceType: 'ambulance',
                    color: Colors.orange,
                    description: 'Paramedics, medical transport, life support',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Indian Emergency Numbers Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Emergency Numbers in India',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildEmergencyNumber('112', 'All Emergency Services', Icons.emergency),
                    _buildEmergencyNumber('100', 'Police', Icons.local_police),
                    _buildEmergencyNumber('101', 'Fire Department', Icons.local_fire_department),
                    _buildEmergencyNumber('108', 'Ambulance', Icons.local_hospital),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Emergency contact info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Life-threatening emergency?',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          Text(
                            'Call 112 immediately for fastest response',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _showEmergencyDialog(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text('Call 112'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build emergency number info row
  Widget _buildEmergencyNumber(String number, String service, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blue[600]),
          const SizedBox(width: 8),
          Text(
            number,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '- $service',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  // Build service selection card
  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String icon,
    required String serviceType,
    required Color color,
    required String description,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to provider list with selected service type
          Navigator.pushNamed(
            context,
            '/provider-list',
            arguments: {'serviceType': serviceType},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Service icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    icon,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Service info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Show emergency call dialog
  void _showEmergencyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Emergency Call'),
          ],
        ),
        content: const Text(
          'This is a demo app. In a real emergency, you would be connected to 112 emergency services.\n\n'
          'Indian Emergency Numbers:\n'
          '• 112 - All Emergency Services\n'
          '• 100 - Police\n'
          '• 101 - Fire Department\n'
          '• 108 - Ambulance\n\n'
          'For life-threatening emergencies, always call 112 directly.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}