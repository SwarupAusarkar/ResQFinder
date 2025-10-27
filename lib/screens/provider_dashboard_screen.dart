// lib/screens/provider_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/request_model.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';
import 'provider_profile_edit_screen.dart';

// Provider dashboard showing incoming emergency requests
class ProviderDashboardScreen extends StatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  String _selectedFilter = 'pending'; // Default to pending to show active requests

  // ** START: MODIFICATION - NEW LIVE DATA LOGIC **

  // Securely accepts a request using a Firestore transaction to prevent race conditions.
  Future<void> _acceptRequest(EmergencyRequest request) async {
    final providerId = _authService.currentUser?.uid;
    if (providerId == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final relatedRequestsQuery = _firestore
            .collection('emergency_requests')
            .where('masterRequestId', isEqualTo: request.masterRequestId);
            
        final relatedRequestsSnapshot = await relatedRequestsQuery.get();

        if (relatedRequestsSnapshot.docs.any((doc) => doc.data()['status'] == 'accepted')) {
          throw Exception('This request has already been handled.');
        }

        transaction.update(_firestore.collection('emergency_requests').doc(request.id), {'status': 'accepted'});

        for (final doc in relatedRequestsSnapshot.docs) {
          if (doc.id != request.id && doc.data()['status'] == 'pending') {
            transaction.update(doc.reference, {'status': 'cancelled_by_system'});
          }
        }
        
        final providerDocRef = _firestore.collection('users').doc(providerId);
        final providerSnapshot = await transaction.get(providerDocRef);
        final providerData = providerSnapshot.data() as Map<String, dynamic>?;
        
        if (providerData != null) {
          final inventory = (providerData['inventory'] as List<dynamic>)
              .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
              .toList();
              
          final itemIndex = inventory.indexWhere((item) => item.name == request.itemName);
          if (itemIndex != -1) {
            final currentQuantity = inventory[itemIndex].quantity;
            if (currentQuantity >= request.itemQuantity) {
              inventory[itemIndex] = InventoryItem(
                name: inventory[itemIndex].name,
                quantity: currentQuantity - request.itemQuantity,
                unit: inventory[itemIndex].unit,
                lastUpdated: DateTime.now(),
              );

              final newInventoryMap = inventory.map((item) => item.toMap()).toList();
              final newInventorySearch = newInventoryMap.map((item) => item['name'] as String).toList();
              
              transaction.update(providerDocRef, {
                'inventory': newInventoryMap,
                'inventorySearch': newInventorySearch,
              });
            } else {
              throw Exception('Not enough inventory to fulfill this request.');
            }
          }
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request accepted!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // Declines a request.
  Future<void> _declineRequest(EmergencyRequest request) async {
    try {
      await _firestore.collection('emergency_requests').doc(request.id).update({'status': 'declined'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Request declined.'), backgroundColor: Colors.orange));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error declining request: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  // ** END: NEW LIVE DATA LOGIC **

  Future<void> _toggleAvailability() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final currentDoc = await _firestore.collection('users').doc(user.uid).get();
      final currentStatus = currentDoc.data()?['isAvailable'] ?? true;
      
      await _firestore.collection('users').doc(user.uid).update({
        'isAvailable': !currentStatus,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${!currentStatus ? "Available" : "Unavailable"}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
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
              // ** CORRECTED: Access data from DocumentSnapshot correctly **
              final data = snapshot.data?.data() as Map<String, dynamic>?;
              final isAvailable = data?['isAvailable'] ?? true;
              
              return IconButton(
                icon: Icon(isAvailable ? Icons.visibility : Icons.visibility_off),
                tooltip: isAvailable ? 'Set to Unavailable' : 'Set to Available',
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
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // _buildStatsSection(), // Preserving this, can be re-enabled later
          
          _buildFilterTabs(),
          
          // ** MODIFICATION: Replaced old logic with a live StreamBuilder **
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('emergency_requests')
                  .where('providerId', isEqualTo: user.uid)
                  .where('status', whereIn: _selectedFilter == 'all' ? ['pending', 'accepted', 'declined', 'cancelled_by_system'] : [_selectedFilter])
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                    return Center(child: Text("Error fetching requests: ${snapshot.error}"));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final requests = snapshot.data!.docs.map((doc) => EmergencyRequest.fromFirestore(doc)).toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildRequestCard(requests[index]),
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
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'declined', 'label': 'Declined'},
      {'key': 'all', 'label': 'All'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(filter['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedFilter = filter['key']!;
                    });
                  }
                },
                selectedColor: Colors.green.withOpacity(0.2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ** MODIFICATION: Updated card to use live data and new accept/decline methods **
  Widget _buildRequestCard(EmergencyRequest request) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        'Request: ${request.itemQuantity} ${request.itemUnit} of ${request.itemName}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text('From: ${request.requesterName}', style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.status.toUpperCase().replaceAll('_', ' '),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (request.description.isNotEmpty) ...[
              Text(request.description, style: TextStyle(fontSize: 14, color: Colors.grey[800])),
              const SizedBox(height: 12),
            ],
            Text('Time: ${_formatDateTime(request.timestamp)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _declineRequest(request),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _acceptRequest(request),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            const Text(
              'New requests from users will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}