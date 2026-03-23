import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../data/master_inventory_list.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class SendRequestScreen extends StatefulWidget {
  final InventoryItem? inventoryItem;
  const SendRequestScreen({super.key, this.inventoryItem});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _selectedItem;
  String? _selectedUnit;
  double _searchRadius = 5.0;
  bool _isSending = false;
  double lat = 0.0, long = 0.0;
  String loc = "";

  @override
  void initState() {
    super.initState();
    _initLocation();

    // Null-safe pre-fill if navigating from inventory
    if (widget.inventoryItem != null) {
      _selectedItem = widget.inventoryItem?.name;
      _selectedUnit = widget.inventoryItem?.unit;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() {
        lat = pos.latitude;
        long = pos.longitude;
      });

      final address = await LocationService.getAddressFromLatLng(lat, long);
      if (mounted && address != null) {
        setState(() => loc = address);
      }
    }
  }

  void _onResourceChanged(String? newValue) {
    if (newValue == null) return;

    // Find unit from master list based on name
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
    // 1. Logic Guard: Ensure resource is selected
    if (_selectedItem == null) {
      _showSnackBar("Please select a resource type", Colors.orange);
      return;
    }

    // 2. Logic Guard: Form validation
    if (!_formKey.currentState!.validate()) return;

    // 3. Logic Guard: Location check
    if (lat == 0.0) {
      await _initLocation();
      if (!mounted) return;
      if (lat == 0.0) {
        _showSnackBar("GPS Location required for SOS", Colors.red);
        return;
      }
    }

    setState(() => _isSending = true);

    try {
      final user = _authService.currentUser;
      if (user == null) throw "User session expired. Please log in.";

      // 4. Data Guard: Safely fetch user data across collections
      final userDoc = await _authService.getUserData(user.uid);
      if (!mounted) return;

      final Map<String, dynamic> userData = userDoc?.data() as Map<String, dynamic>? ?? {};
      final String requesterName = userData['fullName'] ?? userData['name'] ?? 'Anonymous';
      final String requesterPhone = userData['phone'] ?? 'N/A';

      // 5. Build and Push Payload
      await FirebaseFirestore.instance.collection('emergency_requests').add({
        'masterRequestId': const Uuid().v4(),
        'requesterId': user.uid,
        'requesterName': requesterName,
        'requesterPhone': requesterPhone,
        'latitude': lat,
        'longitude': long,
        'locationName': loc,
        'itemName': _selectedItem,
        'itemQuantity': int.tryParse(_quantityController.text) ?? 1,
        'itemUnit': _selectedUnit ?? 'Units',
        'description': _descriptionController.text.trim(),
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
        'radius': _searchRadius,
        'declinedBy': [],
        'acceptedAt': null,
        'verificationCode': null,
        'offers': [],
        'confirmedProviderId': '',
      });

      if (mounted) {
        _showSnackBar("Emergency Alert Broadcasted!", const Color(0xFF00897B));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _showSnackBar("Failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Emergency Request',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle("Emergency Type"),
              const SizedBox(height: 12),
              _buildTypeChips(),
              const SizedBox(height: 28),

              _buildSectionTitle("Resource Details"),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                // FIX: Ensure _selectedItem actually exists in the list to prevent the crash
                value: (masterInventoryList.any((e) => e.name == _selectedItem))
                    ? _selectedItem
                    : null,
                isExpanded: true,
                decoration: _inputDecoration("Select Resource"),

                // FIX: Use .toSet() before .toList() if you have duplicate names in your master list
                items: masterInventoryList
                    .map((e) => e.name)
                    .toSet() // This removes duplicates automatically
                    .map((name) => DropdownMenuItem(
                  value: name,
                  child: Text(name),
                ))
                    .toList(),

                onChanged: _onResourceChanged,
                validator: (v) => v == null ? "Please select an item" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration("Quantity (${_selectedUnit ?? 'Units'})"),
                validator: (v) => (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle("Search Radius"),
                  Text("${_searchRadius.toStringAsFixed(1)} km",
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
                ],
              ),
              Slider(
                value: _searchRadius, min: 1, max: 20, divisions: 19,
                activeColor: const Color(0xFF00897B),
                inactiveColor: Colors.teal.withOpacity(0.1),
                onChanged: (v) => setState(() => _searchRadius = v),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle("Medical Notes / Urgency"),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration("Enter specific details or address clues..."),
              ),
              const SizedBox(height: 40),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Helper Methods ---

  Widget _buildTypeChips() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildEmergencyTypeChip(Icons.local_hospital, 'Medical', const Color(0xFF00897B), true),
        _buildEmergencyTypeChip(Icons.local_fire_department, 'Fire', Colors.orange, false),
        _buildEmergencyTypeChip(Icons.car_crash, 'Accident', Colors.red, false),
        _buildEmergencyTypeChip(Icons.security, 'Security', Colors.blue, false),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(colors: [Color(0xFF00897B), Color(0xFF00796B)]),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00897B).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isSending ? null : _sendBroadcastRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _isSending
            ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.podcasts, color: Colors.white),
            SizedBox(width: 12),
            Text("BROADCAST SOS", style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00897B), width: 1.5)),
    );
  }

  Widget _buildEmergencyTypeChip(IconData icon, String label, Color color, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isSelected ? color : Colors.grey[200]!, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: isSelected ? color : Colors.grey, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: color,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )
    );
  }
}