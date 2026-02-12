import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/RequestOffer.dart';
import '../services/auth_service.dart';
import '../widgets/approvalCard.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isProcessing = false;

  String _generate6DigitCode() {
    return (100000 + Random().nextInt(900000)).toString();
  }

  Future<void> _handleOfferAction(EmergencyRequest request, RequestOffer selectedOffer, bool isApproving) async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      final requestRef = _firestore.collection('emergency_requests').doc(request.id);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) throw "Request not found";

        if (isApproving) {
          // Generate the 6-digit verification code
          String vCode = _generate6DigitCode();

          // Update ALL offers: the chosen one becomes 'confirmed', others become 'rejected'
          List<Map<String, dynamic>> updatedOffers = request.offers.map((offer) {
            var map = offer.toMap();
            if (offer.providerId == selectedOffer.providerId) {
              map['status'] = 'confirmed'; // Syncing with OfferApprovalCard logic
            } else {
              map['status'] = 'rejected';
            }
            return map;
          }).toList();

          transaction.update(requestRef, {
            'status': 'confirmed',
            'confirmedProviderId': selectedOffer.providerId,
            'acceptedBy': selectedOffer.providerId,
            'verificationCode': vCode,
            'offers': updatedOffers,
            'confirmedAt': FieldValue.serverTimestamp(),
          });
        } else {
          // Decline logic: mark only the selected offer as rejected
          List<Map<String, dynamic>> updatedOffers = request.offers.map((offer) {
            var map = offer.toMap();
            if (offer.providerId == selectedOffer.providerId) {
              map['status'] = 'rejected';
            }
            return map;
          }).toList();

          transaction.update(requestRef, {'offers': updatedOffers});
        }
      });

      // ... existing SnackBar logic ...
    } catch (e) {
      // ... existing error logic ...
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Offers"),
        backgroundColor: Colors.red[700],
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('emergency_requests')
            .where('requesterId', isEqualTo: user?.uid)
        // Listen for all active states
            .where('status', whereIn: ['pending', 'provider_accepted', 'confirmed'])
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          // Sort by timestamp manually if Firestore ordering conflicts with 'whereIn'
          final requests = snapshot.data!.docs
              .map((doc) => EmergencyRequest.fromFirestore(doc))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

          if (requests.isEmpty) return _buildEmptyState();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: requests.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, index) {
              final req = requests[index];
              final visibleOffers = _getVisibleOffers(req);

              if (visibleOffers.isEmpty) return const SizedBox.shrink();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRequestHeader(req),
                  const SizedBox(height: 12),
                  ...visibleOffers.map((offer) => OfferApprovalCard(
                    request: req,
                    offer: offer,
                    onAction: (off, isApprove) => _handleOfferAction(req, off, isApprove),
                  )),
                ],
              );
            },
          );
        },
      ),
    );
  }
  List<RequestOffer> _getVisibleOffers(EmergencyRequest request) {
    if (request.status == 'confirmed') {
      // Filter for the specific provider that was confirmed
      return request.offers
          .where((o) => o.providerId == request.confirmedProviderId || o.status == 'confirmed')
          .toList();
    } else {
      // While pending, show all active (waiting) offers
      return request.offers.where((o) => o.status == 'waiting').toList();
    }
  }

  Widget _buildRequestHeader(EmergencyRequest request) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: request.status == 'confirmed' ? Colors.green[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: request.status == 'confirmed' ? Colors.green : Colors.blue,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                request.status == 'confirmed' ? Icons.check_circle : Icons.pending_actions,
                color: request.status == 'confirmed' ? Colors.green : Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${request.itemQuantity} ${request.itemUnit} of ${request.itemName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.locationName,
            style: TextStyle(color: Colors.grey[700], fontSize: 14),
          ),
          if (request.status == 'confirmed') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Provider confirmed!',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            "No active requests",
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

}