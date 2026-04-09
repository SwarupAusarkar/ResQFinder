// lib/widgets/inventory_item_card.dart
import 'package:flutter/material.dart';

class InventoryItemCard extends StatelessWidget {
  final String title;
  final int quantity;
  final String unit;
  final String lastUpdated;
  final bool isCritical; // If quantity is 0
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const InventoryItemCard({
    super.key,
    required this.title,
    required this.quantity,
    required this.unit,
    required this.lastUpdated,
    this.isCritical = false,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Side Indicator Bar
              Container(width: 6, color: isCritical ? Colors.red : Colors.green),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_services_outlined, color: isCritical ? Colors.red : Colors.green[700], size: 20),
                              const SizedBox(width: 8),
                              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ],
                          ),
                          if (isCritical)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.indigo[900], borderRadius: BorderRadius.circular(6)),
                              child: const Text("CRITICAL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text("Updated: $lastUpdated", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildQtyBtn(Icons.remove, onRemove),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              children: [
                                Text("$quantity", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                                Text(unit.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.grey, letterSpacing: 1.2)),
                              ],
                            ),
                          ),
                          _buildQtyBtn(Icons.add, onAdd),
                          const Spacer(),
                          IconButton(onPressed: onDelete, icon: const Icon(Icons.delete_outline, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQtyBtn(IconData icon, VoidCallback tap) {
    return InkWell(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 20, color: Colors.indigo[900]),
      ),
    );
  }
}