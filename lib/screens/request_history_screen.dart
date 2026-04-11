// lib/screens/request_history_screen.dart
import 'package:emergency_res_loc_new/models/reviews.dart';
import 'package:emergency_res_loc_new/widgets/ReviewDialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../services/ReviewService.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

// ── Color tokens ──────────────────────────────────────────────────────────────
const _teal = Color(0xFF0D9488);
const _tealDark = Color(0xFF0D4F4A);
const _bgColor = Color(0xFFF8FAFB);

class RequesterHistoryScreen extends StatefulWidget {
  const RequesterHistoryScreen({super.key});

  @override
  State<RequesterHistoryScreen> createState() => _RequesterHistoryScreenState();
}

class _RequesterHistoryScreenState extends State<RequesterHistoryScreen>
    with SingleTickerProviderStateMixin {
  // ── State (unchanged) ────────────────────────────────────────────────────────
  late TabController _tabController;
  final user = AuthService().currentUser;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  Future<bool> _hasBeenReviewed(String requestId) async {
    try {
      final snap = await firestore
          .collection('reviews')
          .where('requestId', isEqualTo: requestId)
          .where('requesterId', isEqualTo: user?.uid)
          .limit(1)
          .get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  void _openReviewFlow(EmergencyRequest request) {
    try {
      final winner = request.offers.firstWhere((o) => o.providerId == request.confirmedProviderId);
      showDialog(
        context: context,
        builder: (context) => ReviewDialog(
          providerId: request.confirmedProviderId!,
          providerName: winner.providerName,
          requesterId: user?.uid ?? '',
          requestId: request.id,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not load provider details.")));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HistoryHeader(),
            _TabRow(controller: _tabController),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ActiveRequestsTab(
                    user: user,
                    firestore: firestore,
                    onReview: _openReviewFlow,
                    hasBeenReviewed: _hasBeenReviewed,
                  ),
                  _HistoryTab(
                    user: user,
                    firestore: firestore,
                    onReview: _openReviewFlow,
                    hasBeenReviewed: _hasBeenReviewed,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _HistoryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: _tealDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Request Log', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _tealDark)),
          const SizedBox(height: 4),
          Text(
            'Track your active medical dispatches and review historical emergency records.',
            style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _TabRow extends StatelessWidget {
  final TabController controller;
  const _TabRow({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(color: _teal, borderRadius: BorderRadius.circular(10)),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey[500],
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
        padding: const EdgeInsets.all(4),
        dividerColor: Colors.transparent,
      ),
    );
  }
}

// ── Active Requests Tab ───────────────────────────────────────────────────────

class _ActiveRequestsTab extends StatelessWidget {
  final dynamic user;
  final FirebaseFirestore firestore;
  final void Function(EmergencyRequest) onReview;
  final Future<bool> Function(String) hasBeenReviewed;

  const _ActiveRequestsTab({
    required this.user,
    required this.firestore,
    required this.onReview,
    required this.hasBeenReviewed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('emergency_requests')
          .where('requesterId', isEqualTo: user?.uid)
          .where('status', whereIn: ['pending', 'confirmed'])
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorState();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _teal, strokeWidth: 2));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _EmptyState(label: 'No active requests');
        final requests = docs.map((doc) => EmergencyRequest.fromFirestore(doc)).toList();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
          itemCount: requests.length,
          itemBuilder: (context, i) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: ActiveRequestCard(
              request: requests[i],
              onReview: onReview,
              hasBeenReviewed: hasBeenReviewed,
            ),
          ),
        );
      },
    );
  }
}

// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final dynamic user;
  final FirebaseFirestore firestore;
  final void Function(EmergencyRequest) onReview;
  final Future<bool> Function(String) hasBeenReviewed;

  const _HistoryTab({
    required this.user,
    required this.firestore,
    required this.onReview,
    required this.hasBeenReviewed,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: firestore
          .collection('emergency_requests')
          .where('requesterId', isEqualTo: user?.uid)
          .where('status', whereIn: ['completed', 'expired_or_declined', 'expired_handshake'])
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return _ErrorState();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _teal, strokeWidth: 2));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) return _EmptyState(label: 'No past records');
        final requests = docs.map((doc) => EmergencyRequest.fromFirestore(doc)).toList();

        // Safety score (mock — from completion rate)
        final completed = requests.where((r) => r.status == 'completed').length;
        final score = requests.isEmpty ? 0 : ((completed / requests.length) * 100).round();

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          itemCount: requests.length + 2, // +2 for header label and safety score
          itemBuilder: (context, i) {
            if (i == 0) return const _RecentCompletionLabel();
            if (i == requests.length + 1) return _SafetyScoreCard(score: score);
            final req = requests[i - 1];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: HistoryRequestCard(
                request: req,
                onReview: onReview,
                hasBeenReviewed: hasBeenReviewed,
              ),
            );
          },
        );
      },
    );
  }
}

// ── ACTIVE REQUEST CARD ───────────────────────────────────────────────────────

class ActiveRequestCard extends StatelessWidget {
  final EmergencyRequest request;
  final void Function(EmergencyRequest) onReview;
  final Future<bool> Function(String) hasBeenReviewed;

  const ActiveRequestCard({
    super.key,
    required this.request,
    required this.onReview,
    required this.hasBeenReviewed,
  });

  bool get _isConfirmed => request.status == 'confirmed';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActiveCardHeader(request: request),
          if (_isConfirmed) ...[
            _VerificationCodeBanner(code: request.verificationCode ?? '---'),
          ],
          _ActiveCardBody(request: request),
          if (_isConfirmed) _ActiveCardActions(request: request),
        ],
      ),
    );
  }
}

