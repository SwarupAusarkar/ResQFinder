import 'package:emergency_res_loc_new/services/HandShakeService.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/RequestOffer.dart';
import '../models/request_model.dart';

class RequestCard extends StatelessWidget {
  final EmergencyRequest request;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final ValueChanged<String>? onVerify;

  const RequestCard({
    super.key,
    required this.request,
    this.onAccept,
    this.onDecline,
    this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "";

    final offers = request.offers ?? <RequestOffer>[];
    final hasOffered = offers.any((o) => o.providerId == currentUserId);
    final myOffer = hasOffered ? offers.firstWhere((o) => o.providerId == currentUserId) : null;

    final bool isWinner = (request.confirmedProviderId == currentUserId && request.status == 'confirmed') ||
        (myOffer?.status == 'confirmed' && request.status == 'confirmed');
    final bool isRejected = (myOffer?.status == 'rejected') ||
        (request.status == 'confirmed' && request.confirmedProviderId != currentUserId);
    final bool isWaiting = (myOffer?.status == 'waiting') && request.status == 'pending';
    final bool someoneElseWon = request.status == 'confirmed' && request.confirmedProviderId != currentUserId;

    final itemQuantity = request.itemQuantity ?? 0;
    final itemUnit = request.itemUnit ?? '';
    final itemName = request.itemName ?? 'Item';
    final timestamp = request.timestamp ?? DateTime.now();
    final requesterName = request.requesterName ?? 'Requester';
    final locationName = request.locationName ?? 'Unknown location';

    return Card(
      elevation: isWinner ? 6 : 2,
      margin: const EdgeInsets.only(bottom: 16, left: 12, right: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: isWinner ? BorderSide(color: Colors.green.shade300, width: 1.5) : BorderSide.none,
      ),
      child: Column(
        children: [
          _buildStatusHeader(isWinner, isRejected, isWaiting, someoneElseWon),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$itemQuantity $itemUnit of $itemName',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                    ),
                    _buildTimestamp(timestamp),
                  ],
                ),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.person_outline, 'Requester: $requesterName'),
                const SizedBox(height: 6),
                _buildInfoRow(Icons.location_on_outlined, locationName),
                if ((request.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Note: ${request.description}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade700, fontStyle: FontStyle.italic),
                  ),
                ],
                const SizedBox(height: 14),
                const Divider(height: 24),
                if (isWinner)
                  _buildWinnerState(context)
                else if (isRejected || someoneElseWon)
                  _buildClosedState()
                else if (isWaiting)
                    _buildWaitingState()
                  else
                    _buildPendingActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHeader(bool isWinner, bool isRejected, bool isWaiting, bool someoneElseWon) {
    String label = "NEW REQUEST";
    Color color = Colors.orange.shade700;
    if (isWinner) {
      label = "YOU ARE SELECTED";
      color = Colors.green.shade700;
    } else if (isRejected || someoneElseWon) {
      label = "REQUEST CLOSED";
      color = Colors.grey.shade600;
    } else if (isWaiting) {
      label = "OFFER SENT";
      color = Colors.blue.shade700;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildWinnerState(BuildContext context) {
    final TextEditingController _otpController = TextEditingController();
    // Inside your ProviderDashboardScreen state
    final HandshakeService _handshakeService = HandshakeService();

    void _handleVerification(String requestId, String inputCode) async {
      // Show a loading indicator if necessary
      final result = await _handshakeService.verifyAndCompleteRequest(
        requestId: requestId,
        providerInputCode: inputCode,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
        );
      }
    }
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.green.shade100),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.green.shade700, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "ENTER VERIFICATION CODE",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade800, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 12),
                decoration: InputDecoration(
                  counterText: "",
                  hintText: "000000",
                  hintStyle: TextStyle(color: Colors.grey.shade400, letterSpacing: 12),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onChanged: (value) {
                  if (value.length == 6) {
                    // Auto-send when 6 digits are reached
                    if (onVerify != null) onVerify!(value);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ask the citizen for the 6-digit code shown on their screen',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        ),
      ],
    );
  }

  Widget _buildWaitingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "Waiting for approval...",
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.blue.shade700),
        ),
      ),
    );
  }

  Widget _buildClosedState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          "This request is no longer available.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      ),
    );
  }

  Widget _buildPendingActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(color: Colors.red.shade100),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("Decline"),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onAccept,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: const Text("Send Offer", style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey.shade800))),
        ],
      ),
    );
  }

  Widget _buildTimestamp(DateTime ts) {
    return Text(
      DateFormat('hh:mm a').format(ts),
      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
    );
  }
}
