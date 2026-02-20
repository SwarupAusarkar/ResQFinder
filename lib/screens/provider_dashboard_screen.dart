import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/RequestOffer.dart';
import '../models/request_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/NotificationHelper.dart';
import '../widgets/requestCard.dart';
import '../widgets/CustomNavigation.dart';
import 'provider_profile_edit_screen.dart';
import 'manage_inventory_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  final String? highlightRequestId;
  const ProviderDashboardScreen({super.key, this.highlightRequestId});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  String _selectedFilter = 'new';
  Position? _currentPosition;
  String? _highlightedRequestId;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _highlightedRequestId = widget.highlightRequestId;
    _initializeNotifications();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    Position? pos = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _currentPosition = pos);
  }

  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();

    // Listen for notification taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
    FirebaseMessaging.instance.getInitialMessage().then((msg) {
      if (msg != null) _handleNotificationTap(msg);
    });

    // Handle background-to-foreground highlighting
    if (_highlightedRequestId != null) {
      _startHighlightTimer();
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    final requestId = message.data['requestId'];
    if (requestId != null && mounted) {
      setState(() {
        _selectedFilter = 'new';
        _highlightedRequestId = requestId;
      });
      _startHighlightTimer();
    }
  }

  // void _handleNotificationTap(RemoteMessage message) {
  //   final type = message.data['type'];
  //   final redirectTo = message.data['redirectTo'];
  //
  //   if (!mounted) return;
  //
  //   // Handle different notification types
  //   switch (type) {
  //     case 'emergency_request':
  //     // Existing code - redirect to dashboard
  //       final requestId = message.data['requestId'];
  //       setState(() {
  //         _selectedFilter = 'new';
  //         _highlightedRequestId = requestId;
  //       });
  //       Future.delayed(const Duration(seconds: 4), () {
  //         if (mounted) setState(() => _highlightedRequestId = null);
  //       });
  //       break;
  //
  //     case 'inventory_update':
  //     // Navigate to inventory management
  //       Navigator.pushNamed(context, '/manage-inventory');
  //       break;
  //
  //     case 'offer_approved':
  //     // Navigate to dashboard and highlight request
  //       final requestId = message.data['requestId'];
  //       setState(() {
  //         _selectedFilter = 'my_offers';
  //         _highlightedRequestId = requestId;
  //       });
  //
  //       // Show success dialog
  //       Future.delayed(const Duration(milliseconds: 500), () {
  //         if (mounted) {
  //           showDialog(
  //             context: context,
  //             builder: (context) => AlertDialog(
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(16),
  //               ),
  //               content: Column(
  //                 mainAxisSize: MainAxisSize.min,
  //                 children: [
  //                   const Icon(
  //                     Icons.celebration,
  //                     size: 64,
  //                     color: Color(0xFF00897B),
  //                   ),
  //                   const SizedBox(height: 16),
  //                   const Text(
  //                     'You\'re Selected!',
  //                     style: TextStyle(
  //                       fontSize: 20,
  //                       fontWeight: FontWeight.bold,
  //                     ),
  //                   ),
  //                   const SizedBox(height: 8),
  //                   Text(
  //                     '${message.data['requesterName']} approved your offer!',
  //                     textAlign: TextAlign.center,
  //                     style: TextStyle(color: Colors.grey[600]),
  //                   ),
  //                 ],
  //               ),
  //               actions: [
  //                 ElevatedButton(
  //                   onPressed: () => Navigator.pop(context),
  //                   style: ElevatedButton.styleFrom(
  //                     backgroundColor: const Color(0xFF00897B),
  //                     minimumSize: const Size(double.infinity, 48),
  //                   ),
  //                   child: const Text('View Request'),
  //                 ),
  //               ],
  //             ),
  //           );
  //         }
  //       });
  //
  //       // Clear highlight after dialog
  //       Future.delayed(const Duration(seconds: 4), () {
  //         if (mounted) setState(() => _highlightedRequestId = null);
  //       });
  //       break;
  //
  //     default:
  //     // Generic handling - use redirectTo if available
  //       if (redirectTo != null && redirectTo.isNotEmpty) {
  //         Navigator.pushNamed(context, '/$redirectTo');
  //       }
  //   }
  // }
  void _startHighlightTimer() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _highlightedRequestId = null);
    });
  }

  Future<void> _acceptRequest(EmergencyRequest request) async {
    if (_isProcessing) return;
    final userId = _authService.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isProcessing = true);
    try {
      final requestRef = _firestore
          .collection('emergency_requests')
          .doc(request.id);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        final data = snapshot.data() as Map<String, dynamic>;

        if (data['acceptedBy'] != null)
          throw "Request already accepted by someone else";

        final pSnap = await _firestore.collection('users').doc(userId).get();
        final pData = pSnap.data() ?? {};

        final newOffer =
            RequestOffer(
              providerId: userId,
              providerName: pData['name'] ?? "Provider",
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
          const SnackBar(
            content: Text("Offer Sent!"),
            backgroundColor: Color(0xFF00897B),
          ),
        );
        setState(() => _selectedFilter = 'my_offers');
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Emergency Feed",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: Colors.black),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageInventoryScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _authService.signOut(),
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.black87),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProviderProfileEditScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          if (_isProcessing)
            const LinearProgressIndicator(color: Color(0xFF00897B)),
          Expanded(
            child:
                _currentPosition == null
                    ? const Center(child: CircularProgressIndicator())
                    : StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('emergency_requests')
                              .where('status', whereIn: ['pending', 'confirmed', 'completed', 'expired'])
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData)
                          return const Center(
                            child: CircularProgressIndicator(),
                          );

                        // ... inside your StreamBuilder builder ...
                        final requests = snapshot.data!.docs
                            .map((doc) => EmergencyRequest.fromFirestore(doc))
                            .where((req) {
                          double dist = Geolocator.distanceBetween(
                            _currentPosition!.latitude,
                            _currentPosition!.longitude,
                            req.latitude,
                            req.longitude,
                          ) / 1000;

                          bool isNearby = dist <= req.radius;
                          bool notDeclined = !req.declinedBy.contains(userId);
                          bool involved = req.offers.any((o) => o.providerId == userId);

                          // TAB 1: NEW REQUESTS
                          // Only show if: Pending, Nearby, Not Declined, and I haven't offered yet.
                          if (_selectedFilter == 'new') {
                            return req.status == 'pending' && isNearby && notDeclined && !involved;
                          }

                          // TAB 2: ACTIVE OFFERS
                          // Only show if: I am involved AND (Status is Pending or I am the winner/Confirmed)
                          // BUT exclude if status is 'completed' (that goes to history)
                          if (_selectedFilter == 'my_offers') {
                            return involved && (req.status == 'pending' || req.status == 'confirmed');
                          }

                          // TAB 3: HISTORY
                          // Show if: I was involved and the request is officially 'completed' or 'expired'
                          if (_selectedFilter == 'history') {
                            return involved && (req.status == 'confirmed' || req.status == 'expired');
                          }

                          return false;
                        }).toList();
                        if (requests.isEmpty) return _buildEmptyState();

                        return ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: requests.length,
                          itemBuilder: (context, index) {
                            final req = requests[index];
                            final isHighlighted =
                                _highlightedRequestId == req.id;

                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                border:
                                    isHighlighted
                                        ? Border.all(
                                          color: const Color(0xFF00897B),
                                          width: 2,
                                        )
                                        : null,
                                boxShadow:
                                    isHighlighted
                                        ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF00897B,
                                            ).withOpacity(0.2),
                                            blurRadius: 10,
                                          ),
                                        ]
                                        : null,
                              ),
                              child: RequestCard(
                                request: req,
                                onAccept: () => _acceptRequest(req),
                                onDecline:
                                    () => _firestore
                                        .collection('emergency_requests')
                                        .doc(req.id)
                                        .update({
                                          'declinedBy': FieldValue.arrayUnion([
                                            userId,
                                          ]),
                                        }),
                              ),
                            );
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          _filterChip("New Requests", 'new'),
          const SizedBox(width: 8),
          _filterChip("Active Offers", 'my_offers'),
          const SizedBox(width: 8),
          _filterChip("History", 'history'),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    bool selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (v) => setState(() => _selectedFilter = value),
      selectedColor: const Color(0xFF00897B).withOpacity(0.1),
      labelStyle: TextStyle(
        color: selected ? const Color(0xFF00897B) : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.radar, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "No requests found in this area",
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
