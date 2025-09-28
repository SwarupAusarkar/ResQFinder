import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class ManageServicesScreen extends StatefulWidget {
  const ManageServicesScreen({super.key});

  @override
  State<ManageServicesScreen> createState() => _ManageServicesScreenState();
}

class _ManageServicesScreenState extends State<ManageServicesScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Master list of services. In a real app, this might also come from Firestore.
  final List<String> _masterServiceList = [
    'Emergency Room', 'ICU Beds', 'Ventilators', 'X-Ray', 'CT Scan',
    'MRI', 'Blood Bank', 'Pharmacy', 'Surgery', 'Trauma Care',
    'Pediatrics', 'Cardiology', 'Neurology', 'Oncology',
    'Advanced Life Support', 'Basic Life Support', 'Crime Investigation',
    'Traffic Control', 'Public Safety'
  ];

  List<String> _selectedServices = [];
  bool _isLoading = false;

  Future<void> _saveServices() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    final user = _authService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in!')),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'services': _selectedServices,
        'profileComplete': true, // Mark profile as complete
      });

      if (mounted) {
        // Navigate to the dashboard after setup is complete.
        // The AuthWrapper will now let them through.
        Navigator.of(context).pushReplacementNamed('/provider-dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save services: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Your Services'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // No back button
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Text(
                  'Welcome, Provider!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please select all the services and equipment you provide. This will help users find you when they need you most.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: _masterServiceList.map((service) {
                return CheckboxListTile(
                  title: Text(service),
                  value: _selectedServices.contains(service),
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedServices.add(service);
                      } else {
                        _selectedServices.remove(service);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _saveServices,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Finish Setup & Go to Dashboard'),
            ),
          ),
        ],
      ),
    );
  }
}