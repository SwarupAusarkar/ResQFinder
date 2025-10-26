// lib/models/inventory_item_model.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItem {
  final String name;
  final int quantity;
  final String unit;
  final DateTime lastUpdated;

  InventoryItem({
    required this.name,
    required this.quantity,
    required this.unit,
    required this.lastUpdated,
  });

  // Factory constructor to create an InventoryItem from a map
  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      name: map['name'] ?? '',
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? 'units',
      lastUpdated: (map['last_updated'] as Timestamp).toDate(),
    );
  }

  // Method to convert an InventoryItem to a map
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'last_updated': Timestamp.fromDate(lastUpdated),
    };
  }
}