// lib/screens/requester_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts_service/flutter_contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/requester_model.dart';
import '../services/auth_service.dart';
import 'offline_provider_list_screen.dart';
import '../services/location_service.dart';
import 'offline_region_picker_screen.dart';

// ── Design Tokens ─────────────────────────────────────────────────────────────
const _teal = Color(0xFF00897B);
const _white = Color(0xFFFFEBEE);
const _darkteal = Color(0xFF00897B);
const _bgColor = Color(0xFFFAFAFA);

class RequesterProfileScreen extends StatefulWidget {
  const RequesterProfileScreen({super.key});

  @override
  State<RequesterProfileScreen> createState() => _RequesterProfileScreenState();
}

class _RequesterProfileScreenState extends State<RequesterProfileScreen> {
  // ── State ──
  List<Map<String, dynamic>> _savedLocations = [];
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _medicalController = TextEditingController();

  String? _profileImageUrl;
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

  // ── Logic ──
  Future<void> _loadUserData() async {
    final user = AuthService().currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('requesters').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          if (data['savedLocations'] != null) {
            final List<dynamic> rawList = data['savedLocations'];
            _savedLocations = rawList.map((item) => Map<String, dynamic>.from(item)).toList();
          } else {
            _savedLocations = [];
          }

          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _medicalController.text = data['medicalNotes'] ?? '';
          _sendSmsPermission = data['sendSmsPermission'] ?? false;
          _profileImageUrl = data['profileImageUrl'] as String?;
          
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

  Future<void> _updateProfilePicture() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile == null) return;

    setState(() => _isLoading = true);
    try {
      final user = AuthService().currentUser;
      if (user == null) return;

      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child('profile_pictures/requesters/${user.uid}.jpg');
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('requesters').doc(user.uid).update({'profileImageUrl': url});

      setState(() => _profileImageUrl = url);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile picture updated!'), backgroundColor: _teal));
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      setState(() => _isLoading = false);
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
            phone: (c.phones != null && c.phones!.isNotEmpty)
                ? c.phones!.first.value ?? ""
                : "No Number",
          );
        }).toList();
        if (!mounted) return;
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Save Error: $e"),
            backgroundColor: Colors.grey[800],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
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
      backgroundColor: _bgColor,
      body: CustomScrollView(
        slivers: [
          _ProfileSliverAppBar(
            name: _nameController.text,
            bloodType: _selectedBloodType,
            profileImageUrl: _profileImageUrl,
            onUpdateProfilePic: _updateProfilePicture,
            onSave: _saveProfile,
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileSectionCard(
                      title: 'Identity',
                      icon: Icons.person_rounded,
                      child: _IdentityFields(
                        nameController: _nameController,
                        phoneController: _phoneController,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileSectionCard(
                      title: 'Critical Medical Info',
                      icon: Icons.medical_services_rounded,
                      iconColor: _teal,
                      child: _MedicalInfoFields(
                        medicalController: _medicalController,
                        selectedBloodType: _selectedBloodType,
                        bloodTypes: _bloodTypes,
                        onBloodTypeChanged: (v) => setState(() => _selectedBloodType = v!),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _ProfileSectionCard(
                      title: 'Emergency Settings',
                      icon: Icons.notifications_active_rounded,
                      child: _EmergencySettingsRow(
                        value: _sendSmsPermission,
                        onChanged: (val) => setState(() => _sendSmsPermission = val),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Emergency Contacts',
                      actionLabel: 'Add New',
                      actionIcon: Icons.person_add_rounded,
                      onAction: _pickAndSearchContact,
                    ),
                    const SizedBox(height: 8),
                    _EmergencyContactList(
                      contacts: _emergencyChecklist,
                      onToggle: (c, v) => setState(() => c.isSelected = v!),
                      onRemove: (c) => setState(() => _emergencyChecklist.remove(c)),
                    ),
                    const SizedBox(height: 16),
                    _SectionHeader(
                      title: 'Saved Offline Regions',
                      actionLabel: 'Add Trip',
                      actionIcon: Icons.add_location_alt_rounded,
                      onAction: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OfflineRegionPickerScreen()),
                        ).then((_) => _loadUserData());
                      },
                    ),
                    const SizedBox(height: 8),
                    _OfflineRegionsList(
                      locations: _savedLocations,
                      onDelete: (loc) async {
                        final user = AuthService().currentUser;
                        if (user != null) {
                          await FirebaseFirestore.instance
                              .collection('requesters')
                              .doc(user.uid)
                              .update({
                            'savedLocations': FieldValue.arrayRemove([loc])
                          });
                          _loadUserData();
                        }
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-components ────────────────────────────────────────────────────────────

class _ProfileSliverAppBar extends StatelessWidget {
  final String name;
  final String bloodType;
  final String? profileImageUrl;
  final VoidCallback onUpdateProfilePic;
  final VoidCallback onSave;

  const _ProfileSliverAppBar({
    required this.name,
    required this.bloodType,
    required this.profileImageUrl,
    required this.onUpdateProfilePic,
    required this.onSave,
  });

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
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: onSave,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Save',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_darkteal, _teal],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: onUpdateProfilePic,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                              image: profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: profileImageUrl == null
                                ? const Icon(Icons.person_rounded, size: 40, color: Colors.white)
                                : null,
                          ),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: _teal,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    if (bloodType != 'Unknown')
                      Positioned(
                        bottom: -4,
                        left: -10, // Moved to the left to not clash with the camera icon
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)
                            ]
                          ),
                          child: Text(
                            bloodType,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              color: _teal,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  name.isEmpty ? 'Medical ID' : name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Emergency Profile',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String actionLabel;
  final IconData actionIcon;
  final VoidCallback onAction;

  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.actionIcon,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        GestureDetector(
          onTap: onAction,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(actionIcon, size: 13, color: _teal),
                const SizedBox(width: 4),
                Text(
                  actionLabel,
                  style: const TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color? iconColor;

  const _ProfileSectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? _teal;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 15, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF212121),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF5F5F5)),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }
}

class _IdentityFields extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController phoneController;

  const _IdentityFields({
    required this.nameController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProfileField(
          controller: nameController,
          label: 'LEGAL NAME',
          hint: 'Full name',
          icon: Icons.person_rounded,
        ),
        const SizedBox(height: 12),
        _ProfileField(
          controller: phoneController,
          label: 'PRIMARY PHONE',
          hint: 'Contact number',
          icon: Icons.phone_rounded,
          keyboardType: TextInputType.phone,
        ),
      ],
    );
  }
}

class _MedicalInfoFields extends StatelessWidget {
  final TextEditingController medicalController;
  final String selectedBloodType;
  final List<String> bloodTypes;
  final void Function(String?) onBloodTypeChanged;

  const _MedicalInfoFields({
    required this.medicalController,
    required this.selectedBloodType,
    required this.bloodTypes,
    required this.onBloodTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BLOOD TYPE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: Color(0xFF9E9E9E),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEEEEEE)),
              ),
              child: Row(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.bloodtype_rounded, size: 16, color: _teal),
                  ),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedBloodType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      ),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _teal),
                      dropdownColor: Colors.white,
                      items: bloodTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: onBloodTypeChanged,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ProfileField(
          controller: medicalController,
          label: 'ALLERGIES / CONDITIONS',
          hint: 'List known conditions, allergies...',
          icon: Icons.medical_services_rounded,
          maxLines: 3,
        ),
      ],
    );
  }
}

