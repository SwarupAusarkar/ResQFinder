import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../models/inventory_item_model.dart';

class InventoryBottomSheet extends StatefulWidget {
  const InventoryBottomSheet({super.key});

  @override
  State<InventoryBottomSheet> createState() => _InventoryBottomSheetState();
}

class _InventoryBottomSheetState extends State<InventoryBottomSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final userId = _authService.currentUser?.uid;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle Bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00897B).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.inventory_outlined,
                    color: Color(0xFF00897B),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'INVENTORY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Manage your stock',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 24),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey[100],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Inventory List
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('users')
                  .doc(userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "Error loading inventory",
                      style: TextStyle(color: Colors.red[300]),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFF00897B)),
                    ),
                  );
                }

                final data = snapshot.data?.data() as Map<String, dynamic>?;
                final inventoryList = data?['inventory'] as List<dynamic>? ?? [];

                if (inventoryList.isEmpty) {
                  return _buildEmptyState();
                }

                final items = inventoryList
                    .map((item) => InventoryItem.fromMap(item))
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return _buildInventoryCard(items[index], userId!);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryCard(InventoryItem item, String userId) {
    final isLow = item.quantity < 5;
    final isCritical = item.quantity == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCritical
            ? Colors.red[50]
            : isLow
            ? Colors.orange[50]
            : Colors.green[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCritical
              ? Colors.red[200]!
              : isLow
              ? Colors.orange[200]!
              : Colors.green[200]!,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCritical
                      ? Colors.red[100]
                      : isLow
                      ? Colors.orange[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getItemIcon(item.name),
                  color: isCritical
                      ? Colors.red[700]
                      : isLow
                      ? Colors.orange[700]
                      : Colors.green[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),

              // Name & Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isCritical
                      ? Colors.red[100]
                      : isLow
                      ? Colors.orange[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isCritical
                      ? 'OUT OF STOCK'
                      : isLow
                      ? 'LOW'
                      : 'AVAILABLE',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isCritical
                        ? Colors.red[900]
                        : isLow
                        ? Colors.orange[900]
                        : Colors.green[900],
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity Display
          Row(
            children: [
              Text(
                'Quantity:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${item.quantity} ${item.unit}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isCritical
                      ? Colors.red[700]
                      : isLow
                      ? Colors.orange[700]
                      : Colors.green[700],
                ),
              ),
              const Spacer(),

              // Quick Actions
              Row(
                children: [
                  _buildQuickButton(
                    icon: Icons.remove,
                    onPressed: item.quantity > 0
                        ? () => _updateQuantity(userId, item, -1)
                        : null,
                  ),
                  const SizedBox(width: 8),
                  _buildQuickButton(
                    icon: Icons.add,
                    onPressed: () => _updateQuantity(userId, item, 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: onPressed != null
              ? const Color(0xFF00897B).withOpacity(0.1)
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onPressed != null
                ? const Color(0xFF00897B)
                : Colors.grey[400]!,
          ),
        ),
        child: Icon(
          icon,
          size: 20,
          color: onPressed != null ? const Color(0xFF00897B) : Colors.grey,
        ),
      ),
    );
  }

  Future<void> _updateQuantity(
      String userId,
      InventoryItem item,
      int change,
      ) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final data = userDoc.data() as Map<String, dynamic>;
      final inventoryList = List<Map<String, dynamic>>.from(
        data['inventory'] ?? [],
      );

      // Find and update the item
      final index = inventoryList.indexWhere((i) => i['name'] == item.name);
      if (index != -1) {
        final newQuantity = (inventoryList[index]['quantity'] + change)
            .clamp(0, 9999);
        inventoryList[index]['quantity'] = newQuantity;

        await _firestore.collection('users').doc(userId).update({
          'inventory': inventoryList,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating inventory: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getItemIcon(String name) {
    final lowerName = name.toLowerCase();
    if (lowerName.contains('blood')) return Icons.bloodtype;
    if (lowerName.contains('oxygen')) return Icons.air;
    if (lowerName.contains('bed')) return Icons.bed;
    if (lowerName.contains('ambulance')) return Icons.local_hospital;
    if (lowerName.contains('medicine') || lowerName.contains('drug')) {
      return Icons.medication;
    }
    return Icons.inventory_2;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_outlined,
                size: 80, color: Colors.grey[300]),
            const SizedBox(height: 20),
            Text(
              'No Inventory Items',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items to track your stock',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Navigate to add inventory screen
                Navigator.pop(context);
              },
              icon: const Icon(Icons.add),
              label: const Text('ADD ITEMS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00897B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}