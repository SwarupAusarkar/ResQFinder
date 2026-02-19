import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../data/master_inventory_list.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class SendRequestScreen extends StatefulWidget {
  // Ignored inventoryItem for now to allow generic requests
  final InventoryItem? inventoryItem; 
  const SendRequestScreen({super.key, this.inventoryItem});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService(); // Use our robust service

  String? _selectedItem;
  String? _selectedUnit;
  double _searchRadius = 5.0; // Increased default radius
  bool _isSending = false;
  double lat = 0.0, long = 0.0;
  String loc = "";

  @override
  void initState() {
    super.initState();
    _initLocation();
    // Pre-fill if passed from inventory
    if (widget.inventoryItem != null) {
      _selectedItem = widget.inventoryItem!.name;
      _selectedUnit = widget.inventoryItem!.unit;
    }
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        lat = pos.latitude;
        long = pos.longitude;
      });
      // Optional: Get address string (can be slow, so await carefully)
      LocationService.getAddressFromLatLng(lat, long).then((address) {
        if (mounted) setState(() => loc = address);
      });
    }
  }

  void _onResourceChanged(String? newValue) {
    if (newValue == null) return;
    final foundItem = masterInventoryList.firstWhere(
      (item) => item.name == newValue,
      orElse: () => const MasterInventoryItem(name: '', unit: 'Units'),
    );
    setState(() {
      _selectedItem = newValue;
      _selectedUnit = foundItem.unit;
    });
  }

  Future<void> _sendBroadcastRequest() async {
    if (!_formKey.currentState!.validate() || _selectedItem == null) return;

    if (lat == 0.0) {
      await _initLocation();
      if (lat == 0.0) {
        _showSnackBar("Please enable GPS to send a request.", Colors.orange);
        return;
      }
    }

    setState(() => _isSending = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw Exception("User session expired.");

      // FIX: Use getUserData to find user across BOTH collections
      final userDoc = await _authService.getUserData(user.uid);
      final userData = userDoc?.data() as Map<String, dynamic>? ?? {};

      await FirebaseFirestore.instance.collection('emergency_requests').add({
        'masterRequestId': const Uuid().v4(),
        'requesterId': user.uid,
        'requesterName': userData['name'] ?? 'Unknown',
        'requesterPhone': userData['phone'] ?? 'N/A', // Crucial for contact
        'latitude': lat,
        'longitude': long,
        'locationName': loc,
        'itemName': _selectedItem,
        'itemQuantity': int.parse(_quantityController.text),
        'itemUnit': _selectedUnit,
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'radius': _searchRadius,
        'declinedBy': [],
        'acceptedAt': null,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request Broadcasted!'), backgroundColor: Colors.green)
        );
        Navigator.pop(context);
      }
    } catch (e) {
      _showSnackBar("Broadcast Failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ... (Keep existing build UI code, or I can paste full if needed) ...
  // Assuming you keep your existing build method, just ensure _sendBroadcastRequest is linked.
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast Emergency'), backgroundColor: Colors.redAccent),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
               DropdownButtonFormField<String>(
                value: _selectedItem,
                hint: const Text("Select Resource Needed"),
                isExpanded: true,
                items: masterInventoryList.map((e) => DropdownMenuItem(value: e.name, child: Text(e.name))).toList(),
                onChanged: _onResourceChanged,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Quantity needed (${_selectedUnit ?? 'Units'})", border: const OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? "Required" : null,
              ),
              const SizedBox(height: 16),
              Text("Search Radius: ${_searchRadius.toStringAsFixed(1)} km"),
              Slider(
                value: _searchRadius, min: 1, max: 20, divisions: 19,
                label: "${_searchRadius.toStringAsFixed(1)} km",
                onChanged: (v) => setState(() => _searchRadius = v),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: "Medical Details / Urgency", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSending ? null : _sendBroadcastRequest,
                  icon: _isSending ? const SizedBox() : const Icon(Icons.podcasts),
                  label: Text(_isSending ? "Broadcasting..." : "SEND EMERGENCY ALERT"),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }
}