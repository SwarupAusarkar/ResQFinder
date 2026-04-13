// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../models/request_model.dart';
// import '../../models/RequestOffer.dart';
// import '../../services/auth_service.dart';
// import '../../widgets/requestCard.dart';
//
// class NewRequestsPage extends StatefulWidget {
//   const NewRequestsPage({super.key});
//
//   @override
//   State<NewRequestsPage> createState() => _NewRequestsPageState();
// }
//
// class _NewRequestsPageState extends State<NewRequestsPage> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthService _authService = AuthService();
//   String _selectedTimeFilter = 'all';
//   bool _isProcessing = false;
//
//   Future<void> _acceptRequest(EmergencyRequest request) async {
//     if (_isProcessing) return;
//     final providerId = _authService.currentUser?.uid;
//     if (providerId == null) return;
//
//     setState(() => _isProcessing = true);
//
//     try {
//       final requestRef = _firestore.collection('emergency_requests').doc(request.id);
//
//       await _firestore.runTransaction((transaction) async {
//         final snapshot = await transaction.get(requestRef);
//         if (!snapshot.exists) throw "Request no longer exists";
//
//         final data = snapshot.data() as Map<String, dynamic>;
//         final List offers = data['offers'] ?? [];
//         if (offers.any((o) => o['providerId'] == providerId)) throw "Offer already sent";
//
//         // ✅ FIX: Use providers collection
//         final pSnap = await _firestore.collection('providers').doc(providerId).get();
//         final pData = pSnap.data() ?? {};
//
//         final newOffer = RequestOffer(
//           providerId: providerId,
//           providerName: pData['name'] ?? pData['fullName'] ?? "Provider",
//           providerPhone: pData['phone'] ?? "",
//           acceptedAt: DateTime.now(),
//           status: 'waiting',
//         ).toMap();
//
//         transaction.update(requestRef, {
//           'offers': FieldValue.arrayUnion([newOffer]),
//         });
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text("✅ Offer sent! Waiting for approval."), backgroundColor: Color(0xFF00897B)),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
//
//   bool _matchesTimeFilter(DateTime timestamp) {
//     final now = DateTime.now();
//     switch (_selectedTimeFilter) {
//       case 'today':
//         return timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day;
//       case 'week':
//         return timestamp.isAfter(now.subtract(const Duration(days: 7)));
//       case 'all':
//       default:
//         return true;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final userId = _authService.currentUser?.uid;
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('New Requests'),
//         backgroundColor: const Color(0xFF0D4F4A),
//       ),
//       body: Column(
//         children: [
//           // Time Filter Chips
//           Container(
//             color: Colors.white,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//             child: SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: [
//                   _buildTimeChip('All', 'all'),
//                   const SizedBox(width: 8),
//                   _buildTimeChip('Today', 'today'),
//                   const SizedBox(width: 8),
//                   _buildTimeChip('This Week', 'week'),
//                 ],
//               ),
//             ),
//           ),
//
//           // Request List
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('emergency_requests')
//                   .where('status', isEqualTo: 'pending')
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (snapshot.hasError) {
//                   return Center(
//                     child: Text(
//                       "Error loading requests: ${snapshot.error}",
//                       style: TextStyle(color: Colors.red[300]),
//                     ),
//                   );
//                 }
//
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return const Center(
//                     child: CircularProgressIndicator(
//                       valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
//                     ),
//                   );
//                 }
//
//                 if (!snapshot.hasData) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//
//                 var requests = snapshot.data!.docs
//                     .map((doc) => EmergencyRequest.fromFirestore(doc))
//                     .toList();
//
//                 // Filter out already offered/declined
//                 requests = requests.where((req) {
//                   final hasOffered = req.offers.any((o) => o.providerId == userId);
//                   final hasDeclined = (req.declinedBy ?? []).contains(userId);
//                   return !hasOffered && !hasDeclined;
//                 }).toList();
//
//                 // Apply time filter
//                 requests = requests.where((r) => _matchesTimeFilter(r.timestamp)).toList();
//
//                 // ✅ Local sort to avoid Firebase index crash
//                 requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//
//                 if (requests.isEmpty) {
//                   return _buildEmptyState();
//                 }
//
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: requests.length,
//                   itemBuilder: (context, index) {
//                     final req = requests[index];
//                     return RequestCard(
//                       request: req,
//                       onAccept: () => _acceptRequest(req),
//                       onDecline: () => _firestore
//                           .collection('emergency_requests')
//                           .doc(req.id)
//                           .update({
//                         'declinedBy': FieldValue.arrayUnion([userId]),
//                       }),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTimeChip(String label, String value) {
//     final isSelected = _selectedTimeFilter == value;
//     return InkWell(
//       onTap: () => setState(() => _selectedTimeFilter = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF00897B) : Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color: isSelected ? const Color(0xFF00897B) : Colors.grey[300]!,
//             width: 1.5,
//           ),
//         ),
//         child: Text(
//           label,
//           style: TextStyle(
//             fontSize: 13,
//             fontWeight: FontWeight.bold,
//             color: isSelected ? Colors.white : Colors.grey[700],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
//             const SizedBox(height: 20),
//             Text('No New Requests',
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600])),
//             const SizedBox(height: 8),
//             Text('New emergency requests will appear here',
//                 textAlign: TextAlign.center,
//                 style: TextStyle(fontSize: 14, color: Colors.grey[500])),
//           ],
//         ),
//       ),
//     );
//   } }
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

