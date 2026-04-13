// import 'package:emergency_res_loc_new/screens/InventoryManagementScreen.dart';
// import 'package:emergency_res_loc_new/screens/manage_inventory_screen.dart';
// import 'package:emergency_res_loc_new/screens/provider_registration_screen.dart';
// import 'package:emergency_res_loc_new/services/expiration_logic_service.dart';
// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../models/RequestOffer.dart' show RequestOffer;
// import '../models/request_model.dart';
// import '../services/HandShakeService.dart' show HandshakeService;
// import '../services/auth_service.dart';
// import '../widgets/requestCard.dart';
// import 'provider_profile_edit_screen.dart';
//
// class ProviderDashboardScreen extends StatefulWidget {
//   const ProviderDashboardScreen({super.key, required String initialTab});
//
//   @override
//   State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
// }
//
// class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final AuthService _authService = AuthService();
//   String _selectedFilter = 'new';
//   String _selectedTimeFilter = 'all';
//   bool _isProcessing = false;
//   bool _isAvailable = true;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadAvailability();
//   }
//
//   Future<void> _loadAvailability() async {
//     final uid = _authService.currentUser?.uid;
//     if (uid == null) return;
//
//     final doc = await _firestore.collection('providers').doc(uid).get();
//     if (mounted) {
//       setState(() {
//         _isAvailable = doc.data()?['isAvailable'] ?? true;
//       });
//     }
//   }
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
//
//         if (data['acceptedBy'] != null) throw "Someone else was already accepted";
//
//         final List offers = data['offers'] ?? [];
//         if (offers.any((o) => o['providerId'] == providerId)) throw "Offer already sent";
//
//         final pSnap = await _firestore.collection('providers').doc(providerId).get();
//         final pData = pSnap.data() ?? {};
//
//         final newOffer = RequestOffer(
//           providerId: providerId,
//           providerName: pData['name'] ?? "Provider",
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
//           const SnackBar(content: Text("Offer Sent! Waiting for citizen approval."), backgroundColor: Color(0xFF00897B)),
//         );
//         setState(() => _selectedFilter = 'my_offers');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
//       }
//     } finally {
//       if (mounted) setState(() => _isProcessing = false);
//     }
//   }
//
//   Future<void> _processVerification(EmergencyRequest request, String inputCode) async {
//     if (inputCode.trim() == request.verificationCode?.trim()) {
//       try {
//         await _firestore.collection('emergency_requests').doc(request.id).update({
//           'status': 'completed',
//           'completedAt': FieldValue.serverTimestamp(),
//         });
//
//         if (mounted) {
//           setState(() {
//             _selectedFilter = 'history';
//           });
//           Navigator.pop(context); // Close input dialog
//
//           showDialog(
//             context: context,
//             barrierDismissible: false,
//             builder: (context) => AlertDialog(
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.celebration, size: 64, color: Color(0xFF00897B)),
//                   const SizedBox(height: 16),
//                   const Text("Request Completed!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   Text("Thank you for helping!", style: TextStyle(color: Colors.grey[600])),
//                 ],
//               ),
//               actions: [
//                 ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 48)),
//                   child: const Text("Done"),
//                 ),
//               ],
//             ),
//           );
//         }
//       } catch (e) {
//         if (mounted) {
//           Navigator.pop(context);
//           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error completing request: $e"), backgroundColor: Colors.red));
//         }
//       }
//     } else {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Row(children: [Icon(Icons.error_outline, color: Colors.white), SizedBox(width: 8), Text("❌ Incorrect code. Please try again.")]),
//             backgroundColor: Colors.red, behavior: SnackBarBehavior.floating, duration: Duration(seconds: 2),
//           ),
//         );
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final user = _authService.currentUser;
//     if (user == null) return const Scaffold(body: Center(child: Text("Login Required")));
//
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Provider Dashboard'),
//         backgroundColor: const Color(0xFF00897B),
//         actions: [
//           Row(
//             children: [
//               Text(_isAvailable ? "Online" : "Offline", style: TextStyle(color: _isAvailable ? Colors.white : Colors.white70, fontSize: 12)),
//               Switch(
//                 value: _isAvailable, activeColor: Colors.greenAccent,
//                 onChanged: (value) async {
//                   final uid = _authService.currentUser?.uid;
//                   if (uid == null) return;
//                   setState(() => _isAvailable = value);
//                   await _firestore.collection('providers').doc(uid).update({'isAvailable': value});
//                 },
//               ),
//             ],
//           ),
//           IconButton(icon: const Icon(Icons.person), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderProfileEditScreen()))),
//           IconButton(icon: const Icon(Icons.inventory), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const InventoryMgmtScreen()))),
//           IconButton(icon: const Icon(Icons.logout), onPressed: () => _signOut(context)),
//         ],
//       ),
//       body: Column(
//         children: [
//           _buildFilterTabs(),
//           if (_isProcessing) const LinearProgressIndicator(color: Color(0xFF00897B)),
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore.collection('emergency_requests').snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
//
//                 final userId = user.uid;
//
//                 var requests = snapshot.data!.docs.map((doc) {
//                   ExpirationLogicService.checkAndExpireRequest(doc);
//                   return EmergencyRequest.fromFirestore(doc);
//                 }).where((req) {
//                   final bool hasOffered = req.offers.any((o) => o.providerId == userId);
//                   final bool notDeclined = !req.declinedBy.contains(userId);
//
//                   switch (_selectedFilter) {
//                     case 'new': return req.status == 'pending' && !hasOffered && notDeclined;
//                     case 'my_offers': return hasOffered && (req.status == 'pending' || req.status == 'confirmed');
//                     case 'history': return hasOffered && req.status == 'completed';
//                     default: return false;
//                   }
//                 }).toList();
//
//                 requests = requests.where((r) => _matchesTimeFilter(r.timestamp)).toList();
//                 requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));
//
//                 if (requests.isEmpty) {
//                   return _buildEmptyState(icon: Icons.search_off, title: 'No Requests', subtitle: _getEmptySubtitle());
//                 }
//
//                 return ListView.builder(
//                   padding: const EdgeInsets.all(16),
//                   itemCount: requests.length,
//                   itemBuilder: (context, index) {
//                     final req = requests[index];
//                     return RequestCard(
//                       request: req,
//                       onAccept: (_selectedFilter == 'new') ? () => _acceptRequest(req) : null,
//                       onDecline: (_selectedFilter == 'new') ? () => _firestore.collection('emergency_requests').doc(req.id).update({'declinedBy': FieldValue.arrayUnion([userId])}) : null,
//                       onVerify: (req.status == 'confirmed' && req.confirmedProviderId == userId)
//                           ? (code) async {
//                               final result = await HandshakeService().verifyAndCompleteRequest(requestId: req.id, providerInputCode: code);
//                               if (mounted) {
//                                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: result['success'] ? Colors.green : Colors.red));
//                                 if (result['success']) setState(() => _selectedFilter = 'history');
//                               }
//                             }
//                           : null,
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
//   Widget _buildFilterTabs() {
//     return Container(
//       color: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceAround,
//         children: [
//           _buildChoiceChip('New Requests', 'new'),
//           _buildChoiceChip('My Offers', 'my_offers'),
//           _buildChoiceChip('History', 'history'),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildChoiceChip(String label, String value) {
//     return ChoiceChip(
//       label: Text(label), selected: _selectedFilter == value,
//       onSelected: (selected) { if (selected) setState(() => _selectedFilter = value); },
//       selectedColor: Colors.green.withOpacity(0.2),
//       labelStyle: TextStyle(color: const Color(0xFF00897B), fontWeight: _selectedFilter == value ? FontWeight.bold : FontWeight.normal),
//     );
//   }
//
//   Widget _buildTimeChip(String label, String value) {
//     final isSelected = _selectedTimeFilter == value;
//     return InkWell(
//       onTap: () => setState(() => _selectedTimeFilter = value),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(color: isSelected ? const Color(0xFF00897B) : Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: isSelected ? const Color(0xFF00897B) : Colors.grey[300]!)),
//         child: Text(label, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.grey[700], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState({required IconData icon, required String title, required String subtitle}) {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(32),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(icon, size: 64, color: Colors.grey[400]), const SizedBox(height: 16),
//             Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey[600])), const SizedBox(height: 8),
//             Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
//           ],
//         ),
//       ),
//     );
//   }
//
//   bool _matchesTimeFilter(DateTime timestamp) {
//     final now = DateTime.now();
//     switch (_selectedTimeFilter) {
//       case 'today': return timestamp.year == now.year && timestamp.month == now.month && timestamp.day == now.day;
//       case 'week': return timestamp.isAfter(now.subtract(const Duration(days: 7)));
//       case 'all': default: return true;
//     }
//   }
//
//   String _getEmptySubtitle() {
//     switch (_selectedFilter) {
//       case 'new': return "New emergency requests will appear here";
//       case 'my_offers': return "Requests you've offered for will appear here";
//       case 'history': return "All your past requests will appear here";
//       default: return "No requests found";
//     }
//   }
//
//   Future<void> _signOut(BuildContext context) async {
//     try {
//       await AuthService().signOut();
//       if (context.mounted) Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
//     } catch (e) {
//       if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Sign out failed: $e'), backgroundColor: Colors.red));
//     }
//   } }
import 'package:emergency_res_loc_new/screens/InventoryManagementScreen.dart';
import 'package:emergency_res_loc_new/screens/newRequestPage.dart';
import 'package:emergency_res_loc_new/screens/myOffersPage.dart';
import 'package:emergency_res_loc_new/screens/ProviderHistoryPage.dart';
import 'package:emergency_res_loc_new/services/expiration_logic_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';
import 'provider_profile_edit_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key, required String initialTab});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  bool _isAvailable = true;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Live counters for badge display
  int _newCount = 0;
  int _offersCount = 0;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadAvailability() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;
    final doc = await _firestore.collection('providers').doc(uid).get();
    if (mounted) {
      setState(() {
        _isAvailable = doc.data()?['isAvailable'] ?? true;
      });
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      await AuthService().signOut();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Login Required")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F3),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('emergency_requests').snapshots(),
        builder: (context, snapshot) {
          // Compute badge counts
          if (snapshot.hasData) {
            final userId = user.uid;
            final docs = snapshot.data!.docs;
            _newCount = docs.where((doc) {
              try {
                ExpirationLogicService.checkAndExpireRequest(doc);
                final req = EmergencyRequest.fromFirestore(doc);
                final hasOffered = req.offers.any((o) => o.providerId == userId);
                final notDeclined = !req.declinedBy.contains(userId);
                return req.status == 'pending' && !hasOffered && notDeclined;
              } catch (_) {
                return false;
              }
            }).length;

            _offersCount = docs.where((doc) {
              try {
                final req = EmergencyRequest.fromFirestore(doc);
                final hasOffered = req.offers.any((o) => o.providerId == userId);
                return hasOffered &&
                    (req.status == 'pending' || req.status == 'confirmed');
              } catch (_) {
                return false;
              }
            }).length;
          }

          return CustomScrollView(
            slivers: [
              // ── Hero App Bar ──────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 180,
                pinned: true,
                backgroundColor: const Color(0xFF0A3D38),
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildHeroHeader(user.uid),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.person_outline, color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProviderProfileEditScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.inventory_2_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryMgmtScreen(),
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                    const Icon(Icons.logout_rounded, color: Colors.white70),
                    onPressed: () => _signOut(context),
                  ),
                ],
              ),

              // ── Body ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Availability toggle card
                      _buildAvailabilityCard(),
                      const SizedBox(height: 28),

                      // Section label
                      const Text(
                        'QUICK ACCESS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B8A87),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3 Navigation Cards
                      _buildNavCard(
                        label: 'New Requests',
                        subtitle: 'Browse & offer on live emergencies',
                        icon: Icons.notifications_active_rounded,
                        iconBg: const Color(0xFFE8F5E9),
                        iconColor: const Color(0xFF2E7D32),
                        badge: _newCount,
                        accentColor: const Color(0xFF43A047),
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(const NewRequestsPage()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildNavCard(
                        label: 'My Offers',
                        subtitle: 'Track your pending & confirmed offers',
                        icon: Icons.local_offer_rounded,
                        iconBg: const Color(0xFFE3F2FD),
                        iconColor: const Color(0xFF1565C0),
                        badge: _offersCount,
                        accentColor: const Color(0xFF1E88E5),
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(const MyOffersPage()),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _buildNavCard(
                        label: 'History',
                        subtitle: 'View completed & participated requests',
                        icon: Icons.history_rounded,
                        iconBg: const Color(0xFFFFF8E1),
                        iconColor: const Color(0xFFF57F17),
                        badge: 0,
                        accentColor: const Color(0xFFFFB300),
                        onTap: () => Navigator.push(
                          context,
                          _slideRoute(const HistoryPage()),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader(String uid) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A3D38), Color(0xFF00695C)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 20),
      child: FutureBuilder<DocumentSnapshot>(
        future: _firestore.collection('providers').doc(uid).get(),
        builder: (context, snap) {
          final name = snap.data?.data() != null
              ? (snap.data!.data() as Map<String, dynamic>)['name'] ??
              (snap.data!.data() as Map<String, dynamic>)['fullName'] ??
              'Provider'
              : 'Provider';
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                children: [
                  // Pulse indicator
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (_, __) => Transform.scale(
                      scale: _isAvailable ? _pulseAnimation.value : 1.0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isAvailable
                              ? const Color(0xFF69F0AE)
                              : Colors.grey[400],
                          boxShadow: _isAvailable
                              ? [
                            BoxShadow(
                              color: const Color(0xFF69F0AE)
                                  .withOpacity(0.6),
                              blurRadius: 8,
                              spreadRadius: 2,
                            )
                          ]
                              : [],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isAvailable ? 'ONLINE' : 'OFFLINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: _isAvailable
                          ? const Color(0xFF69F0AE)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Hello, $name 👋',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to help someone today?',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.65),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _isAvailable
                  ? const Color(0xFFE8F5E9)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isAvailable
                  ? Icons.wifi_tethering_rounded
                  : Icons.wifi_tethering_off_rounded,
              color: _isAvailable
                  ? const Color(0xFF2E7D32)
                  : Colors.grey[500],
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isAvailable
                      ? 'You\'re accepting requests'
                      : 'You\'re not accepting requests',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  _isAvailable
                      ? 'Toggle off to go offline'
                      : 'Toggle on to go online',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: _isAvailable,
              activeColor: const Color(0xFF00897B),
              onChanged: (value) async {
                final uid = _authService.currentUser?.uid;
                if (uid == null) return;
                setState(() => _isAvailable = value);
                await _firestore
                    .collection('providers')
                    .doc(uid)
                    .update({'isAvailable': value});
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color accentColor,
    required int badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badge > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Text(
                        '$badge',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PageRouteBuilder _slideRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => page,
      transitionsBuilder: (_, animation, __, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          ),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 320),
    );
  }
}