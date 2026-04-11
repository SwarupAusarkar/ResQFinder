import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/request_model.dart';
import '../../models/RequestOffer.dart';
import '../../services/auth_service.dart';
import '../../widgets/requestCard.dart';

class NewRequestsPage extends StatefulWidget {
  const NewRequestsPage({super.key});

  @override
  State<NewRequestsPage> createState() => _NewRequestsPageState();
}

class _NewRequestsPageState extends State<NewRequestsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String _selectedTimeFilter = 'all';
  bool _isProcessing = false;

  Future<void> _acceptRequest(EmergencyRequest request) async {
    if (_isProcessing) return;
    final providerId = _authService.currentUser?.uid;
    if (providerId == null) return;

    setState(() => _isProcessing = true);

    try {
      final requestRef = _firestore.collection('emergency_requests').doc(request.id);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) throw "Request no longer exists";

        final data = snapshot.data() as Map<String, dynamic>;

        final List offers = data['offers'] ?? [];
        if (offers.any((o) => o['providerId'] == providerId)) throw "Offer already sent";

        // FIX: Changed 'users' to 'providers'. This was causing your name to be blank!
        final pSnap = await _firestore.collection('providers').doc(providerId).get();
        final pData = pSnap.data() ?? {};

        final newOffer = RequestOffer(
          providerId: providerId,
          providerName: pData['name'] ?? pData['fullName'] ?? "Provider",
          providerPhone: pData['phone'] ?? "",
          acceptedAt: DateTime.now(),
          status: 'waiting',
        ).toMap();

        transaction.update(requestRef, {
          'offers': FieldValue.arrayUnion([newOffer]),
        });
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Offer sent! Waiting for approval."), backgroundColor: Color(0xFF00897B)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  bool _matchesTimeFilter(DateTime timestamp) {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 'today': return timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day;
      case 'week': return timestamp.isAfter(now.subtract(const Duration(days: 7)));
      case 'all': default: return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildTimeChip('All', 'all'), const SizedBox(width: 8),
              _buildTimeChip('Today', 'today'), const SizedBox(width: 8),
              _buildTimeChip('This Week', 'week'),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            // FIX: Removed .orderBy('timestamp', descending: true) to fix Firebase Index Crash
            stream: _firestore
                .collection('emergency_requests')
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Error loading requests: ${snapshot.error}", style: TextStyle(color: Colors.red[300])));
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFF00897B))));

              var requests = snapshot.data!.docs.map((doc) => EmergencyRequest.fromFirestore(doc)).toList();

              requests = requests.where((req) {
                final hasOffered = req.offers.any((o) => o.providerId == userId);
                final hasDeclined = (req.declinedBy ?? []).contains(userId);
                return !hasOffered && !hasDeclined;
              }).toList();

              requests = requests.where((r) => _matchesTimeFilter(r.timestamp)).toList();

              // FIX: Sort locally in Dart to bypass Firebase restrictions
              requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

              if (requests.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final req = requests[index];
                  return RequestCard(
                    request: req,
                    onAccept: () => _acceptRequest(req),
                    onDecline: () => _firestore.collection('emergency_requests').doc(req.id).update({'declinedBy': FieldValue.arrayUnion([userId])}),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimeChip(String label, String value) {
    final isSelected = _selectedTimeFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedTimeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00897B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF00897B) : Colors.grey[300]!, width: 1.5),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.grey[700])),
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
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]), const SizedBox(height: 20),
            Text('No New Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])), const SizedBox(height: 8),
            Text('New emergency requests will appear here', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }
}