import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/requester_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';

class RequesterProfileScreen extends StatefulWidget {
  const RequesterProfileScreen({super.key});

  @override
  State<RequesterProfileScreen> createState() => _RequesterProfileScreenState();
}

class _RequesterProfileScreenState extends State<RequesterProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  String _selectedBloodType = 'Unknown';
  List<EmergencyContact> _emergencyChecklist = [];
  bool _isLoading = true;
  String location = "";

  final List<String> _bloodTypes = [
    'Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    // Get current location
    final pos = await LocationService.getCurrentLocation();
    if (pos != null) {
      location = await LocationService.getAddressFromLatLng(
        pos.latitude,pos.longitude,
      );
      print("📍 Address: $location");
    } else {
      print("❌ Location not available");
    }

    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final profile = requester_model.fromFirestore(doc);

        _nameController.text = profile.fullName;
        _phoneController.text = profile.phone;
        _medicalController.text = profile.medicalNotes;

        // ✅ Ensure blood type is valid
        _selectedBloodType = _bloodTypes.contains(profile.bloodGrp)
            ? profile.bloodGrp
            : 'Unknown';

        _emergencyChecklist = profile.emergencyContacts;
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodGrp': _selectedBloodType, // ✅ match field name with model
        'medicalNotes': _medicalController.text.trim(),
        'emergencyContacts': _emergencyChecklist.map((e) => e.toMap()).toList(),
        'location': location,
      };

      print("Saving data for UID ${user.uid}: $data");

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set(
        data,
        SetOptions(merge: true),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Medical ID Updated"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Medical ID & Profile"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: _saveProfile, icon: const Icon(Icons.done_all))
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader("IDENTITY"),
            _buildCard([
              _buildTextField(_nameController, "Legal Name", Icons.person),
              const Divider(),
              _buildTextField(_phoneController, "Primary Phone", Icons.phone,
                  isPhone: true),
            ]),

            const SizedBox(height: 20),
            _buildSectionHeader("CRITICAL MEDICAL INFO"),
            _buildCard([
              _buildBloodTypeDropdown(),
              const Divider(),
              _buildTextField(_medicalController, "Allergies / Conditions",
                  Icons.medical_services,
                  maxLines: 3),
            ]),

            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("EMERGENCY CONTACTS"),
                IconButton(
                  onPressed: _pickContact,
                  icon: const Icon(Icons.add_circle, color: Colors.redAccent),
                ),
              ],
            ),
            _buildEmergencyContactList(),
          ],
        ),
      ),
    );
  }

  // UI Helper Components
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon,
      {bool isPhone = false, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.redAccent, size: 20),
        border: InputBorder.none,
      ),
    );
  }

  Widget _buildBloodTypeDropdown() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.bloodtype, color: Colors.redAccent),
      title: const Text("Blood Type"),
      trailing: DropdownButton<String>(
        value: _bloodTypes.contains(_selectedBloodType)
            ? _selectedBloodType
            : 'Unknown',
        onChanged: (val) => setState(() => _selectedBloodType = val ?? 'Unknown'),
        items: _bloodTypes
            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
            .toList(),
      ),
    );
  }

  Widget _buildEmergencyContactList() {
    if (_emergencyChecklist.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text("No emergency contacts added."),
        ),
      );
    }
    return Column(
      children: _emergencyChecklist.map((contact) {
        return Card(
          child: CheckboxListTile(
            secondary: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () =>
                  setState(() => _emergencyChecklist.remove(contact)),
            ),
            title: Text(contact.name),
            subtitle: Text(contact.phone),
            value: contact.isSelected,
            onChanged: (v) => setState(() => contact.isSelected = v ?? false),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _pickContact() async {
    if (await Permission.contacts.request().isGranted) {
      final List<ContactInfo> deviceContacts =
      await FlutterContactsService.getContacts();
      // TODO: Show dialog for multi-select and add to _emergencyChecklist
    }
  }
}
