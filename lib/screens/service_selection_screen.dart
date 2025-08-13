import 'package:flutter/material.dart';

class ServiceSelectionScreen extends StatelessWidget {
  const ServiceSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final services = [
      ServiceType(
        title: 'Hospital',
        subtitle: 'Medical emergencies & treatment',
        icon: '🏥',
        serviceType: 'hospital',
        color: Colors.red,
        description: 'Emergency rooms, doctors, medical care',
      ),
      ServiceType(
        title: 'Police',
        subtitle: 'Security & law enforcement',
        icon: '🚓',
        serviceType: 'police',
        color: Colors.blue,
        description: 'Crime reporting, accidents, public safety',
      ),
      ServiceType(
        title: 'Ambulance',
        subtitle: 'Emergency medical transport',
        icon: '🚑',
        serviceType: 'ambulance',
        color: Colors.orange,
        description: 'Paramedics, medical transport, life support',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Emergency Service'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/',
              (route) => false,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              'Select the appropriate service and we\'ll find the nearest available providers.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 40),

            // Dynamically generate service cards
            Expanded(
              child: ListView.separated(
                itemCount: services.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final service = services[index];
                  return _ServiceCard(service: service);
                },
              ),
            ),

            // Emergency contact section
            _EmergencyContactSection(onCallPressed: () {
              _showEmergencyDialog(context);
            }),
          ],
        ),
      ),
    );
  }

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
          'This is a demo app. In a real emergency, you would be connected to 911 emergency services.\n\nFor life-threatening emergencies, always call 911 directly.',
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

class ServiceType {
  final String title;
  final String subtitle;
  final String icon;
  final String serviceType;
  final Color color;
  final String description;

  ServiceType({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.serviceType,
    required this.color,
    required this.description,
  });
}

class _ServiceCard extends StatelessWidget {
  final ServiceType service;

  const _ServiceCard({required this.service});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/provider-list',
            arguments: {'serviceType': service.serviceType},
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(service.icon, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: service.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.arrow_forward_ios, color: service.color, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmergencyContactSection extends StatelessWidget {
  final VoidCallback onCallPressed;

  const _EmergencyContactSection({required this.onCallPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Life-threatening emergency?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
                Text(
                  'Call 911 immediately for fastest response',
                  style: TextStyle(fontSize: 12, color: Colors.red[600]),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onCallPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Call 911'),
          ),
        ],
      ),
    );
  }
}