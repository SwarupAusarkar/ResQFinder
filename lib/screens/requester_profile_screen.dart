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
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  List<Map<String, dynamic>> _savedLocations = [];
  String _selectedBloodType = 'Unknown';
  List<EmergencyContact> _emergencyChecklist = [];
  bool _isLoading = true;
  bool _sendSmsPermission = false;
  String location = "Fetching location...";

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
      // 1. Fetch Current Location
      final pos = await LocationService.getCurrentLocation();
      if (pos != null) {
        location = await LocationService.getAddressFromLatLng(pos.latitude, pos.longitude);
      }

      // 2. Fetch Firestore Data
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

          if (data['savedLocations'] != null) {
            final List<dynamic> rawList = data['savedLocations'];
            _savedLocations = rawList.map((item) => Map<String, dynamic>.from(item)).toList();
          }

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
      debugPrint("Error loading profile: $e");
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
          const SnackBar(
            content: Text("Medical ID Updated"),
            backgroundColor: Color(0xFF0D9488),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Save Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFEFF6F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF0D9488))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6F5),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            _ProfileSliverHeader(
              name: _nameController.text.isEmpty ? 'Set Your Name' : _nameController.text,
              onSave: _saveProfile,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const _SectionLabel(label: 'FULL NAME'),
                    const SizedBox(height: 8),
                    _ProfileField(controller: _nameController, hint: 'e.g. Swarup Ausarkar', icon: Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    const _SectionLabel(label: 'MOBILE NUMBER'),
                    const SizedBox(height: 8),
                    _PhoneField(controller: _phoneController),
                    const SizedBox(height: 24),
                    _Divider(),

                    const _SectionLabel(label: 'MEDICAL DETAILS'),
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
                          child: _ContactStatsCard(count: _emergencyChecklist.length),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const _SectionLabel(label: 'ALLERGIES & MEDICAL CONDITIONS'),
                    const SizedBox(height: 8),
                    _MedicalNotesField(controller: _medicalController),
                    const SizedBox(height: 24),
                            _Divider(),
                    _LocationAccessCard(address: location),
                    const SizedBox(height: 24),

                    // --- OFFLINE REGIONS SECTION ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel(label: 'OFFLINE SAFETY REGIONS'),
                        GestureDetector(
                          onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const OfflineRegionPickerScreen())
                          ).then((_) => _loadUserData()),
                          child: const Text('Add Trip', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_savedLocations.isEmpty)
                      const _EmptyStateCard(text: "No offline regions saved for trips."),
                    ..._savedLocations.map((loc) => _OfflineLocationTile(
                        loc: loc,
                        onDelete: () async {
                          final user = AuthService().currentUser;
                          if (user != null) {
                            await FirebaseFirestore.instance.collection('requesters').doc(user.uid).update({
                              'savedLocations': FieldValue.arrayRemove([loc])
                            });
                            _loadUserData();
                          }
                        }
                    )),
                    const SizedBox(height: 24),
                    _Divider(),

                    _SmsToggleCard(
                      value: _sendSmsPermission,
                      onChanged: (v) => setState(() => _sendSmsPermission = v),
                    ),
                    const SizedBox(height: 24),
                    _Divider(),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const _SectionLabel(label: 'EMERGENCY CONTACTS'),
                        GestureDetector(
                          onTap: _pickAndSearchContact,
                          child: const Row(
                            children: [
                              Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF0D9488)),
                              SizedBox(width: 4),
                              Text('Add New', style: TextStyle(fontSize: 12, color: Color(0xFF0D9488), fontWeight: FontWeight.w600)),
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
                    const SizedBox(height: 40),

                    _SaveButton(onTap: _saveProfile),
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

// ── UI SUB-COMPONENTS ──

class _ProfileSliverHeader extends StatelessWidget {
  final String name;
  final VoidCallback onSave;
  const _ProfileSliverHeader({required this.name, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 180,
      pinned: true,
      backgroundColor: const Color(0xFF0D4F4A),
      elevation: 0,
      actions: [
        IconButton(onPressed: onSave, icon: const Icon(Icons.check_circle, color: Colors.white)),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.white24,
                child: Icon(Icons.person, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
  Widget build(BuildContext context) => Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2));
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Divider(color: Colors.black.withOpacity(0.05)));
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  const _ProfileField({required this.controller, required this.hint, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)]),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(prefixIcon: Icon(icon, size: 20), hintText: hint, border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 16), child: const Text("+91", style: TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: TextFormField(controller: controller, keyboardType: TextInputType.phone, decoration: const InputDecoration(border: InputBorder.none, hintText: "Phone Number"))),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text("BLOOD TYPE", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          DropdownButton<String>(value: selected, isExpanded: true, items: bloodTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ContactStatsCard extends StatelessWidget {
  final int count;
  const _ContactStatsCard({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          const Text("EMERGENCY", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 10),
          Text("$count Contacts", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0D9488))),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: TextFormField(controller: controller, maxLines: 3, decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(12), hintText: "List medical conditions...")),
    );
  }
}

class _LocationAccessCard extends StatelessWidget {
  final String address;
  const _LocationAccessCard({required this.address});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF0D4F4A), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white70),
          const SizedBox(width: 12),
          Expanded(child: Text(address, style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}

class _OfflineLocationTile extends StatelessWidget {
  final Map<String, dynamic> loc;
  final VoidCallback onDelete;
  const _OfflineLocationTile({required this.loc, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(top: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: const Icon(Icons.cloud_off, color: Colors.blueGrey),
        title: Text(loc['name'] ?? 'Trip', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("${loc['radius']} km radius"),
        trailing: IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent), onPressed: onDelete),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String text;
  const _EmptyStateCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white70, borderRadius: BorderRadius.circular(12)), child: Text(text, style: const TextStyle(color: Colors.grey, fontSize: 12)));
}

class _SmsToggleCard extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SmsToggleCard({required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text("Auto-send SMS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: const Text("Sends coordinates to contacts during SOS"),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF0D9488),
    );
  }
}

class _EmergencyContactsList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final Function(EmergencyContact) onDelete;
  final Function(EmergencyContact, bool) onToggle;
  const _EmergencyContactsList({required this.contacts, required this.onDelete, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) return const _EmptyStateCard(text: "No contacts added yet.");
    return Column(children: contacts.map((c) => ListTile(
      leading: CircleAvatar(backgroundColor: const Color(0xFFEFF6F5), child: Text(c.name[0])),
      title: Text(c.name),
      subtitle: Text(c.phone),
      trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => onDelete(c)),
    )).toList());
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
class _SaveButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveButton({required this.onTap});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0D9488), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text("SAVE PROFILE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}