class _ActiveCardHeader extends StatelessWidget {
  final EmergencyRequest request;
  const _ActiveCardHeader({required this.request});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = request.status == 'confirmed';
    final isPending = request.status == 'pending';
    final statusLabel = isConfirmed ? 'IN TRANSIT' : 'ASSIGNING PROVIDER';
    final statusColor = isConfirmed ? const Color(0xFFDCFCE7) : const Color(0xFFFFF7ED);
    final statusTextColor = isConfirmed ? const Color(0xFF16A34A) : const Color(0xFFEA580C);
    final statusIcon = isConfirmed ? Icons.local_shipping_rounded : Icons.search_rounded;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.4),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, size: 14, color: statusTextColor),
          const SizedBox(width: 6),
          Text(
            statusLabel,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusTextColor, letterSpacing: 1),
          ),
          const Spacer(),
          Text(
            DateFormat('d MMM yyyy').format(request.timestamp),
            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _VerificationCodeBanner extends StatelessWidget {
  final String code;
  const _VerificationCodeBanner({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0D4F4A),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('VERIFY CODE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white.withOpacity(0.6), letterSpacing: 1)),
          Text(code, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 8)),
        ],
      ),
    );
  }
}

class _ActiveCardBody extends StatelessWidget {
  final EmergencyRequest request;
  const _ActiveCardBody({required this.request});

  @override
  Widget build(BuildContext context) {
    final isConfirmed = request.status == 'confirmed';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${request.itemName} ${request.itemQuantity}${request.itemUnit}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _tealDark),
          ),
          const SizedBox(height: 4),
          Text(
            '${request.description.isNotEmpty ? request.description : 'Emergency Request'} • ${DateFormat('d MMM yyyy').format(request.timestamp)}',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
          const SizedBox(height: 14),

          // COPY CODE row
          if (isConfirmed) ...[
            Row(
              children: [
                _InfoChip(label: 'COPY CODE', value: request.verificationCode ?? '----', isCode: true),
              ],
            ),
            const SizedBox(height: 10),
          ],

          // Source & ETA
          Row(
            children: [
              _InfoChip(label: 'SOURCE', value: request.locationName.isNotEmpty ? request.locationName.split(',').first : 'Unknown'),
              const SizedBox(width: 8),
              _InfoChip(label: 'ETA', value: '${request.radius.toInt()} Mins'),
            ],
          ),

          if (isConfirmed) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF16A34A).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.near_me_rounded, size: 13, color: Color(0xFF16A34A)),
                  const SizedBox(width: 6),
                  const Text('On the way to destination', style: TextStyle(fontSize: 12, color: Color(0xFF16A34A), fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF16A34A)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _ActiveCardActions extends StatelessWidget {
  final EmergencyRequest request;
  const _ActiveCardActions({required this.request});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: _OutlineButton(label: 'Modify', onTap: () {}),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _OutlineButton(label: 'Cancel', onTap: () {}, isDestructive: true),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isCode;

  const _InfoChip({required this.label, required this.value, this.isCode = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: isCode ? 16 : 12,
              fontWeight: FontWeight.w700,
              color: isCode ? _tealDark : const Color(0xFF0F172A),
              letterSpacing: isCode ? 4 : 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OutlineButton({required this.label, required this.onTap, this.isDestructive = false});

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? const Color(0xFFDC2626) : _tealDark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color))),
      ),
    );
  }
}

// ── HISTORY REQUEST CARD ──────────────────────────────────────────────────────

class HistoryRequestCard extends StatelessWidget {
  final EmergencyRequest request;
  final void Function(EmergencyRequest) onReview;
  final Future<bool> Function(String) hasBeenReviewed;

  const HistoryRequestCard({
    super.key,
    required this.request,
    required this.onReview,
    required this.hasBeenReviewed,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = request.status == 'completed';
    final statusColor = isCompleted ? const Color(0xFF16A34A) : const Color(0xFF94A3B8);
    final statusBg = isCompleted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(
                isCompleted ? Icons.check_rounded : Icons.cancel_outlined,
                color: statusColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${request.itemName} ${request.itemQuantity}${request.itemUnit}',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _tealDark),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    DateFormat('d MMM yyyy • hh:mm a').format(request.timestamp),
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                  ),
                ],
              ),
            ),
            // Amount/cost placeholder
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  request.confirmedProviderId != null ? '₹---' : 'N/A',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _tealDark),
                ),
                const SizedBox(height: 2),
                if (isCompleted)
                  FutureBuilder<bool>(
                    future: hasBeenReviewed(request.id),
                    builder: (ctx, snap) {
                      final reviewed = snap.data ?? false;
                      if (reviewed || request.isReviewed == true) {
                        return const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B));
                      }
                      return GestureDetector(
                        onTap: () => onReview(request),
                        child: const Text('Rate', style: TextStyle(fontSize: 11, color: _teal, fontWeight: FontWeight.w600)),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _RecentCompletionLabel extends StatelessWidget {
  const _RecentCompletionLabel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        'RECENT COMPLETION',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.grey[400], letterSpacing: 1.5),
      ),
    );
  }
}

class _SafetyScoreCard extends StatelessWidget {
  final int score;
  const _SafetyScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SAFETY SCORE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white60, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text('$score%', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 4),
          const Text('Your emergency response efficiency is top-tier this month.', style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
          const SizedBox(height: 14),
          // Floating SOS chip
          Align(
            alignment: Alignment.bottomRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.4), blurRadius: 8)],
              ),
              child: const Text('SOS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text('Sync Error: Check Connection', style: TextStyle(color: Colors.red[300])));
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(color: const Color(0xFFF0FDF9), borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.assignment_late_outlined, size: 40, color: _teal),
          ),
          const SizedBox(height: 16),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[400], fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}