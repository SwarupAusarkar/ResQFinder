import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/request_model.dart';
import '../models/RequestOffer.dart';

class OfferApprovalCard extends StatelessWidget {
  final EmergencyRequest request;
  final RequestOffer offer;
  final Function(RequestOffer, bool) onAction;

  const OfferApprovalCard({
    super.key,
    required this.request,
    required this.offer,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isWinner = (request.confirmedProviderId == offer.providerId &&
        request.status == 'confirmed') ||
        offer.status == 'confirmed';
    final bool isWaiting = offer.status == 'waiting';

    if (offer.status == 'rejected') return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isWinner ? Colors.green.shade300 : Colors.grey.shade300,
          width: isWinner ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isWinner) _buildCompactHeader(),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _buildProviderRow(isWinner),
                if (isWinner) _buildCompactVerificationCode(context),
                if (isWaiting) _buildCompactActionButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Center(
        child: Text(
          "SECURE HANDSHAKE ACTIVE",
          style: TextStyle(
            color: Colors.green.shade800,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProviderRow(bool isWinner) {
    return Row(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isWinner ? Colors.green.shade50 : Colors.orange.shade50,
          child: Icon(Icons.medical_services_outlined,
              size: 20, color: isWinner ? Colors.green : Colors.orange),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offer.providerName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                offer.providerPhone,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
        if (isWinner)
          Icon(Icons.verified, color: Colors.green.shade600, size: 22),
      ],
    );
  }

  Widget _buildCompactVerificationCode(BuildContext context) {
    final code = request.verificationCode ?? "------";

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "VERIFICATION CODE",
                style: TextStyle(
                  color: Colors.green.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                code,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          IconButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.copy_rounded, size: 20),
            color: Colors.green.shade700,
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionButtons() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              onPressed: () => onAction(offer, false),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade600),
              child: const Text("Decline"),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => onAction(offer, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade500,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Approve Offer", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
