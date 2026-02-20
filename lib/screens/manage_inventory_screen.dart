import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';
import 'add_inventory_item_screen.dart';
import 'package:intl/intl.dart'; // For date formatting

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  // FORMATTER: For the "Last Updated" text
  String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd MMM, hh:mm a').format(dateTime);
  }

  // CORE LOGIC: Update inventory in the 'providers' collection
  Future<void> _updateInventory(List<Map<String, dynamic>> newInventory) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not logged in.");

      // Fixed: Using 'providers' collection as per upstream fix
      await _firestore
          .collection('providers')
          .doc(user.uid)
          .update({'inventory': newInventory});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inventory updated!'),
            backgroundColor: Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // HELPER: Change quantity + or -
  Future<void> _updateQuantity(
      InventoryItem item, int change, List<InventoryItem> currentInventory) async {
    final newQuantity = item.quantity + change;
    if (newQuantity < 0) return;

    final index = currentInventory.indexWhere((i) => i.name == item.name);
    if (index != -1) {
      currentInventory[index] = InventoryItem(
        name: item.name,
        quantity: newQuantity,
        unit: item.unit,
        lastUpdated: DateTime.now(),
      );
      await _updateInventory(currentInventory.map((i) => i.toMap()).toList());
    }
  }

  // HELPER: Delete item
  Future<void> _removeItem(int index, List<InventoryItem> currentInventory) async {
    currentInventory.removeAt(index);
    await _updateInventory(currentInventory.map((i) => i.toMap()).toList());
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Login required")));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inventory'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // Listen to 'providers' collection
        stream: _firestore.collection('providers').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("No inventory data found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>?;
          final inventory = (data?['inventory'] as List<dynamic>? ?? [])
              .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
              .toList();

          inventory.sort((a, b) => a.name.compareTo(b.name));

          if (inventory.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B)),
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: const Text("Add Your First Item", style: TextStyle(color: Colors.white)),
                    onPressed: () => _navigateToAdd(inventory),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${item.quantity} ${item.unit}'),
                        Text(
                          'Updated: ${_formatDateTime(item.lastUpdated)}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                          onPressed: _isSubmitting ? null : () => _updateQuantity(item, -1, inventory),
                        ),
                        Text(
                          item.quantity.toString(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00897B)),
                          onPressed: _isSubmitting ? null : () => _updateQuantity(item, 1, inventory),
                        ),
                        const VerticalDivider(width: 10),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.grey),
                          onPressed: _isSubmitting ? null : () => _removeItem(index, inventory),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00897B),
        tooltip: 'Add New Item',
        onPressed: () {
          _firestore.collection('providers').doc(user.uid).get().then((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            final currentInv = (data['inventory'] as List? ?? [])
                .map((e) => InventoryItem.fromMap(e))
                .toList();
            _navigateToAdd(currentInv);
          });
        },
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _navigateToAdd(List<InventoryItem> current) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => AddInventoryItemScreen(currentInventory: current)));
  }
}