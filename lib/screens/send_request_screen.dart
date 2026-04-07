// lib/screens/send_request_screen.dart
import 'package:emergency_res_loc_new/models/inventory_item_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../data/master_inventory_list.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../screens/SearchingProviderScreen.dart';

class SendRequestScreen extends StatefulWidget {
  final InventoryItem? inventoryItem;
  const SendRequestScreen({super.key, this.inventoryItem});

  @override
  State<SendRequestScreen> createState() => _SendRequestScreenState();
}

class _SendRequestScreenState extends State<SendRequestScreen> {
  // ── State (unchanged) ────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _recipientController = TextEditingController();
  final AuthService _authService = AuthService();

  String? _selectedItem;
  String? _selectedUnit;
  double _searchRadius = 5.0;
  bool _isSending = false;
  double lat = 0.0, long = 0.0;
  String loc = "";

  // Urgency: 0=Low, 1=Medium, 2=Critical
  int _urgencyLevel = 2;

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D4F4A);
  static const _tealLight = Color(0xFF0D9488);
  static const _bgColor = Color(0xFFEFF6F5);

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _initLocation();
    if (widget.inventoryItem != null) {
      _selectedItem = widget.inventoryItem?.name;
      _selectedUnit = widget.inventoryItem?.unit;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descriptionController.dispose();
    _recipientController.dispose();
    super.dispose();
  }

  // ── Logic (unchanged) ────────────────────────────────────────────────────────
  Future<void> _initLocation() async {
    final pos = await LocationService.getCurrentLocation();
    if (pos != null && mounted) {
      setState(() { lat = pos.latitude; long = pos.longitude; });
      final address = await LocationService.getAddressFromLatLng(lat, long);
      if (mounted && address != null) setState(() => loc = address);
    }
  }

  void _onResourceChanged(String? newValue) {
    if (newValue == null) return;
    final foundItem = masterInventoryList.firstWhere(
          (item) => item.name == newValue,
      orElse: () => const MasterInventoryItem(name: '', unit: 'Units'),
    );
    setState(() { _selectedItem = newValue; _selectedUnit = foundItem.unit; });
  }

  Future<void> _sendBroadcastRequest() async {
    if (_selectedItem == null) { _showSnackBar("Please select a resource type", Colors.orange); return; }
    if (!_formKey.currentState!.validate()) return;
    if (lat == 0.0) {
      await _initLocation();
      if (!mounted) return;
      if (lat == 0.0) { _showSnackBar("GPS Location required for SOS", Colors.red); return; }
    }

    setState(() => _isSending = true);
    try {
      final user = _authService.currentUser;
      if (user == null) throw "User session expired. Please log in.";
      final userDoc = await _authService.getUserData(user.uid);
      if (!mounted) return;
      final Map<String, dynamic> userData = userDoc?.data() as Map<String, dynamic>? ?? {};
      final String requesterName = userData['fullName'] ?? userData['name'] ?? 'Anonymous';
      final String requesterPhone = userData['phone'] ?? 'N/A';

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
        // Navigate to searching screen instead of popping
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const SearchingProvidersScreen()),
        );
      }
    } catch (e) {
      if (mounted) _showSnackBar("Failed: $e", Colors.red);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _RequestScreenHeader(onBack: () => Navigator.pop(context)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      _SectionLabel(label: 'RESOURCE & QUANTITY'),
                      const SizedBox(height: 12),
                      _ResourceDropdown(
                        selectedItem: _selectedItem,
                        selectedUnit: _selectedUnit,
                        onChanged: _onResourceChanged,
                      ),
                      const SizedBox(height: 12),
                      _QuantityField(
                        controller: _quantityController,
                        unit: _selectedUnit ?? 'Units',
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'RECIPIENT NAME'),
                      const SizedBox(height: 12),
                      _StyledTextField(
                        controller: _recipientController,
                        hint: 'Enter recipient name',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'URGENCY LEVEL'),
                      const SizedBox(height: 12),
                      _UrgencySelector(
                        selected: _urgencyLevel,
                        onChanged: (v) => setState(() => _urgencyLevel = v),
                      ),
                      const SizedBox(height: 20),
                      _SectionLabel(label: 'PICKUP / DELIVERY POINT'),
                      const SizedBox(height: 12),
                      _LocationCard(address: loc.isEmpty ? 'Fetching location...' : loc),
                      const SizedBox(height: 32),
                      _RequestNowButton(
                        isSending: _isSending,
                        onTap: _sendBroadcastRequest,
                      ),
                      const SizedBox(height: 16),
                      _SecurityNote(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _RequestScreenHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _RequestScreenHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: onBack,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0D4F4A)),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'NEW VITAL REQUEST',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D9488),
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: const TextSpan(
              text: 'Specify your ',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF0D4F4A), height: 1.1),
              children: [
                TextSpan(
                  text: 'needs.',
                  style: TextStyle(color: Color(0xFF0D9488)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our Calm Guardian system ensures your request reaches the right responder with absolute clarity.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w800,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.5,
      ),
    );
  }
}

