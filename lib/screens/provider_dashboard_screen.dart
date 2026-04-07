import 'package:emergency_res_loc_new/screens/InventoryManagementScreen.dart';
import 'package:emergency_res_loc_new/screens/manage_inventory_screen.dart';
import 'package:emergency_res_loc_new/screens/provider_registration_screen.dart';
import 'package:emergency_res_loc_new/services/expiration_logic_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/RequestOffer.dart' show RequestOffer;
import '../models/request_model.dart';
import '../services/HandShakeService.dart' show HandshakeService;
import '../services/auth_service.dart';
import '../widgets/requestCard.dart';
import 'provider_profile_edit_screen.dart';
import '../services/expiration_logic_service.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key, required String initialTab});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String _selectedFilter = 'new';
  String _selectedTimeFilter = 'all';
  bool _isProcessing = false;
  bool _isAvailable = true;
  Future<void> _acceptRequest(EmergencyRequest request) async {
    if (_isProcessing) return;
    final providerId = _authService.currentUser?.uid;
    if (providerId == null) return;

    setState(() => _isProcessing = true);

    try {
      final requestRef = _firestore
          .collection('emergency_requests')
          .doc(request.id);

      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(requestRef);
        if (!snapshot.exists) throw "Request no longer exists";

        final data = snapshot.data() as Map<String, dynamic>;

        // Check if already taken
        if (data['acceptedBy'] != null)
          throw "Someone else was already accepted";

        // Check if already offered
        final List offers = data['offers'] ?? [];
        if (offers.any((o) => o['providerId'] == providerId))
          throw "Offer already sent";

        // Get Provider Info for the offer
        final pSnap =
            await _firestore.collection('providers').doc(providerId).get();
        final pData = pSnap.data() ?? {};

        final newOffer =
            RequestOffer(
              providerId: providerId,
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
            content: Text("Offer Sent! Waiting for citizen approval."),
            backgroundColor: Color(0xFF00897B),
          ),
        );
        setState(() => _selectedFilter = 'my_offers');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) return;

    final doc = await _firestore.collection('providers').doc(uid).get();
    setState(() {
      _isAvailable = doc.data()?['isAvailable'] ?? true;
    });
  }

  Future<void> _processVerification(
    EmergencyRequest request,
    String inputCode,
  ) async {
    if (inputCode.trim() == request.verificationCode?.trim()) {
      try {
        await _firestore
            .collection('emergency_requests')
            .doc(request.id)
            .update({
              'status': 'completed',
              'completedAt': FieldValue.serverTimestamp(),
            });

        if (mounted) {
          setState(() {
            _selectedFilter = 'history';
          });
          Navigator.pop(context); // Close dialog

          // Show success
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.celebration,
                        size: 64,
                        color: Color(0xFF00897B),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Request Completed!",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Thank you for helping!",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  actions: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00897B),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: const Text("Done"),
                    ),
                  ],
                ),
          );
        }
      } catch (e) {
        if (mounted) {
          Navigator.pop(context); // Close dialog
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error completing request: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        // Show error but keep dialog open
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Text("❌ Incorrect code. Please try again."),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null)
      return const Scaffold(body: Center(child: Text("Login Required")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Color(0xFF00897B),
        actions: [
          Row(
            children: [
              Text(
                _isAvailable ? "Online" : "Offline",
                style: TextStyle(
                  color: _isAvailable ? Colors.white : Colors.white70,
                  fontSize: 12,
                ),
              ),
              Switch(
                value: _isAvailable,
                activeColor: Colors.greenAccent,
                onChanged: (value) async {
                  final uid = _authService.currentUser?.uid;
                  if (uid == null) return;

                  setState(() => _isAvailable = value);

                  await _firestore.collection('providers').doc(uid).update({
                    'isAvailable': value,
                  });
                },
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderProfileEditScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const InventoryMgmtScreen(),
                  ),
                ),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>_signOut(context),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          if (_isProcessing)
            const LinearProgressIndicator(color: Color(0xFF00897B)),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  _firestore
                      .collection('emergency_requests')
                      .snapshots(), // ✅ Fetch all statuses
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userId = user.uid;

                var requests =
                    snapshot.data!.docs
                        .map((doc) {
                          ExpirationLogicService.checkAndExpireRequest(doc);
                          return EmergencyRequest.fromFirestore(doc);
                        })
                        .where((req) {
                          final bool hasOffered = req.offers.any(
                            (o) => o.providerId == userId,
                          );

                          final bool notDeclined =
                              !req.declinedBy.contains(userId);

                          switch (_selectedFilter) {
                            case 'new':
                              // Only pending requests
                              // I have not offered
                              // I have not declined
                              return req.status == 'pending' &&
                                  !hasOffered &&
                                  notDeclined;

                            case 'my_offers':
                              // I have offered
                              // Still active (not completed)
                              return hasOffered &&
                                  (req.status == 'pending' ||
                                      req.status == 'confirmed');

                            case 'history':
                              // Only completed requests where I was involved
                              return hasOffered && req.status == 'completed';

                            default:
                              return false;
                          }
                        })
                        .toList();

                // Apply time filter
                requests =
                    requests
                        .where((r) => _matchesTimeFilter(r.timestamp))
                        .toList();

                // Sort latest first
                requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (requests.isEmpty) {
                  return _buildEmptyState(
                    icon: Icons.search_off,
                    title: 'No Requests',
                    subtitle: _getEmptySubtitle(),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final bool hasOffered = req.offers.any(
                      (o) => o.providerId == userId,
                    );

                    final bool isWinner =
                        req.status == 'confirmed' &&
                        req.confirmedProviderId == userId;

                    return RequestCard(
                      request: req,

                      // Accept only in New tab
                      onAccept:
                          (_selectedFilter == 'new')
                              ? () => _acceptRequest(req)
                              : null,

                      // Decline only in New tab
                      onDecline:
                          (_selectedFilter == 'new')
                              ? () => _firestore
                                  .collection('emergency_requests')
                                  .doc(req.id)
                                  .update({
                                    'declinedBy': FieldValue.arrayUnion([
                                      userId,
                                    ]),
                                  })
                              : null,

                      // Verify only if confirmed winner
                      onVerify:
                          (req.status == 'confirmed' &&
                                  req.confirmedProviderId == userId)
                              ? (code) async {
                                final handshakeService = HandshakeService();

                                final result = await handshakeService
                                    .verifyAndCompleteRequest(
                                      requestId: req.id,
                                      providerInputCode: code,
                                    );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor:
                                        result['success']
                                            ? Colors.green
                                            : Colors.red,
                                  ),
                                );

                                if (result['success']) {
                                  setState(() {
                                    _selectedFilter = 'history';
                                  });
                                }
                              }
                              : null,
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

  // --- UI Components ---

  Widget _buildFilterTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildChoiceChip('New Requests', 'new'),
          _buildChoiceChip('My Offers', 'my_offers'),
          _buildChoiceChip('History', 'history'),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String label, String value) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedFilter == value,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = value);
        }
      },
      selectedColor: Colors.green.withOpacity(0.2),
      labelStyle: TextStyle(
        color: _selectedFilter == value ? Color(0xFF00897B) : Color(0xFF00897B),
        fontWeight:
            _selectedFilter == value ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildTimeChip(String label, String value) {
    final isSelected = _selectedTimeFilter == value;
    return InkWell(
      onTap: () => setState(() => _selectedTimeFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF00897B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Color(0xFF00897B) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Methods ---

  bool _matchesTimeFilter(DateTime timestamp) {
    final now = DateTime.now();

    switch (_selectedTimeFilter) {
      case 'today':
        return timestamp.year == now.year &&
            timestamp.month == now.month &&
            timestamp.day == now.day;

      case 'week':
        final weekAgo = now.subtract(const Duration(days: 7));
        return timestamp.isAfter(weekAgo);

      case 'all':
      default:
        return true;
    }
  }

  String _getEmptySubtitle() {
    switch (_selectedFilter) {
      case 'new':
        return "New emergency requests will appear here";
      case 'my_offers':
        return "Requests you've offered for will appear here";
      case 'history':
        return "All your past requests will appear here";
      default:
        return "No requests found";
    }
  }

  Future<void> _signOut(BuildContext context) async {
    try {
      print("👋 Signing out from ServiceSelectionScreen...");
      await AuthService().signOut();

      if (context.mounted) {
        print("→ Navigating to home screen");
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/',
              (route) => false,
        );
      }
    } catch (e) {
      print("❌ Sign out error: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } }
