import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/requester_model.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import 'offline_region_picker_screen.dart';

class RequesterProfileScreen extends StatefulWidget {
  const RequesterProfileScreen({super.key});

  @override
  State<RequesterProfileScreen> createState() => _RequesterProfileScreenState();
}

class _RequesterProfileScreenState extends State<RequesterProfileScreen> {
  List<Map<String, dynamic>> _savedLocations = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  String _selectedBloodType = 'Unknown';
  List<EmergencyContact> _emergencyChecklist = [];
  bool _isLoading = true;
  bool _sendSmsPermission = false;
  String location = "";

  final List<String> _bloodTypes = ['Unknown', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
  final user = AuthService().currentUser;
  if (user == null) return;

  try {
    // 1. First, fetch the document
    final doc = await FirebaseFirestore.instance.collection('requesters').doc(user.uid).get();
    
    if (doc.exists && doc.data() != null) {
      final data = doc.data() as Map<String, dynamic>;
      
      // 2. Use setState to ensure the UI reacts to the new data
      setState(() {
        // We use .from() and explicitly map to ensures types are correct for Flutter
        if (data['savedLocations'] != null) {
          final List<dynamic> rawList = data['savedLocations'];
          _savedLocations = rawList.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          _savedLocations = [];
        }

        // Keep your existing profile fields here...
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _medicalController.text = data['medicalNotes'] ?? '';
        _sendSmsPermission = data['sendSmsPermission'] ?? false;
        String bType = data['bloodGrp'] ?? 'Unknown';
        _selectedBloodType = _bloodTypes.contains(bType) ? bType : 'Unknown';
        
        if (data['emergencyContacts'] != null) {
          _emergencyChecklist = (data['emergencyContacts'] as List).map((e) {
            return EmergencyContact(
              name: e['name'] ?? '',
              phone: e['phone'] ?? '',
            )..isSelected = e['isSelected'] ?? true;
          }).toList();
        }
      });
    }
  } catch (e) {
    debugPrint("Error loading profile data: $e");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  Future<void> _pickAndSearchContact() async {
    var status = await Permission.contacts.request();

    if (status.isGranted) {
      try {
        // Fetch raw contacts from service
        final List<ContactInfo> rawContacts = await FlutterContactsService.getContacts();

        final List<EmergencyContact> mappedContacts = rawContacts.map((c) {
          return EmergencyContact(
            name: c.displayName ?? "Unknown",
            phone: (c.phones != null && c.phones!.isNotEmpty)
                ? c.phones!.first.value ?? ""
                : "No Number",
          );
        }).toList();

        if (!mounted) return;

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (context) => SizedBox(
            height: MediaQuery.of(context).size.height * 0.8,
            child: ContactSearchDialog(
              contacts: mappedContacts, 
              onContactSelected: (selected) {
                setState(() => _emergencyChecklist.add(selected..isSelected = true));
                Navigator.pop(context);
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint("Contact Service Error: $e");
      }
    }
  }

  Future<void> _saveProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('requesters').doc(user.uid).set({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'bloodGrp': _selectedBloodType,
        'medicalNotes': _medicalController.text.trim(),
        'emergencyContacts': _emergencyChecklist.map((e) => {
          'name': e.name,
          'phone': e.phone,
          'isSelected': e.isSelected,
        }).toList(),
        'sendSmsPermission': _sendSmsPermission,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileComplete': true, 
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medical ID Updated"), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text("Medical ID & Profile"), backgroundColor: Colors.redAccent, actions: [IconButton(onPressed: _saveProfile, icon: const Icon(Icons.check))]),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader("IDENTITY"),
            _buildCard([
              _buildTextField(_nameController, "Legal Name", Icons.person),
              const Divider(),
              _buildTextField(_phoneController, "Primary Phone", Icons.phone, isPhone: true),
            ]),
            const SizedBox(height: 24),
            
            _buildSectionHeader("CRITICAL MEDICAL INFO"),
            _buildCard([
              _buildBloodTypeDropdown(),
              const Divider(),
              _buildTextField(_medicalController, "Allergies / Conditions", Icons.medical_services, maxLines: 3),
            ]),
            const SizedBox(height: 24),
            
            _buildSectionHeader("EMERGENCY SETTINGS"),
            _buildCard([
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: Icon(Icons.message, color: _sendSmsPermission ? Colors.green : Colors.grey),
                title: const Text("Emergency Contact SMS"),
                value: _sendSmsPermission,
                onChanged: (val) => setState(() => _sendSmsPermission = val),
              ),
            ]),
            const SizedBox(height: 24),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("EMERGENCY CONTACTS"),
                TextButton.icon(onPressed: _pickAndSearchContact, icon: const Icon(Icons.add), label: const Text("Add New"))
              ],
            ),
            _buildEmergencyContactList(),

            // --- NEW: SAVED OFFLINE REGIONS ---
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader("SAVED OFFLINE REGIONS"),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OfflineRegionPickerScreen())).then((_) => _loadUserData());
                  }, 
                  icon: const Icon(Icons.add_location_alt), 
                  label: const Text("Add Trip")
                )
              ],
            ),
            if (_savedLocations.isEmpty)
              const Card(child: Padding(padding: EdgeInsets.all(16.0), child: Text("No offline regions saved. Add a trip if you are heading to a low-network area.", style: TextStyle(color: Colors.grey)))),
            ..._savedLocations.map((loc) => Card(
              child: ListTile(
                leading: const Icon(Icons.offline_pin, color: Colors.blue),
                title: Text(loc['name'] ?? 'Saved Trip', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Radius: ${loc['radius']} km"),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    final user = AuthService().currentUser;
                    if (user != null) {
                      await FirebaseFirestore.instance.collection('requesters').doc(user.uid).update({
                        'savedLocations': FieldValue.arrayRemove([loc])
                      });
                      _loadUserData(); 
                    }
                  },
                ),
              ),
            )),
            const SizedBox(height: 40),
            // ------------------------------------
          ],
        ),
      ),
    );
  }

  // UI Helpers
  Widget _buildSectionHeader(String title) => Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)));
  
  Widget _buildCard(List<Widget> children) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)]), child: Column(children: children));
  
  Widget _buildTextField(TextEditingController c, String l, IconData i, {bool isPhone = false, int maxLines = 1}) => TextFormField(controller: c, maxLines: maxLines, keyboardType: isPhone ? TextInputType.phone : TextInputType.text, decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.redAccent), border: InputBorder.none));
  
  Widget _buildBloodTypeDropdown() => ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.bloodtype, color: Colors.redAccent), title: const Text("Blood Type"), trailing: DropdownButton<String>(value: _selectedBloodType, onChanged: (v) => setState(() => _selectedBloodType = v!), items: _bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList()));
  
  Widget _buildEmergencyContactList() {
    return Column(children: _emergencyChecklist.map((c) => Card(child: CheckboxListTile(title: Text(c.name), subtitle: Text(c.phone), value: c.isSelected, onChanged: (v) => setState(() => c.isSelected = v!), secondary: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _emergencyChecklist.remove(c)))))).toList());
  }
}

class ContactSearchDialog extends StatefulWidget {
  final List<EmergencyContact> contacts;
  final Function(EmergencyContact) onContactSelected;
  const ContactSearchDialog({super.key, required this.contacts, required this.onContactSelected});
  
  @override 
  State<ContactSearchDialog> createState() => _ContactSearchDialogState();
}

class _ContactSearchDialogState extends State<ContactSearchDialog> {
  late List<EmergencyContact> _filtered;
  
  @override 
  void initState() { 
    super.initState(); 
    _filtered = widget.contacts; 
  }
  
  @override 
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16), 
        child: TextField(
          decoration: const InputDecoration(hintText: "Search...", prefixIcon: Icon(Icons.search)), 
          onChanged: (v) => setState(() => _filtered = widget.contacts.where((c) => c.name.toLowerCase().contains(v.toLowerCase())).toList())
        )
      ),
      Expanded(
        child: ListView.builder(
          itemCount: _filtered.length, 
          itemBuilder: (context, i) => ListTile(
            title: Text(_filtered[i].name), 
            subtitle: Text(_filtered[i].phone), 
            onTap: () => widget.onContactSelected(_filtered[i])
          )
        )
      )
    ]);
  }
}