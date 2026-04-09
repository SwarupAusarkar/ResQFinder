// lib/widgets/master_list_picker.dart
import 'package:flutter/material.dart';
import '../data/master_inventory_list.dart'; // Aapka existing master data
import '../models/inventory_item_model.dart';

class MasterListPicker extends StatefulWidget {
  final List<InventoryItem> currentInventory;
  final Function(List<InventoryItem>) onItemsAdded;

  const MasterListPicker({
    super.key,
    required this.currentInventory,
    required this.onItemsAdded
  });

  @override
  State<MasterListPicker> createState() => _MasterListPickerState();
}

class _MasterListPickerState extends State<MasterListPicker> {
  final List<InventoryItem> _tempSelected = [];
  String _query = "";

  @override
  Widget build(BuildContext context) {
    final currentNames = widget.currentInventory.map((e) => e.name).toSet();

    // Filter master list based on search and already added items
    final filteredMaster = masterInventoryList.where((m) =>
    m.name.toLowerCase().contains(_query.toLowerCase()) &&
        !currentNames.contains(m.name)
    ).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          const SizedBox(height: 20),
          const Text("Add New Resources", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),

          // Search in Modal
          TextField(
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: "Search categories...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: filteredMaster.length,
              itemBuilder: (context, index) {
                final item = filteredMaster[index];
                final isSelected = _tempSelected.any((s) => s.name == item.name);

                return CheckboxListTile(
                  activeColor: const Color(0xFF00695C),
                  title: Text(item.name),
                  subtitle: Text(item.unit),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _tempSelected.add(InventoryItem(
                            name: item.name,
                            quantity: 0,
                            unit: item.unit,
                            lastUpdated: DateTime.now()
                        ));
                      } else {
                        _tempSelected.removeWhere((s) => s.name == item.name);
                      }
                    });
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00695C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _tempSelected.isEmpty ? null : () {
                widget.onItemsAdded(_tempSelected);
                Navigator.pop(context);
              },
              child: Text("Add Selected (${_tempSelected.length})", style: const TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}