// lib/screens/manage_inventory_screen.dart

import 'package:flutter/material.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'add_inventory_item_screen.dart'; // Import the new screen

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});

  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isSubmitting = false;

  Future<void> _updateInventory(List<Map<String, dynamic>> newInventory) async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User not logged in.");
      await _firestore.collection('users').doc(user.uid).update({'inventory': newInventory});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory updated!'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _updateQuantity(InventoryItem item, int change, List<InventoryItem> currentInventory) async {
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

  void _showEditDialog({required InventoryItem item, required List<InventoryItem> currentInventory}) {
    final quantityController = TextEditingController(text: item.quantity.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit: ${item.name}'),
          content: TextField(
            controller: quantityController,
            decoration: InputDecoration(labelText: 'Quantity', hintText: 'Enter new quantity'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final updatedInventory = currentInventory.where((i) => i.name != item.name).toList();
                await _updateInventory(updatedInventory.map((i) => i.toMap()).toList());
              },
              child: const Text('Delete Item', style: TextStyle(color: Colors.red)),
            ),
            const Spacer(),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final index = currentInventory.indexWhere((i) => i.name == item.name);
                if (index != -1) {
                  currentInventory[index] = InventoryItem(
                    name: item.name,
                    quantity: int.tryParse(quantityController.text) ?? item.quantity,
                    unit: item.unit,
                    lastUpdated: DateTime.now(),
                  );
                  Navigator.pop(context);
                  await _updateInventory(currentInventory.map((i) => i.toMap()).toList());
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text("User not found.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Inventory'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _firestore.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data?.data() == null) {
            return const Center(child: Text("No provider data found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final inventory = (data['inventory'] as List<dynamic>? ?? [])
              .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
              .toList();
          
          inventory.sort((a, b) => a.name.compareTo(b.name));

          if (inventory.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Your inventory is empty.\nTap the "+" button to add items from the master list.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 80),
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    subtitle: Text('Unit: ${item.unit}\nLast updated: ${_formatDateTime(item.lastUpdated)}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: _isSubmitting ? null : () => _updateQuantity(item, -1, inventory),
                        ),
                        Text(item.quantity.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        IconButton(
                          icon: const Icon(Icons.add_circle, color: Colors.green),
                          onPressed: _isSubmitting ? null : () => _updateQuantity(item, 1, inventory),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit, color: Colors.grey[600]),
                          onPressed: _isSubmitting ? null : () => _showEditDialog(item: item, currentInventory: inventory),
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
        onPressed: () {
          // Fetch the latest inventory and navigate to the add screen
          _firestore.collection('users').doc(user.uid).get().then((doc) {
            if (doc.exists) {
              final data = doc.data() as Map<String, dynamic>;
              final currentInventory = (data['inventory'] as List<dynamic>? ?? [])
                  .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
                  .toList();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AddInventoryItemScreen(currentInventory: currentInventory),
                ),
              );
            }
          });
        },
        backgroundColor: Colors.green,
        tooltip: 'Add New Item',
        child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  String _formatDateTime(DateTime dt) {
    return "${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
  }
}