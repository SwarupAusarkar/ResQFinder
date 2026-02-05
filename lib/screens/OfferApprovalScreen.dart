import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import '../models/request_model.dart';
import '../services/auth_service.dart';

class approval_screen extends StatefulWidget {
  const approval_screen({super.key});

  @override
  State<approval_screen> createState() => _approval_screenState();
}

class _approval_screenState extends State<approval_screen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI every minute to update the countdown timers
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _handleFinalAction(EmergencyRequest request, bool isConfirming) async {
    try {
      await _firestore.collection('emergency_requests').doc(request.id).update({
        'status': isConfirming ? 'confirmed' : 'expired_or_declined',
        'confirmedAt': isConfirming ? FieldValue.serverTimestamp() : null,
      });

      // If declining or expired, you might want to trigger the "Inventory Rollback" here

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isConfirming ? 'Provider Confirmed!' : 'Request Dismissed')),
      );
    } catch (e) {
      print("Error updating status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Approve Provider")),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('emergency_requests')
            .where('requesterId', isEqualTo: user?.uid)
            .where('status', isEqualTo: 'accepted')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final requests = snapshot.data!.docs
              .map((doc) => EmergencyRequest.fromFirestore(doc))
              .toList();

          if (requests.isEmpty) {
            return const Center(child: Text("No providers waiting for approval."));
          }

          return ListView.builder(
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final req = requests[index];

              // 5-Minute Logic
              final expiryTime = req.acceptedAt!.add(const Duration(minutes: 5));
              final remaining = expiryTime.difference(DateTime.now());
              final isExpired = remaining.isNegative;

              if (isExpired) {
                // Auto-mark as expired in DB when UI detects it
                _handleFinalAction(req, false);
                return const SizedBox();
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text("Provider ready for ${req.itemName}"),
                  subtitle: Text("Expires in: ${remaining.inMinutes}m ${remaining.inSeconds % 60}s"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleFinalAction(req, false),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () => _handleFinalAction(req, true),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  } }
