import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';
import '../../services/auth_service.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      // FIX: Removed .orderBy('completedAt', descending: true) to prevent Firebase Index Crash
      stream: _firestore
          .collection('emergency_requests')
          .where('status', isEqualTo: 'completed')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text("Error loading history: ${snapshot.error}", style: TextStyle(color: Colors.red[300])),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00897B))));
        }

        var requests = snapshot.data!.docs
            .map((doc) => EmergencyRequest.fromFirestore(doc))
            .where((req) => req.offers.any((o) => o.providerId == userId) && req.status == 'completed')
            .toList();

        // FIX: Sort locally in Dart to bypass Firebase restrictions
        requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (requests.isEmpty) return _buildEmptyState();

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final req = requests[index];
            final wasWinner = req.confirmedProviderId == userId;
            return _buildHistoryCard(req, wasWinner);
          },
        );
      },
    );
  }

  Widget _buildHistoryCard(EmergencyRequest request, bool wasWinner) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: wasWinner ? Border.all(color: Colors.green[300]!, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: wasWinner ? Colors.green[50] : Colors.blue[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Icon(wasWinner ? Icons.check_circle : Icons.history, color: wasWinner ? Colors.green[700] : Colors.blue[700], size: 18),
                const SizedBox(width: 8),
                Text(wasWinner ? 'COMPLETED' : 'PARTICIPATED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: wasWinner ? Colors.green[900] : Colors.blue[900], letterSpacing: 1)),
                const Spacer(),
                Text(_formatDate(request.timestamp), style: TextStyle(fontSize: 11, color: Colors.grey[600])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: wasWinner ? Colors.green[100] : Colors.blue[100], borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.medical_services_rounded, color: wasWinner ? Colors.green[700] : Colors.blue[700], size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${request.itemQuantity} ${request.itemUnit} ${request.itemName}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
                          const SizedBox(height: 4),
                          Text(request.requesterName ?? "Emergency Request", style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Expanded(child: Text(request.locationName, style: TextStyle(fontSize: 12, color: Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (wasWinner) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green[200]!)),
                    child: Row(
                      children: [
                        Icon(Icons.monetization_on, color: Colors.green[700], size: 20),
                        const SizedBox(width: 8),
                        const Expanded(child: Text("Service completed successfully", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        Icon(Icons.verified, color: Colors.green[700], size: 18),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_outlined, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text('No History Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Your completed requests will appear here', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) return 'Today, ${DateFormat('h:mm a').format(date)}';
    if (dateOnly == yesterday) return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    return DateFormat('MMM d, h:mm a').format(date);
  }
}