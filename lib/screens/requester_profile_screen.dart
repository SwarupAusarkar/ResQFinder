// lib/screens/requester_profile_screen.dart
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

  // ── State (unchanged logic) ──────────────────────────────────────────────────
=======
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

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D9488);
  static const _tealDark = Color(0xFF0D4F4A);
  static const _bgColor = Color(0xFFEFF6F5);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // ── Logic (unchanged) ────────────────────────────────────────────────────────
  Future<void> _loadUserData() async {

    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final pos = await LocationService.getCurrentLocation();
      if (pos != null) {
        location = await LocationService.getAddressFromLatLng(pos.latitude, pos.longitude);
      }
      final doc = await FirebaseFirestore.instance.collection('requesters').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _medicalController.text = data['medicalNotes'] ?? '';
          _sendSmsPermission = data['sendSmsPermission'] ?? false;
          String bType = data['bloodGrp'] ?? 'Unknown';
          _selectedBloodType = _bloodTypes.contains(bType) ? bType : 'Unknown';
          if (data['emergencyContacts'] != null) {
            _emergencyChecklist = (data['emergencyContacts'] as List).map((e) {
              return EmergencyContact(name: e['name'] ?? '', phone: e['phone'] ?? '')
                ..isSelected = e['isSelected'] ?? true;
            }).toList();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading profile: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);

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
        final List<ContactInfo> rawContacts = await FlutterContactsService.getContacts();
        final List<EmergencyContact> mappedContacts = rawContacts.map((c) {
          return EmergencyContact(
            name: c.displayName ?? "Unknown",
            phone: (c.phones != null && c.phones!.isNotEmpty) ? c.phones!.first.value ?? "" : "No Number",
          );
        }).toList();
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
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

        'emergencyContacts': _emergencyChecklist.map((e) => {'name': e.name, 'phone': e.phone, 'isSelected': e.isSelected}).toList(),
        'sendSmsPermission': _sendSmsPermission,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
        'profileComplete': true,

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Medical ID Updated"),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEFF6F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _ProfileSliverHeader(
              name: _nameController.text.isEmpty ? 'Your Name' : _nameController.text,
              onSave: _saveProfile,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── FULL NAME & PHONE ──────────────────────────────────────
                    _SectionLabel(label: 'FULL NAME'),
                    const SizedBox(height: 8),
                    _ProfileField(controller: _nameController, hint: 'e.g. Swarup Ausarkar', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    _SectionLabel(label: 'MOBILE NUMBER'),
                    const SizedBox(height: 8),
                    _PhoneField(controller: _phoneController),
                    const SizedBox(height: 24),

                    _Divider(),

                    // ── MEDICAL DETAILS ────────────────────────────────────────
                    _SectionLabel(label: 'MEDICAL DETAILS'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _BloodTypeCard(
                            selected: _selectedBloodType,
                            bloodTypes: _bloodTypes,
                            onChanged: (v) => setState(() => _selectedBloodType = v!),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ContactCard(contacts: _emergencyChecklist),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    _SectionLabel(label: 'ALLERGIES & MEDICAL CONDITIONS'),
                    const SizedBox(height: 8),
                    _MedicalNotesField(controller: _medicalController),
                    const SizedBox(height: 24),

                    _Divider(),

                    // ── LOCATION ACCESS ────────────────────────────────────────
                    _LocationAccessCard(address: location),
                    const SizedBox(height: 24),

                    _Divider(),

                    // ── AUTO-SEND SMS ──────────────────────────────────────────
                    _SmsToggleCard(
                      value: _sendSmsPermission,
                      onChanged: (v) => setState(() => _sendSmsPermission = v),
                    ),
                    const SizedBox(height: 24),

                    _Divider(),

                    // ── EMERGENCY CONTACTS ─────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionLabel(label: 'EMERGENCY CONTACTS'),
                        GestureDetector(
                          onTap: _pickAndSearchContact,
                          child: Row(
                            children: [
                              const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0D9488)),
                              const SizedBox(width: 4),
                              const Text('Add New', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _EmergencyContactsList(
                      contacts: _emergencyChecklist,
                      onDelete: (c) => setState(() => _emergencyChecklist.remove(c)),
                      onToggle: (c, v) => setState(() => c.isSelected = v),
                    ),
                    const SizedBox(height: 32),

                    // ── SAVE BUTTON ────────────────────────────────────────────
                    _SaveButton(onTap: _saveProfile),
                    const SizedBox(height: 16),
                    _FooterLinks(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _ProfileSliverHeader extends StatelessWidget {
  final String name;
  final VoidCallback onSave;

  const _ProfileSliverHeader({required this.name, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: const Color(0xFF0D4F4A),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        TextButton(
          onPressed: onSave,
          child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFF0D4F4A),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, size: 40, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(color: Color(0xFF0D9488), shape: BoxShape.circle),
                      child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 20),
            ],
          ),
        ),
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
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Divider(color: Colors.grey.withOpacity(0.15), height: 1),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;

  const _ProfileField({required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF9),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(14), bottomLeft: Radius.circular(14)),
              border: Border(right: BorderSide(color: Colors.grey.withOpacity(0.15))),
            ),
            child: const Text('+91', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D4F4A))),
          ),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Color(0xFF0D4F4A)),
              decoration: const InputDecoration(
                hintText: '00000 00000',
                hintStyle: TextStyle(color: Color(0xFFCBD5E1)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodTypeCard extends StatelessWidget {
  final String selected;
  final List<String> bloodTypes;
  final void Function(String?) onChanged;

  const _BloodTypeCard({required this.selected, required this.bloodTypes, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('BLOOD TYPE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 10),
          // Blood type display pill
          if (selected != 'Unknown')
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(selected, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
              ),
            ),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              style: const TextStyle(fontSize: 13, color: Color(0xFF0D4F4A), fontWeight: FontWeight.w600),
              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0D9488), size: 18),
              onChanged: onChanged,
              items: bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            ),
          ),
          if (selected != 'Unknown')
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(20)),
                child: const Text('CRITICAL INFO', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Color(0xFFDC2626), letterSpacing: 0.5)),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final List<EmergencyContact> contacts;
  const _ContactCard({required this.contacts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CONTACT', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 8),
          const Text(
            'Emergency\n#',
            style: TextStyle(fontSize: 13, color: Color(0xFF0D4F4A), fontWeight: FontWeight.w500, height: 1.4),
          ),
          const SizedBox(height: 8),
          Text(
            '${contacts.length} contact${contacts.length == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF0D9488), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MedicalNotesField extends StatelessWidget {
  final TextEditingController controller;
  const _MedicalNotesField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: TextFormField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
        decoration: const InputDecoration(
          hintText: 'List any chronic conditions or allergies...',
          hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _LocationAccessCard extends StatelessWidget {
  final String address;
  const _LocationAccessCard({required this.address});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6F5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFF0D9488), size: 28),
            ),
            const SizedBox(height: 14),
            const Text(
              'Allow Location Access',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0D4F4A)),
            ),
            const SizedBox(height: 6),
            Text(
              address.isEmpty
                  ? 'Emergeo uses your location to connect you with the nearest emergency responders in seconds.'
                  : address,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey[500], height: 1.5),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmsToggleCard extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _SmsToggleCard({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6F5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.location_on_rounded, color: Color(0xFF0D9488), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Auto-send location SMS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D4F4A))),
                  Text('Sends live coordinates during SOS', style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF0D9488),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmergencyContactsList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final void Function(EmergencyContact) onDelete;
  final void Function(EmergencyContact, bool) onToggle;

  const _EmergencyContactsList({required this.contacts, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text('No emergency contacts added', style: TextStyle(color: Colors.grey[400], fontSize: 13)),
        ),
      );
    }
    return Column(
      children: contacts.map((c) => _EmergencyContactTile(contact: c, onDelete: onDelete, onToggle: onToggle)).toList(),
    );
  }
}

class _EmergencyContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final void Function(EmergencyContact) onDelete;
  final void Function(EmergencyContact, bool) onToggle;

  const _EmergencyContactTile({required this.contact, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
        border: Border(left: BorderSide(color: const Color(0xFF0D9488), width: 3)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [

            // Avatar initial
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(color: Color(0xFFEFF6F5), shape: BoxShape.circle),
              child: Center(
                child: Text(
                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0D9488)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(contact.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0D4F4A))),
                      const SizedBox(width: 6),
                      if (contact.isSelected)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(20)),
                          child: const Text('VERIFIED', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: Color(0xFF16A34A), letterSpacing: 0.5)),
                        ),
                    ],
                  ),
                  Text(contact.phone, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF94A3B8)),
              onPressed: () => onDelete(contact),
            ),

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
}

class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: const Center(
          child: Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

class _FooterLinks extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _FooterLink(label: 'Terms of Service'),
        const Text(' · ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        _FooterLink(label: 'Privacy Policy'),
        const Text(' · ', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
        _FooterLink(label: 'Help Center'),
      ],
    );
  }
}

class _FooterLink extends StatelessWidget {
  final String label;
  const _FooterLink({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)));
  }
}

// ── ContactSearchDialog (unchanged logic, updated style) ──────────────────────

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
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() {
                _filtered = widget.contacts.where((c) => c.name.toLowerCase().contains(v.toLowerCase())).toList();
              }),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _filtered.length,
            itemBuilder: (context, i) => ListTile(
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFEFF6F5),
                child: Text(_filtered[i].name.isNotEmpty ? _filtered[i].name[0] : '?', style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
              ),
              title: Text(_filtered[i].name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text(_filtered[i].phone, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () => widget.onContactSelected(_filtered[i]),
            ),
          ),
        ),
      ],
    );
  }
}