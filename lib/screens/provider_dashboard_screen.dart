import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/request_model.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';
import '../widgets/requestCard.dart';
import 'provider_profile_edit_screen.dart';

class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() =>
      _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String _selectedFilter =
      'pending';

  Future<void> _acceptRequest(EmergencyRequest request) async {
    final providerId = _authService.currentUser?.uid;
    if (providerId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. ALL READS FIRST
        final requestRef = _firestore
            .collection('emergency_requests')
            .doc(request.id);
        final providerRef = _firestore.collection('users').doc(providerId);

        final requestSnap = await transaction.get(requestRef);
        final providerSnap = await transaction.get(providerRef);

        // Query related broadcast instances
        final relatedQuery = _firestore
            .collection('emergency_requests')
            .where('masterRequestId', isEqualTo: request.masterRequestId);
        final relatedSnap = await relatedQuery.get();

        // 2. VALIDATION
        if (requestSnap.data()?['status'] == 'accepted') {
          throw Exception('Already accepted by another provider.');
        }

        final providerData = providerSnap.data() as Map<String, dynamic>?;
        final inventory =
            (providerData?['inventory'] as List? ?? [])
                .map((item) => InventoryItem.fromMap(item))
                .toList();

        final itemIndex = inventory.indexWhere(
          (item) => item.name == request.itemName,
        );
        if (itemIndex == -1 ||
            inventory[itemIndex].quantity < request.itemQuantity) {
          throw Exception('Insufficient inventory.');
        }

        // 3. ALL WRITES LAST
        // Update the request being accepted
        transaction.update(requestRef, {
          'status': 'accepted',
          'acceptedBy': providerId,
          'acceptedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(providerRef, {
          'inventory': inventory.map((e) => e.toMap()).toList(),
          'noOfApprovedRequests': FieldValue.increment(1),
        });
        // Cancel other broadcast segments
        for (var doc in relatedSnap.docs) {
          if (doc.id != request.id && doc.data()['status'] == 'pending') {
            transaction.update(doc.reference, {
              'status': 'cancelled_by_system',
            });
          }
        }
      });
      print('Request accepted!');
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> _declineRequest(EmergencyRequest request) async {
    final providerId = _authService.currentUser?.uid;
    if (providerId == null) return;

    try {
      await _firestore.collection('emergency_requests').doc(request.id).update({
        'declinedBy': FieldValue.arrayUnion([providerId]),
      });
      print('Request hidden.');
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _toggleAvailability() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final currentDoc =
          await _firestore.collection('users').doc(user.uid).get();
      final currentStatus = currentDoc.data()?['isAvailable'] ?? true;

      await _firestore.collection('users').doc(user.uid).update({
        'isAvailable': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status updated to ${!currentStatus ? "Available" : "Unavailable"}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
      }
    }
  }

  Future<void> _editProfile() async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProviderProfileEditScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not logged in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final isAvailable = data?['isAvailable'] ?? true;

              return IconButton(
                icon: Icon(
                  isAvailable ? Icons.visibility : Icons.visibility_off,
                ),
                tooltip:
                    isAvailable ? 'Set to Unavailable' : 'Set to Available',
                onPressed: _toggleAvailability,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory),
            onPressed: () => Navigator.pushNamed(context, '/manage-inventory'),
            tooltip: 'Manage Inventory',
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: _firestore.collection('users').doc(user.uid).get(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;
                final bool isAvailable = userData['isAvailable'] ?? true;

                // 🚫 If provider is unavailable, show empty state immediately
                if (!isAvailable) {
                  return _buildEmptyState();
                }

                final double myLat =
                    (userData['latitude'] as num?)?.toDouble() ?? 0.0;
                final double myLon =
                    (userData['longitude'] as num?)?.toDouble() ?? 0.0;
                const double radiusDegrees = 0.0135; // ~1.5km

                // Provider inventory
                final inventory =
                    (userData['inventory'] as List<dynamic>? ?? [])
                        .map(
                          (item) => InventoryItem.fromMap(
                            item as Map<String, dynamic>,
                          ),
                        )
                        .toList();

                return StreamBuilder<QuerySnapshot>(
                  stream:
                      _selectedFilter == 'all'

                          ? _firestore
                              .collection('emergency_requests')
                              .where(
                                'latitude',
                                isGreaterThanOrEqualTo: myLat - radiusDegrees,
                              )
                              .where(
                                'latitude',
                                isLessThanOrEqualTo: myLat + radiusDegrees,
                              )
                              .snapshots()
                          : _firestore
                              .collection('emergency_requests')
                              .where('status', isEqualTo: _selectedFilter)
                              .where(
                                'latitude',
                                isGreaterThanOrEqualTo: myLat - radiusDegrees,
                              )
                              .where(
                                'latitude',
                                isLessThanOrEqualTo: myLat + radiusDegrees,
                              )
                              .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Filter requests by longitude AND inventory availability
                    final requests =
                        snapshot.data!.docs
                            .map((doc) => EmergencyRequest.fromFirestore(doc))
                            .where(
                              (req) =>
                                  req.longitude >= (myLon - radiusDegrees) &&
                                  req.longitude <= (myLon + radiusDegrees) &&
                                  _hasEnoughInventory(inventory, req),
                            )
                            .toList();

                    requests.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                    if (requests.isEmpty) return _buildEmptyState();

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: requests.length,
                      // itemBuilder: (context, index) =>
                      //     _buildRequestCard(requests[index]),
                      itemBuilder:
                          (context, index) => RequestCard(
                            request: requests[index],
                            onAccept: () => _acceptRequest(requests[index]),
                            onDecline: () => _declineRequest(requests[index]),
                            onVerify: () {},
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

  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'pending', 'label': 'Pending'}, // Shows broadcast requests
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'declined', 'label': 'Declined'},
      {'key': 'all', 'label': 'All'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children:
            filters.map((filter) {
              final isSelected = _selectedFilter == filter['key'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(
                      filter['label']!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedFilter = filter['key']!;
                        });
                      }
                    },
                    selectedColor: Colors.green.withOpacity(0.3),
                    backgroundColor: Colors.white,
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildRequestCard(EmergencyRequest request) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${request.itemQuantity} ${request.itemUnit} of ${request.itemName}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'From: ${request.requesterName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                      ),
                      if (request.requesterPhone.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Phone: ${request.requesterPhone}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (request.description.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.2)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.emergency, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        request.description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  _formatDateTime(request.timestamp),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _declineRequest(request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptRequest(request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
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
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No $_selectedFilter requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'pending'
                  ? 'Broadcast emergency requests from nearby users will appear here.'
                  : 'Requests you\'ve ${_selectedFilter == 'all' ? 'interacted with' : _selectedFilter} will appear here.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  bool _hasEnoughInventory(
    List<InventoryItem> inventory,
    EmergencyRequest req,
  ) {
    final item = inventory.firstWhere(
      (inv) => inv.name == req.itemName,
      orElse:
          () => InventoryItem(
            name: '',
            quantity: 0,
            unit: '',
            lastUpdated: DateTime.now(),
          ),
    );
    return item.name.isNotEmpty && item.quantity >= req.itemQuantity;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
  }
}