class _ResourceDropdown extends StatelessWidget {
  final String? selectedItem;
  final String? selectedUnit;
  final void Function(String?) onChanged;

  const _ResourceDropdown({
    required this.selectedItem,
    required this.selectedUnit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: DropdownButtonFormField<String>(
        value: (masterInventoryList.any((e) => e.name == selectedItem)) ? selectedItem : null,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'TYPE',
          labelStyle: TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, letterSpacing: 1),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        items: masterInventoryList
            .map((e) => e.name)
            .toSet()
            .map((name) => DropdownMenuItem(value: name, child: Text(name)))
            .toList(),
        onChanged: onChanged,
        validator: (v) => v == null ? 'Please select an item' : null,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D4F4A)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488)),
        dropdownColor: Colors.white,
      ),
    );
  }
}

class _QuantityField extends StatelessWidget {
  final TextEditingController controller;
  final String unit;

  const _QuantityField({required this.controller, required this.unit});

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          labelText: 'AMOUNT',
          labelStyle: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8), fontWeight: FontWeight.w700, letterSpacing: 1),
          hintText: '0 $unit',
          hintStyle: TextStyle(color: Colors.grey[300]),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _StyledTextField({required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return _CardContainer(
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontWeight: FontWeight.w400),
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

class _CardContainer extends StatelessWidget {
  final Widget child;
  const _CardContainer({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: child,
    );
  }
}

class _UrgencySelector extends StatelessWidget {
  final int selected;
  final void Function(int) onChanged;

  const _UrgencySelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = [
      _UrgencyOption(label: 'Low', icon: Icons.sentiment_satisfied_alt_rounded, color: const Color(0xFF64748B)),
      _UrgencyOption(label: 'Medium', icon: Icons.warning_amber_rounded, color: const Color(0xFFF59E0B)),
      _UrgencyOption(label: 'Critical', icon: Icons.emergency_rounded, color: const Color(0xFFDC2626)),
    ];

    return Row(
      children: List.generate(options.length, (i) {
        final opt = options[i];
        final isSelected = selected == i;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < options.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: isSelected ? opt.color : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? opt.color : const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: opt.color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
                      : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
                ),
                child: Column(
                  children: [
                    Icon(opt.icon, size: 22, color: isSelected ? Colors.white : opt.color),
                    const SizedBox(height: 4),
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _UrgencyOption {
  final String label;
  final IconData icon;
  final Color color;
  const _UrgencyOption({required this.label, required this.icon, required this.color});
}

class _LocationCard extends StatelessWidget {
  final String address;
  const _LocationCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 110,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFDFF1EF),
      ),
      child: Stack(
        children: [
          // Decorative map-like gradient
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFB2DFDB), Color(0xFFDFF1EF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),
          // Location pin overlay
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded, color: Color(0xFF0D9488), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0D4F4A)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.edit_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestNowButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onTap;

  const _RequestNowButton({required this.isSending, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: Container(
        width: double.infinity,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D9488).withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: isSending
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Request Now',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.shield_rounded, size: 13, color: Colors.grey[400]),
        const SizedBox(width: 5),
        Text(
          'Secured by Emergeo Medical Response Protocol',
          style: TextStyle(fontSize: 11, color: Colors.grey[400]),
        ),
      ],
    );
  }
}