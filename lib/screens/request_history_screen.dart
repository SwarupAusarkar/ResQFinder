import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class RequesterHistoryScreen extends StatefulWidget {
  const RequesterHistoryScreen({super.key});

  @override
  State<RequesterHistoryScreen> createState() => _RequesterHistoryScreenState();
}

class _RequesterHistoryScreenState extends State<RequesterHistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final user = AuthService().currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean, modern off-white
      appBar: AppBar(
        title: const Text(
          'Emergency History',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.redAccent,
          indicatorWeight: 3,
          labelColor: Colors.redAccent,
          unselectedLabelColor: Colors.grey,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "ACTIVE REQUESTS", icon: Icon(Icons.bolt_rounded, size: 20)),
            Tab(text: "PAST LOGS", icon: Icon(Icons.history_rounded, size: 20)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRequestList(['pending', 'confirmed']),
          _buildRequestList(['completed', 'expired_or_declined', 'expired_handshake']),
        ],
      ),
    );
  }

  Widget _buildRequestList(List<String> statuses) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('emergency_requests')
          .where('requesterId', isEqualTo: user?.uid)
          .where('status', whereIn: statuses)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Sync Error: Check Connection", style: TextStyle(color: Colors.red[300])));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _buildEmptyState();

        final requests = docs.map((doc) => EmergencyRequest.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          itemCount: requests.length,
          itemBuilder: (context, index) => _buildEnhancedHistoryCard(context, requests[index]),
        );
      },
    );
  }

  Widget _buildEnhancedHistoryCard(BuildContext context, EmergencyRequest request) {
    bool isConfirmed = request.status == 'confirmed';
    bool isCompleted = request.status == 'completed';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ExpansionTile(
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.white,
          leading: _getModernStatusIcon(request.status),
          title: Text(
            "${request.itemQuantity} ${request.itemUnit} ${request.itemName}",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: Color(0xFF1A1A1A)),
          ),
          subtitle: Text(
            DateFormat('MMM dd • hh:mm a').format(request.timestamp),
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          trailing: _buildModernStatusChip(request.status),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isConfirmed) _buildVerificationBanner(request.verificationCode ?? "---"),
                  const SizedBox(height: 16),
                  _buildSectionTitle("EVENT DETAILS"),
                  _detailRow(Icons.description_outlined, "Purpose", request.description),
                  _detailRow(Icons.location_on_outlined, "Location", request.locationName),
                  const Divider(height: 32, thickness: 0.8),
                  _buildSectionTitle("VERIFIED PROVIDER"),
                  if (request.confirmedProviderId != null)
                    _buildProviderCard(request)
                  else
                    const Text("Waiting for a local provider to accept...",
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12)),
                  if (isConfirmed) ...[
                    const SizedBox(height: 16),
                    _buildSafetyWarning(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationBanner(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF2E7D32)]),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("SECURE OTP", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(code, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 6)),
        ],
      ),
    );
  }

  Widget _buildProviderCard(EmergencyRequest request) {
    try {
      final winner = request.offers.firstWhere((o) => o.providerId == request.confirmedProviderId);
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.blue.withOpacity(0.1)),
        ),
        child: Row(
          children: [
            const CircleAvatar(backgroundColor: Colors.white, radius: 18, child: Icon(Icons.medical_services_rounded, color: Colors.blue, size: 18)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(winner.providerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(winner.providerPhone, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                ],
              ),
            ),
            if (request.status == 'completed') const Icon(Icons.verified, color: Colors.blue, size: 20),
          ],
        ),
      );
    } catch (_) {
      return const Text("Provider details archived.", style: TextStyle(color: Colors.grey, fontSize: 11));
    }
  }

  Widget _buildSectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(title, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.grey[400], letterSpacing: 1.5)),
  );

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.redAccent.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(child: Text("$label: $value", style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF4A4A4A)))),
      ],
    ),
  );

  Widget _buildModernStatusChip(String status) {
    Color color = status == 'confirmed' ? Colors.green : (status == 'pending' ? Colors.orange : Colors.blue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w800)),
    );
  }

  Widget _getModernStatusIcon(String status) {
    switch (status) {
      case 'completed': return const Icon(Icons.check_circle_rounded, color: Colors.blue);
      case 'confirmed': return const Icon(Icons.handshake_rounded, color: Colors.green);
      default: return const Icon(Icons.radio_button_checked_rounded, color: Colors.orange);
    }
  }

  Widget _buildSafetyWarning() => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.amber[50], borderRadius: BorderRadius.circular(10)),
    child: Row(children: [
      Icon(Icons.security_rounded, size: 16, color: Colors.amber[800]),
      const SizedBox(width: 10),
      const Expanded(child: Text("Only reveal your Secure OTP once the provider is physically present with the items.",
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF5D4037)))),
    ]),
  );

  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[200]),
        const SizedBox(height: 16),
        Text("NO LOGS FOUND", style: TextStyle(color: Colors.grey[400], letterSpacing: 2, fontWeight: FontWeight.w900, fontSize: 12)),
      ],
    ),
  );
}