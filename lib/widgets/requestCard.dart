import 'package:flutter/material.dart';
import '../models/request_model.dart';
import 'package:intl/intl.dart'; // Add to pubspec.yaml for easy date formatting

class RequestCard extends StatelessWidget {
  final EmergencyRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onVerify; // For the OTP stage

  const RequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    // Logic for the 5-minute expiry warning
    final bool isWaitingForUser = request.status == 'accepted';
    final bool isConfirmed = request.status == 'confirmed';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          // Status Header Strip
          _buildStatusHeader(),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item & Requester Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        '${request.itemQuantity} ${request.itemUnit} of ${request.itemName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    _buildTimestamp(),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoRow(
                  Icons.person_outline,
                  'Requester: ${request.requesterName}',
                ),

                _buildInfoRow(
                  Icons.phone_outlined,
                  'Contact No: ${request.requesterPhone}',
                ),

                _buildInfoRow(
                  Icons.location_on,
                  'Location: ${request.locationName}',
                ),
                _buildInfoRow(Icons.lock_clock, 'Time: ${request.timestamp}'),
                if (request.description.isNotEmpty) _buildDescriptionBox(),

                const Divider(height: 32),

                // ACTION BUTTONS BASED ON STATUS
                if (request.status == 'pending') _buildPendingActions(),

                if (isWaitingForUser) _buildWaitingState(),

                if (isConfirmed) _buildVerificationState(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- UI Components ---

  Widget _buildStatusHeader() {
    Color color = _getStatusColor();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Text(
          request.status.toUpperCase().replaceAll('_', ' '),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            // <--- THIS PREVENTS RENDER OVERFLOW
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[800], fontSize: 14),
              softWrap: true, // Allows wrapping
              maxLines:
                  3, // Optional: limits the box height if address is extremely long
              overflow:
                  TextOverflow.ellipsis, // Adds '...' if it exceeds maxLines
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              request.description,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // --- State Specific UIs ---

  Widget _buildPendingActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onDecline,
            icon: const Icon(Icons.close),
            label: const Text('Decline'),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: const Icon(Icons.check),
            label: const Text('Accept'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Waiting for user to confirm... (Expires in 5m)",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationState() {
    return Column(
      children: [
        const Text(
          "Help Confirmed! Ask Requester for OTP.",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onVerify,
            icon: const Icon(Icons.vibration),
            label: const Text('ENTER VERIFICATION CODE'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  // --- Helpers ---

  Widget _buildTimestamp() {
    return Text(
      DateFormat('hh:mm a').format(request.timestamp),
      style: TextStyle(color: Colors.grey[500], fontSize: 12),
    );
  }

  Color _getStatusColor() {
    switch (request.status) {
      case 'pending':
        return Colors.orange;
      case 'provider_accepted':
        return Colors.blue;
      case 'confirmed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
