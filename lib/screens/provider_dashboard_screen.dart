import 'package:flutter/material.dart';
import '../models/request_model.dart';
import '../data/data_service.dart';
import '../services/auth_service.dart';
import 'provider_profile_edit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Provider dashboard showing incoming emergency requests
class ProviderDashboardScreen extends StatefulWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  ProviderDashboardScreen({super.key});

  @override
  State<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends State<ProviderDashboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<EmergencyRequest> _requests = [];
  bool _isLoading = true;
  String _selectedFilter = 'all'; // all, pending, accepted, declined

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  // Load emergency requests from data service
  Future<void> _loadRequests() async {
    try {
      final requests = await DataService.loadRequests();
      
      if (mounted) {
        setState(() {
          _requests = requests;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to load requests: $e');
      }
    }
  }

  // Add after _loadRequests() method:

  Future<void> _toggleAvailability() async {
    final user = AuthService().currentUser;
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
    ).then((_) => _loadRequests()); // Refresh after editing
  }

  // Filter requests based on selected filter
  List<EmergencyRequest> get _filteredRequests {
    if (_selectedFilter == 'all') {
      return _requests;
    }
    return _requests.where((request) => request.status == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
  // Add availability toggle
          FutureBuilder<DocumentSnapshot>(
            future: _firestore.collection('users').doc(AuthService().currentUser?.uid).get(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final isAvailable = snapshot.data?.data() as Map?;
              final available = isAvailable?['isAvailable'] ?? true;
              
              return IconButton(
                icon: Icon(available ? Icons.visibility : Icons.visibility_off),
                tooltip: available ? 'Available' : 'Unavailable',
                onPressed: _toggleAvailability,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editProfile,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRequests,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Dashboard stats
          _buildStatsSection(),
          
          // Filter tabs
          _buildFilterTabs(),
          
          // Requests list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _loadRequests,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredRequests.length,
                          itemBuilder: (context, index) {
                            final request = _filteredRequests[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildRequestCard(request),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // Build dashboard statistics section
  Widget _buildStatsSection() {
    final pendingCount = _requests.where((r) => r.status == 'pending').length;
    final acceptedCount = _requests.where((r) => r.status == 'accepted').length;
    final totalCount = _requests.length;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Requests',
              totalCount.toString(),
              Icons.all_inbox,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pending',
              pendingCount.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Accepted',
              acceptedCount.toString(),
              Icons.check_circle,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  // Build individual stat card
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Build filter tabs
  Widget _buildFilterTabs() {
    final filters = [
      {'key': 'all', 'label': 'All'},
      {'key': 'pending', 'label': 'Pending'},
      {'key': 'accepted', 'label': 'Accepted'},
      {'key': 'declined', 'label': 'Declined'},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['key'];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: FilterChip(
                label: Text(filter['label']!),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter['key']!;
                  });
                },
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Build request card
  Widget _buildRequestCard(EmergencyRequest request) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Service type icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: request.priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    request.serviceIcon,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Request info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.requesterName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.serviceType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: request.priorityColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    request.priority.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Description
            Text(
              request.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            
            // Location and time info
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.address,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.access_time,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  _getTimeAgo(request.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Contact info
            Row(
              children: [
                Icon(
                  Icons.phone,
                  size: 14,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 4),
                Text(
                  request.requesterPhone,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(request.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(request.status).withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    request.status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(request.status),
                    ),
                  ),
                ),
              ],
            ),
            
            // Action buttons (only show for pending requests)
            if (request.status == 'pending') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRequestAction(request, 'declined'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleRequestAction(request, 'accepted'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Accept'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            
            // Additional actions for accepted requests
            if (request.status == 'accepted') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _callRequester(request),
                      icon: const Icon(Icons.phone, size: 16),
                      label: const Text('Call Requester'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showLocationDialog(request),
                      icon: const Icon(Icons.map, size: 16),
                      label: const Text('View Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
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

  // Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter == 'all' 
                  ? 'No requests available'
                  : 'No ${_selectedFilter} requests',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == 'all'
                  ? 'Emergency requests will appear here when received'
                  : 'Try switching to a different filter',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadRequests,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  // Handle request action (accept/decline)
  void _handleRequestAction(EmergencyRequest request, String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action == 'accepted' ? 'Accept' : 'Decline'} Request'),
        content: Text(
          'Are you sure you want to ${action == 'accepted' ? 'accept' : 'decline'} '
          'this emergency request from ${request.requesterName}?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateRequestStatus(request, action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'accepted' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action == 'accepted' ? 'Accept' : 'Decline'),
          ),
        ],
      ),
    );
  }

  // Update request status (mock implementation)
  void _updateRequestStatus(EmergencyRequest request, String newStatus) {
    setState(() {
      final index = _requests.indexWhere((r) => r.id == request.id);
      if (index != -1) {
        // In a real app, this would update the backend
        // For demo purposes, we'll just update locally
        _requests[index] = EmergencyRequest(
          id: request.id,
          requesterName: request.requesterName,
          requesterPhone: request.requesterPhone,
          serviceType: request.serviceType,
          description: request.description,
          latitude: request.latitude,
          longitude: request.longitude,
          address: request.address,
          timestamp: request.timestamp,
          status: newStatus,
          priority: request.priority,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Request ${newStatus} successfully'),
        backgroundColor: newStatus == 'accepted' ? Colors.green : Colors.red,
      ),
    );
  }

  // Call requester (mock implementation)
  void _callRequester(EmergencyRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Call Requester'),
        content: Text(
          'Call ${request.requesterName} at ${request.requesterPhone}?\n\n'
          'This is a demo app - no actual call will be made.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling ${request.requesterName}...')),
              );
            },
            child: const Text('Call'),
          ),
        ],
      ),
    );
  }

  // Show location dialog
  void _showLocationDialog(EmergencyRequest request) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Request Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Address: ${request.address}'),
            const SizedBox(height: 8),
            Text('Coordinates: ${request.latitude.toStringAsFixed(4)}, ${request.longitude.toStringAsFixed(4)}'),
            const SizedBox(height: 16),
            const Text(
              'In a real app, this would open navigation to the location.',
              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // In a real app, this would open maps/navigation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening navigation...')),
              );
            },
            child: const Text('Navigate'),
          ),
        ],
      ),
    );
  }

  // Get status color
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'accepted':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Get time ago string
  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Show error message
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: _loadRequests,
        ),
      ),
    );
  }
}