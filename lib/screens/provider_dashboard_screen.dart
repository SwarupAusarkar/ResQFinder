import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../models/request_model.dart';
import 'manage_inventory_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});
  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final AuthService _authService = AuthService();
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Position? pos = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _currentPosition = pos);
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Live Emergency Feed"),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ManageInventoryScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _authService.signOut(),
          ),
        ],
      ),
      body: _currentPosition == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Locating you..."),
                ],
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('emergency_requests')
                  .where('status', isEqualTo: 'pending')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final allRequests = snapshot.data!.docs.map((doc) {
                  return EmergencyRequest.fromFirestore(doc);
                }).toList();

                final nearbyRequests = allRequests.where((req) {
                  if (req.declinedBy.contains(user?.uid)) return false;

                  double distanceInKm = Geolocator.distanceBetween(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                    req.latitude,
                    req.longitude,
                  ) / 1000;

                  return distanceInKm <= req.radius;
                }).toList();

                if (nearbyRequests.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: nearbyRequests.length,
                  itemBuilder: (context, index) {
                    final req = nearbyRequests[index];
                    return _buildRequestCard(req);
                  },
                );
              },
            ),
    );
  }

  Widget _buildRequestCard(EmergencyRequest req) {
    double distanceKm = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      req.latitude,
      req.longitude,
    ) / 1000;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "${req.itemQuantity} ${req.itemUnit} of ${req.itemName}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
                  ),
                ),
                Text("${distanceKm.toStringAsFixed(1)} km", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Patient: ${req.requesterName}"),
                const SizedBox(height: 4),
                Text("Note: ${req.description}", style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: const Text("Ignore"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        onPressed: () {
                          // ACCEPT LOGIC will go here
                          print("Offer sent to ${req.id}");
                        },
                        child: const Text("ACCEPT & OFFER"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Scanning for nearby emergencies...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}