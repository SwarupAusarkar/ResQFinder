import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/RequestOffer.dart' show RequestOffer;
import '../models/request_model.dart';
import '../services/auth_service.dart';
import '../widgets/requestCard.dart';
import 'provider_profile_edit_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String _selectedFilter = 'new';
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

        // Check if already taken
        if (data['acceptedBy'] != null) throw "Someone else was already accepted";

        // Check if already offered
        final List offers = data['offers'] ?? [];
        if (offers.any((o) => o['providerId'] == providerId)) throw "Offer already sent";

        // Get Provider Info for the offer
        final pSnap = await _firestore.collection('users').doc(providerId).get();
        final pData = pSnap.data() ?? {};

        final newOffer = RequestOffer(
          providerId: providerId,
          providerName: pData['fullName'] ?? "Provider",
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
          const SnackBar(content: Text("Offer Sent! Waiting for citizen approval."), backgroundColor: Colors.green),
        );
        setState(() => _selectedFilter = 'my_offers');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showVerifyDialog(EmergencyRequest request) {
    final TextEditingController otpController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false, // Don't dismiss on outside tap
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.pin, color: Colors.orange),
            SizedBox(width: 8),
            Text("Verification Code"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Ask the requester for their 4-digit verification code:",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              autofocus: true,
              style: const TextStyle(
                fontSize: 36,
                letterSpacing: 16,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                hintText: "0000",
                counterText: "",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.green, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "The code is displayed on the requester's screen",
                      style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              otpController.dispose();
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              if (otpController.text.length == 4) {
                _processVerification(request, otpController.text);
                otpController.dispose();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please enter a 4-digit code"),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            icon: const Icon(Icons.check_circle),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            label: const Text("Verify & Complete"),
          ),
        ],
      ),
    );
  }

  Future<void> _processVerification(
      EmergencyRequest request, String inputCode) async {
    if (inputCode.trim() == request.verificationCode?.trim()) {
      try {
        await _firestore.collection('emergency_requests').doc(request.id).update({
          'status': 'completed',
          'completedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context); // Close dialog

          // Show success
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration, size: 64, color: Colors.green),
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
                    backgroundColor: Colors.green,
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
    if (user == null) return const Scaffold(body: Center(child: Text("Login Required")));

    return Scaffold(
        appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Colors.green,
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProviderProfileEditScreen()))),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => _authService.signOut()),
        ],
      ),
    body: Column(
        children: [
          _buildFilterTabs(),
          if (_isProcessing) const LinearProgressIndicator(color: Colors.green),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('emergency_requests')
                  .where('status', whereIn: ['pending', 'confirmed'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final userId = user.uid;
                var requests = snapshot.data!.docs.map((doc) => EmergencyRequest.fromFirestore(doc)).where((req) {
                  // 1. Identify if I am involved
                  bool hasOffered = req.offers.any((o) => o.providerId == userId);
                  bool notDeclined = !req.declinedBy.contains(userId);
                  if (!notDeclined) return false;

                  // 2. Tab Logic: Move from New -> My Offers after sending
                  if (_selectedFilter == 'new') {
                    // Only show if it's open AND I haven't offered yet
                    return req.status == 'pending' && !hasOffered;
                  } else if (_selectedFilter == 'my_offers') {
                    // Show if I have offered (whether waiting, confirmed, or rejected)
                    return hasOffered;
                  }
                  return true; // History
                }).toList();

                requests = requests.where((r) => _matchesTimeFilter(r.timestamp)).toList();
                requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                if (requests.isEmpty) return _buildEmptyState(icon: Icons.search_off, title: 'No Requests', subtitle: _getEmptySubtitle());

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final bool hasOffered = req.offers.any((o) => o.providerId == userId);

                    // Logic fix: Ensure we check both potential field names for the winner
                    final bool isWinner = req.status == 'confirmed' &&
                        (req.confirmedProviderId == userId || req.confirmedProviderId == userId);

                    return RequestCard(
                      request: req,
                      onAccept: (!hasOffered && req.status == 'pending') ? () => _acceptRequest(req) : null,
                      onDecline: hasOffered ? null : () => _firestore.collection('emergency_requests').doc(req.id).update({
                        'declinedBy': FieldValue.arrayUnion([userId])
                      }),
                      onVerify: (String enteredCode) async {
                        if (enteredCode == req.verificationCode) {
                          try {
                            await _firestore.collection('emergency_requests').doc(req.id).update({
                              'status': 'completed',
                              'completedAt': FieldValue.serverTimestamp(),
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Handshake Successful! Request Completed."), backgroundColor: Colors.green),
                            );
                          } catch (e) {
                            debugPrint("Error completing request: $e");
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Invalid Code. Please check and try again."), backgroundColor: Colors.red),
                          );
                        }
                      },
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
        color: _selectedFilter == value ? Colors.green : Colors.grey[700],
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
          color: isSelected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
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
  } }