class _NewRequestsPageState extends State<NewRequestsPage>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String _selectedTimeFilter = 'all';
  bool _isProcessing = false;
  late AnimationController _fabAnimController;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    super.dispose();
  }

  Future<void> _acceptRequest(EmergencyRequest request) async {
    if (_isProcessing) return;
    final providerId = _authService.currentUser?.uid;
    if (providerId == null) return;

    setState(() => _isProcessing = true);

    try {
      final requestRef =
      _firestore.collection('emergency_requests').doc(request.id);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) throw "Request no longer exists";

        final data = snapshot.data() as Map<String, dynamic>;
        final List offers = data['offers'] ?? [];
        if (offers.any((o) => o['providerId'] == providerId)) {
          throw "Offer already sent";
        }

        final pSnap =
        await _firestore.collection('providers').doc(providerId).get();
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
        _showSuccessSnack("✅ Offer sent! Waiting for approval.");
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnack(e.toString());
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        backgroundColor: const Color(0xFF00897B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
                child: Text(msg,
                    style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: Color(0xFF0A3D38),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  bool _matchesTimeFilter(DateTime timestamp) {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case 'today':
        return timestamp.year == now.year &&
            timestamp.month == now.month &&
            timestamp.day == now.day;
      case 'week':
        return timestamp.isAfter(now.subtract(const Duration(days: 7)));
      case 'all':
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── Custom App Bar ────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 120,
            backgroundColor: const Color(0xFF0A3D38),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF0A3D38), Color(0xFF00695C)],
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(24, 72, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: Color(0xFF69F0AE),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New Requests',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Live emergency calls near you',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Filter Chips ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildTimeChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildTimeChip('Today', 'today'),
                  const SizedBox(width: 8),
                  _buildTimeChip('This Week', 'week'),
                ],
              ),
            ),
          ),
        ],
        body: Column(
          children: [
            if (_isProcessing)
              LinearProgressIndicator(
                color: const Color(0xFF00897B),
                backgroundColor: const Color(0xFF00897B).withOpacity(0.15),
              ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('emergency_requests')
                    .where('status', isEqualTo: 'pending')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return _buildError(snapshot.error.toString());
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        valueColor:
                        AlwaysStoppedAnimation(Color(0xFF00897B)),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var requests = snapshot.data!.docs
                      .map((doc) => EmergencyRequest.fromFirestore(doc))
                      .toList();

                  requests = requests.where((req) {
                    final hasOffered =
                    req.offers.any((o) => o.providerId == userId);
                    final hasDeclined =
                    (req.declinedBy ?? []).contains(userId);
                    return !hasOffered && !hasDeclined;
                  }).toList();

                  requests = requests
                      .where((r) => _matchesTimeFilter(r.timestamp))
                      .toList();
                  requests
                      .sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  if (requests.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: requests.length,
                    itemBuilder: (context, index) {
                      final req = requests[index];
                      return _buildRequestTile(req, userId, index);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Wraps the existing RequestCard in a staggered-fade animation tile
  Widget _buildRequestTile(
      EmergencyRequest req, String? userId, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 60).clamp(0, 600)),
      curve: Curves.easeOutCubic,
      builder: (_, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: RequestCard(
          request: req,
          onAccept: () => _acceptRequest(req),
          onDecline: () => _firestore
              .collection('emergency_requests')
              .doc(req.id)
              .update({
            'declinedBy': FieldValue.arrayUnion([userId]),
          }),
        ),
      ),
    );
  }

  Widget _buildTimeChip(String label, String value) {
    final isSelected = _selectedTimeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTimeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00897B) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00897B)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: const Color(0xFF00897B).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            )
          ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 64, color: Colors.red[200]),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey[400])),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 52,
                color: Color(0xFF00897B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'All Clear!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No new emergency requests right now.\nCheck back in a bit.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
