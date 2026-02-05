import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart'; // Add intl to your pubspec.yaml for date formatting

class RequesterHistoryScreen extends StatelessWidget {
  const RequesterHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Request History'),
        backgroundColor: Colors.redAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Querying for THIS user's requests, sorted by time
        stream: firestore
            .collection('emergency_requests')
            .where('requesterId', isEqualTo: user?.uid)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Something went wrong: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final request = EmergencyRequest.fromFirestore(docs[index]);
              return _buildHistoryCard(context, request);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, EmergencyRequest request) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: _getStatusIcon(request.status),
        title: Text(
          "${request.itemQuantity}x ${request.itemName}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a').format(request.timestamp),
          style: const TextStyle(fontSize: 12),
        ),
        trailing: _buildStatusChip(request.status),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _detailRow(Icons.info_outline, "Description", request.description),
                _detailRow(Icons.location_on_outlined, "Coordinates",
                    "${request.locationName}, ${request.latitude}, ${request.longitude}"),
                if (request.status == 'confirmed')
                  _detailRow(Icons.check_circle, "Result", "Help confirmed by a provider."),
                if (request.status == 'expired_or_declined')
                  _detailRow(Icons.timer_off, "Note", "Request expired or was manually closed."),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "$label: ${value.isEmpty ? 'N/A' : value}",
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'confirmed': color = Colors.green; break;
      case 'provider_accepted': color = Colors.blue; break;
      case 'pending': color = Colors.orange; break;
      default: color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase().replaceAll('_', ' '),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'confirmed': return const Icon(Icons.verified, color: Colors.green);
      case 'pending': return const Icon(Icons.broadcast_on_home, color: Colors.orange);
      default: return const Icon(Icons.history, color: Colors.grey);
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_toggle_off, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("No history found", style: TextStyle(color: Colors.grey, fontSize: 18)),
        ],
      ),
    );
  }
}