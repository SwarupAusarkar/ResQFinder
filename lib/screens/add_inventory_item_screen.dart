// lib/screens/add_inventory_item_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/master_inventory_list.dart';
import '../models/inventory_item_model.dart';
import '../services/auth_service.dart';

class AddInventoryItemScreen extends StatefulWidget {
  final List<InventoryItem> currentInventory;

  const AddInventoryItemScreen({super.key, required this.currentInventory});

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final List<InventoryItem> _itemsToAdd = [];

  @override
  Widget build(BuildContext context) {
    // Get a list of names of items already in the provider's inventory
    final currentItemNames = widget.currentInventory.map((item) => item.name).toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add from Master List'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: masterInventoryList.length,
        itemBuilder: (context, index) {
          final masterItem = masterInventoryList[index];
          final isAlreadyAdded = currentItemNames.contains(masterItem.name);
          final isSelected = _itemsToAdd.any((item) => item.name == masterItem.name);

          return CheckboxListTile(
            title: Text(masterItem.name),
            subtitle: Text('Unit: ${masterItem.unit}'),
            value: isSelected,
            // Disable the checkbox if the item is already in the provider's inventory
            onChanged: isAlreadyAdded
                ? null
                : (bool? value) {
                    setState(() {
                      if (value == true) {
                        _itemsToAdd.add(InventoryItem(
                          name: masterItem.name,
                          quantity: 0, // Default quantity is 0
                          unit: masterItem.unit,
                          lastUpdated: DateTime.now(),
                        ));
                      } else {
                        _itemsToAdd.removeWhere((item) => item.name == masterItem.name);
                      }
                    });
                  },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _itemsToAdd.isEmpty ? null : _saveSelection,
        backgroundColor: _itemsToAdd.isEmpty ? Colors.grey : Colors.green,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Add Selected (${_itemsToAdd.length})', style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Future<void> _saveSelection() async {
    final user = _authService.currentUser;
    if (user == null) return;

    // Combine the new items with the existing inventory
    final updatedInventory = [...widget.currentInventory, ..._itemsToAdd];

    try {
      await _firestore.collection('users').doc(user.uid).update({
        'inventory': updatedInventory.map((item) => item.toMap()).toList(),
      });

      if (mounted) {
        Navigator.pop(context); // Go back to the manage inventory screen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add items: $e')),
        );
      }
    }
  }
}