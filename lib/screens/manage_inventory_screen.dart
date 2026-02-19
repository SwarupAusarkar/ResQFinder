import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';
import 'add_inventory_item_screen.dart';

class ManageInventoryScreen extends StatefulWidget {
  const ManageInventoryScreen({super.key});
  @override
  State<ManageInventoryScreen> createState() => _ManageInventoryScreenState();
}

class _ManageInventoryScreenState extends State<ManageInventoryScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FIX: Using 'providers' collection
  Future<void> _updateInventory(List<Map<String, dynamic>> newInventory) async {
    final user = _authService.currentUser;
    if (user != null) {
      await _firestore.collection('providers').doc(user.uid).update({'inventory': newInventory});
    }
  }

  // Helper to change quantity
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

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text("Login required")));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage Inventory'), backgroundColor: Colors.green),
      body: StreamBuilder<DocumentSnapshot>(
        // FIX: Listening to 'providers' collection
        stream: _firestore.collection('providers').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final data = snapshot.data!.data() as Map<String, dynamic>?;
          // If inventory is missing, start with empty list
          final inventory = (data?['inventory'] as List<dynamic>? ?? [])
              .map((item) => InventoryItem.fromMap(item as Map<String, dynamic>))
              .toList();
          
          inventory.sort((a, b) => a.name.compareTo(b.name));

          if (inventory.isEmpty) {
            return Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text("Add Your First Item"),
                onPressed: () => _navigateToAdd(inventory),
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
                child: ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${item.quantity} ${item.unit}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _updateQuantity(item, -1, inventory),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle, color: Colors.green),
                        onPressed: () => _updateQuantity(item, 1, inventory),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.grey),
                        onPressed: () {
                          inventory.removeAt(index);
                          _updateInventory(inventory.map((e) => e.toMap()).toList());
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Fetch current list to pass to next screen
          _firestore.collection('providers').doc(user.uid).get().then((doc) {
             final data = doc.data() as Map<String, dynamic>? ?? {};
             final currentInv = (data['inventory'] as List? ?? []).map((e) => InventoryItem.fromMap(e)).toList();
             _navigateToAdd(currentInv);
          });
        },
      ),
    );
  }

  void _navigateToAdd(List<InventoryItem> current) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddInventoryItemScreen(currentInventory: current)));
  }
}