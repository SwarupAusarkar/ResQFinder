import 'package:flutter/material.dart';
import '../models/request_model.dart';
import 'dart:async';

class ApprovalCard extends StatelessWidget {
  final EmergencyRequest request;
  final Function(EmergencyRequest, bool) onAction; // true for confirm, false for decline

  const ApprovalCard({
    super.key,
    required this.request,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate remaining time
    final expiryTime = request.acceptedAt!.add(const Duration(minutes: 5));
    final remaining = expiryTime.difference(DateTime.now());
    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        children: [
          // Timer Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: remaining.inMinutes < 1 ? Colors.red[100] : Colors.green[100],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: remaining.inMinutes < 1 ? Colors.red : Colors.green),
                const SizedBox(width: 8),
                Text(
                  "Confirm within: ${minutes}m ${seconds}s",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: remaining.inMinutes < 1 ? Colors.red[900] : Colors.green[900],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Resource Details
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.redAccent.withOpacity(0.1),
                      child: const Icon(Icons.medical_services, color: Colors.redAccent),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.itemName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text("Quantity: ${request.itemQuantity} ${request.itemUnit}"),
                        ],
                      ),
                    ),
                  ],
                ),

                const Divider(height: 30),

                // Note to User
                const Text(
                  "Help is ready! Confirming will finalize the request and provide you with a verification code for the provider.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),

                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onAction(request, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey[700],
                          side: BorderSide(color: Colors.grey[300]!),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text("Decline"),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => onAction(request, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: const Text("CONFIRM HELP"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}