class _EmergencySettingsRow extends StatelessWidget {
  final bool value;
  final void Function(bool) onChanged;

  const _EmergencySettingsRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: value ? const Color(0xFFE8F5E9) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.message_rounded,
            size: 18,
            color: value ? Colors.green[700] : Colors.grey[400],
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Emergency Contact SMS',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
              ),
              Text(
                'Auto-alert contacts during SOS',
                style: TextStyle(fontSize: 11, color: Color(0xFF9E9E9E)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _teal,
          activeTrackColor: _white,
        ),
      ],
    );
  }
}

class _EmergencyContactList extends StatelessWidget {
  final List<EmergencyContact> contacts;
  final void Function(EmergencyContact, bool?) onToggle;
  final void Function(EmergencyContact) onRemove;

  const _EmergencyContactList({
    required this.contacts,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    if (contacts.isEmpty) {
      return const _EmptyState(
        icon: Icons.contact_phone_rounded,
        message: 'No emergency contacts added yet.',
      );
    }

    return Column(
      children: contacts.map((c) => _ContactCard(contact: c, onToggle: onToggle, onRemove: onRemove)).toList(),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final EmergencyContact contact;
  final void Function(EmergencyContact, bool?) onToggle;
  final void Function(EmergencyContact) onRemove;

  const _ContactCard({
    required this.contact,
    required this.onToggle,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: contact.isSelected ? _teal.withOpacity(0.2) : const Color(0xFFEEEEEE),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Checkbox(
            value: contact.isSelected,
            onChanged: (v) => onToggle(contact, v),
            activeColor: _teal,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: contact.isSelected ? _white : const Color(0xFFF5F5F5),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: contact.isSelected ? _teal : Colors.grey[400],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF212121)),
                ),
                Text(
                  contact.phone,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBDBDBD), size: 20),
            onPressed: () => onRemove(contact),
          ),
        ],
      ),
    );
  }
}

class _OfflineRegionsList extends StatelessWidget {
  final List<Map<String, dynamic>> locations;
  final void Function(Map<String, dynamic>) onDelete;

  const _OfflineRegionsList({required this.locations, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) {
      return const _EmptyState(
        icon: Icons.offline_pin_rounded,
        message: 'No offline regions saved. Add a trip if you are heading to a low-network area.',
      );
    }

    return Column(
      children: locations.map((loc) => _OfflineRegionCard(location: loc, onDelete: onDelete)).toList(),
    );
  }
}

class _OfflineRegionCard extends StatelessWidget {
  final Map<String, dynamic> location;
  final void Function(Map<String, dynamic>) onDelete;

  const _OfflineRegionCard({required this.location, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OfflineProviderListScreen(
              regionName: location['name'] ?? 'Saved Trip',
              lat: (location['latitude'] as num).toDouble(),
              lng: (location['longitude'] as num).toDouble(),
              radiusKm: (location['radius'] as num).toDouble(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE3F2FD)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.offline_pin_rounded, size: 18, color: Color(0xFF1565C0)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location['name'] ?? 'Saved Trip',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF212121),
                    ),
                  ),
                  Text(
                    'Radius: ${location['radius']} km',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFBDBDBD), size: 20),
              onPressed: () => onDelete(location),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;

  const _ProfileField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF9E9E9E),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Icon(icon, size: 16, color: _teal),
              ),
              Expanded(
                child: TextFormField(
                  controller: controller,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF212121)),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(color: Color(0xFFBDBDBD), fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF5F5F5)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: const Color(0xFFE0E0E0)),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9E9E9E), height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ── Contact Search Dialog ───────────────────────────────────────────────────

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
        Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0))),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[400], size: 18),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: (v) => setState(() {
                _filtered =
                    widget.contacts.where((c) => c.name.toLowerCase().contains(v.toLowerCase())).toList();
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
                child: Text(_filtered[i].name.isNotEmpty ? _filtered[i].name[0] : '?',
                    style: const TextStyle(color: Color(0xFF0D9488), fontWeight: FontWeight.w700)),
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