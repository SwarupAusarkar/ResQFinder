import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import '../services/ReviewService.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

// ── Design tokens ─────────────────────────────────────────────────────────────
const _teal = Color(0xFF0D9488);
const _tealDark = Color(0xFF0D4F4A);
const _bgColor = Color(0xFFF4FAF9);

class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({super.key});
  @override
  State<ProviderProfileEditScreen> createState() =>
      _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends State<ProviderProfileEditScreen> {
  // ── Form & services ──────────────────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();
  final _firestore = FirebaseFirestore.instance;
  final _reviewService = ReviewService();
  final _picker = ImagePicker();

  // ── Controllers ──────────────────────────────────────────────────────────────
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  
  // NEW: Added HFR and NMC controllers here
  final _hfrController = TextEditingController();
  final _nmcController = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  String _verificationStatus = 'pending';
  String? _existingCertUrl;
  List<String> _existingFacilityUrls = [];
  File? _newCertificateImage;
  List<File> _newFacilityImages = [];

  double _avgRating = 0.0;
  int _reviewCount = 0;
  String _summaryReview = 'No summary available yet.';
  bool _isAvailable = true;
  List<Map<String, dynamic>> _inventoryItems = [];
  String _providerType = 'hospital';

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _hfrController.dispose();
    _nmcController.dispose();
    super.dispose();
  }

  // ── Load ─────────────────────────────────────────────────────────────────────
  Future<void> _loadProviderData() async {
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('providers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;
        _nameController.text = d['name'] ?? '';
        _phoneController.text = d['phone'] ?? '';
        _addressController.text = d['address'] ?? '';
        _descriptionController.text = d['description'] ?? '';
        _latController.text = (d['latitude'] as num?)?.toString() ?? '';
        _lonController.text = (d['longitude'] as num?)?.toString() ?? '';
        
        // Load Verification IDs
        _hfrController.text = d['hfrId'] ?? '';
        _nmcController.text = d['nmcId'] ?? '';

        _verificationStatus = d['verificationStatus'] ?? 'pending';
        _existingCertUrl =
            (d['certificateUrl'] as String?)?.isEmpty == true
                ? null
                : d['certificateUrl'] as String?;
        _existingFacilityUrls = List<String>.from(d['facilityUrls'] ?? []);
        _isAvailable = d['isAvailable'] as bool? ?? true;
        _avgRating = (d['avgRating'] as num?)?.toDouble() ?? 0.0;
        _reviewCount = (d['reviewCount'] as int?) ?? 0;
        _providerType = d['providerType'] as String? ?? 'hospital';
        final rawInv = d['inventory'] as List? ?? [];
        _inventoryItems =
            rawInv.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
      
      // AI summary via ReviewService
      final stats = await _reviewService.getProviderStats(user.uid);
      if (mounted) {
        setState(() {
          _avgRating = (stats['avgRating'] as num).toDouble();
          _reviewCount = stats['reviewCount'] as int;
          _summaryReview = stats['summaryReview'] as String;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('_loadProviderData: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Image picking ────────────────────────────────────────────────────────────
  Future<void> _pickCertificate() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (result != null) {
      setState(() => _newCertificateImage = File(result.files.single.path!));
    }
  }

  Future<void> _pickFacilityImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() => _newFacilityImages.addAll(files.map((x) => File(x.path))));
    }
  }

  // ── GPS sync ─────────────────────────────────────────────────────────────────
  Future<void> _updateLocation() async {
    setState(() => _isSaving = true);
    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = position.latitude.toStringAsFixed(6);
        _lonController.text = position.longitude.toStringAsFixed(6);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated!'),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────────────
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final user = _authService.currentUser;
    if (user == null) return;
    try {
      String? finalCertUrl = _existingCertUrl;
      List<String> finalFacilityUrls = List.from(_existingFacilityUrls);

      if (_newCertificateImage != null) {
        final ext = path.extension(_newCertificateImage!.path);
        final ref = FirebaseStorage.instance.ref().child(
          'provider_certs/${user.uid}_cert$ext',
        );
        await ref.putFile(_newCertificateImage!);
        finalCertUrl = await ref.getDownloadURL();
      }
      for (int i = 0; i < _newFacilityImages.length; i++) {
        final ref = FirebaseStorage.instance.ref().child(
          'provider_facilities/${user.uid}/fac_img_'
          '${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
        );
        await ref.putFile(_newFacilityImages[i]);
        finalFacilityUrls.add(await ref.getDownloadURL());
      }
      
      await _firestore.collection('providers').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': double.tryParse(_latController.text) ?? 0,
        'longitude': double.tryParse(_lonController.text) ?? 0,
        'certificateUrl': finalCertUrl ?? '',
        'facilityUrls': finalFacilityUrls,
        'isAvailable': _isAvailable,
        'hfrId': _hfrController.text.trim(),
        'nmcId': _nmcController.text.trim(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: _teal,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _bgColor,
        body: Center(child: CircularProgressIndicator(color: _teal)),
      );
    }

    return Scaffold(
      backgroundColor: _bgColor,
      // Removed the BottomActionBar to declutter
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            // ── Hero header ──────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _HeroHeader(
                name: _nameController.text,
                address: _addressController.text,
                isAvailable: _isAvailable,
                verificationStatus: _verificationStatus,
                avgRating: _avgRating,
                reviewCount: _reviewCount,
                providerType: _providerType,
                facilityUrls: _existingFacilityUrls,
                onAvailableToggle: (v) => setState(() => _isAvailable = v),
                onSave: _saveProfile,
                isSaving: _isSaving,
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Edit fields (Permanently Expanded) ─────────────────────
                    _SectionHeader(label: 'Profile Settings'),
                    const SizedBox(height: 12),
                    _EditProfileForm(
                      nameController: _nameController,
                      phoneController: _phoneController,
                      addressController: _addressController,
                      descriptionController: _descriptionController,
                      latController: _latController,
                      lonController: _lonController,
                      hfrController: _hfrController,
                      nmcController: _nmcController,
                      existingCertUrl: _existingCertUrl,
                      newCertImage: _newCertificateImage,
                      existingFacilityUrls: _existingFacilityUrls,
                      newFacilityImages: _newFacilityImages,
                      isSyncing: _isSaving,
                      onPickCert: _pickCertificate,
                      onPickFacility: _pickFacilityImages,
                      onRemoveFacility:
                          (f) => setState(() => _newFacilityImages.remove(f)),
                      onSyncGps: _updateLocation,
                      onSave: _saveProfile,
                    ),
                    const SizedBox(height: 24),

                    // ── Live inventory ─────────────────────────────────────────
                    _SectionHeader(
                      label: 'Live Inventory',
                      trailing: _LiveBadge(),
                    ),
                    const SizedBox(height: 12),
                    _LiveInventoryGrid(items: _inventoryItems),
                    const SizedBox(height: 24),

                    // ── Rating & feedback summary ──────────────────────────────
                    _SectionHeader(label: 'Patient Feedback'),
                    const SizedBox(height: 12),
                    _RatingSummaryCard(
                      avgRating: _avgRating,
                      reviewCount: _reviewCount,
                      summary: _summaryReview,
                    ),
                    const SizedBox(height: 40), 
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

// ─────────────────────────────────────────────────────────────────────────────
// HERO HEADER
// ─────────────────────────────────────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String name, address, verificationStatus, providerType;
  final bool isAvailable, isSaving;
  final double avgRating;
  final int reviewCount;
  final List<String> facilityUrls;
  final void Function(bool) onAvailableToggle;
  final VoidCallback onSave;

  const _HeroHeader({
    required this.name,
    required this.address,
    required this.isAvailable,
    required this.verificationStatus,
    required this.avgRating,
    required this.reviewCount,
    required this.providerType,
    required this.facilityUrls,
    required this.onAvailableToggle,
    required this.onSave,
    required this.isSaving,
  });

  @override
  Widget build(BuildContext context) {
    final isVerified = verificationStatus == 'approved';
    return Container(
      color: const Color(0xFFEBF6F4),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top nav row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: _tealDark,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),

                  Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isVerified ? const Color(0xFFDCFCE7) : Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isVerified ? 'Verified ✓' : 'Unverified',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isVerified ? const Color(0xFF16A34A) : Colors.orange[800],
                      ),
                    ),
                  ),

                  GestureDetector(
                    onTap: isSaving ? null : onSave,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _teal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: isSaving
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Facility thumbnail
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                  ),
                ],
                image:
                    facilityUrls.isNotEmpty
                        ? DecorationImage(
                          image: NetworkImage(facilityUrls.first),
                          fit: BoxFit.cover,
                        )
                        : null,
              ),
              child:
                  facilityUrls.isEmpty
                      ? const Icon(
                        Icons.local_hospital_rounded,
                        size: 36,
                        color: _teal,
                      )
                      : null,
            ),
            const SizedBox(height: 12),

            // Name + verified badge
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.isEmpty ? 'My Facility' : name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _tealDark,
                  ),
                ),
                if (isVerified) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.verified_rounded, size: 18, color: _teal),
                ],
              ],
            ),
            const SizedBox(height: 4),

            Text(
              address.isEmpty ? '' : address,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),

            // Available toggle pill
            GestureDetector(
              onTap: () => onAvailableToggle(!isAvailable),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isAvailable
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isAvailable ? const Color(0xFF16A34A) : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isAvailable ? '● AVAILABLE NOW' : '○ OFFLINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color:
                            isAvailable ? const Color(0xFF16A34A) : Colors.grey,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Stat cards row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'Provider Type',
                      value: providerType.toUpperCase(),
                      iconColor: _teal,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.star_rounded,
                      label: 'Rating',
                      value:
                          '${avgRating.toStringAsFixed(1)}'
                          ' (${_formatCount(reviewCount)})',
                      iconColor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EDIT PROFILE FORM (Un-collapsed)
// ─────────────────────────────────────────────────────────────────────────────
class _EditProfileForm extends StatelessWidget {
  final TextEditingController nameController,
      phoneController,
      addressController,
      descriptionController,
      latController,
      lonController,
      hfrController,
      nmcController;
  final String? existingCertUrl;
  final File? newCertImage;
  final List<String> existingFacilityUrls;
  final List<File> newFacilityImages;
  final bool isSyncing;
  final VoidCallback onPickCert, onPickFacility, onSyncGps, onSave;
  final void Function(File) onRemoveFacility;

  const _EditProfileForm({
    required this.nameController,
    required this.phoneController,
    required this.addressController,
    required this.descriptionController,
    required this.latController,
    required this.lonController,
    required this.hfrController,
    required this.nmcController,
    required this.existingCertUrl,
    required this.newCertImage,
    required this.existingFacilityUrls,
    required this.newFacilityImages,
    required this.isSyncing,
    required this.onPickCert,
    required this.onPickFacility,
    required this.onRemoveFacility,
    required this.onSyncGps,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditField(
            controller: nameController,
            label: 'FACILITY NAME',
            hint: 'Shanti Hospital',
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: phoneController,
            label: 'PHONE',
            hint: '+91 99999 99999',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: addressController,
            label: 'ADDRESS',
            hint: 'Full address',
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: descriptionController,
            label: 'DESCRIPTION & SERVICES',
            hint: 'Services offered…',
            maxLines: 3,
          ),
          
          const SizedBox(height: 24),
          const Text(
            'VERIFICATION DOCUMENTS',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: _teal,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: hfrController,
            label: 'HFR ID (OPTIONAL)',
            hint: 'HFR-XXXXXXXX',
            isRequired: false,
          ),
          const SizedBox(height: 12),
          _EditField(
            controller: nmcController,
            label: 'NMC DOCTOR ID (OPTIONAL)',
            hint: 'NMC-XXXXXXXX',
            isRequired: false,
          ),
          const SizedBox(height: 16),
          _CertificateUploadRow(
            existingUrl: existingCertUrl,
            newImage: newCertImage,
            onPick: onPickCert,
          ),
          const SizedBox(height: 20),

          _FacilityPhotosRow(
            existingUrls: existingFacilityUrls,
            newImages: newFacilityImages,
            onPickMore: onPickFacility,
            onRemove: onRemoveFacility,
          ),
          const SizedBox(height: 20),

          _GpsRow(
            latController: latController,
            lonController: lonController,
            isSyncing: isSyncing,
            onSync: onSyncGps,
          ),
          const SizedBox(height: 24),

          // Save Changes Button
          GestureDetector(
            onTap: isSyncing ? null : onSave,
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_tealDark, _teal],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: _teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Center(
                child: isSyncing
                    ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                    : const Text(
                      'Save All Changes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Widget? trailing;
  const _SectionHeader({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: _tealDark,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color iconColor;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: _tealDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditField extends StatelessWidget {
  final TextEditingController controller;
  final String label, hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool isRequired;
  const _EditField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.isRequired = true,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Color(0xFF94A3B8),
          letterSpacing: 1.2,
        ),
      ),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: _tealDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
          validator: isRequired ? (v) => v?.isEmpty ?? true ? 'Required' : null : null,
        ),
      ),
    ],
  );
}

class _CertificateUploadRow extends StatelessWidget {
  final String? existingUrl;
  final File? newImage;
  final VoidCallback onPick;
  const _CertificateUploadRow({
    required this.existingUrl,
    required this.newImage,
    required this.onPick,
  });

  bool get _has => newImage != null || existingUrl != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPick,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _has ? _teal : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _has ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              size: 20,
              color: _has ? _teal : Colors.grey[400],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                newImage != null
                    ? newImage!.path.split('/').last
                    : (existingUrl != null
                        ? 'Certificate uploaded ✓'
                        : 'Upload Medical Certificate'),
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacilityPhotosRow extends StatelessWidget {
  final List<String> existingUrls;
  final List<File> newImages;
  final VoidCallback onPickMore;
  final void Function(File) onRemove;
  const _FacilityPhotosRow({
    required this.existingUrls,
    required this.newImages,
    required this.onPickMore,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'FACILITY PHOTOS',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...existingUrls.map(
              (url) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  url,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.broken_image_rounded,
                          color: _teal,
                        ),
                      ),
                ),
              ),
            ),
            ...newImages.map(
              (file) => Stack(
                alignment: Alignment.topRight,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      file,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => onRemove(file),
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: onPickMore,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                child: const Icon(Icons.add_rounded, color: _teal, size: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GpsRow extends StatelessWidget {
  final TextEditingController latController, lonController;
  final bool isSyncing;
  final VoidCallback onSync;
  const _GpsRow({
    required this.latController,
    required this.lonController,
    required this.isSyncing,
    required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'GPS COORDINATES',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  latController.text.isEmpty ? 'Lat —' : latController.text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tealDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  lonController.text.isEmpty ? 'Lon —' : lonController.text,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _tealDark,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onSync,
          child: Container(
            width: double.infinity,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6F5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _teal.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                isSyncing
                    ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        color: _teal,
                        strokeWidth: 2,
                      ),
                    )
                    : const Icon(Icons.sync_rounded, size: 16, color: _teal),
                const SizedBox(width: 8),
                const Text(
                  'Sync GPS Position',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _teal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIVE INVENTORY
// ─────────────────────────────────────────────────────────────────────────────
class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFFFEE2E2),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.fiber_manual_record, size: 8, color: Color(0xFFDC2626)),
        SizedBox(width: 4),
        Text(
          'LIVE',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: Color(0xFFDC2626),
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );
}

class _LiveInventoryGrid extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  const _LiveInventoryGrid({required this.items});

  static IconData _icon(String n) {
    n = n.toLowerCase();
    if (n.contains('blood')) return Icons.bloodtype_rounded;
    if (n.contains('icu') || n.contains('bed')) return Icons.bed_rounded;
    if (n.contains('ventilator')) return Icons.air_rounded;
    if (n.contains('oxygen') || n.contains('cylinder'))
      return Icons.bubble_chart_rounded;
    return Icons.medical_services_rounded;
  }

  static Color _dot(int qty) =>
      qty > 0 ? const Color(0xFF16A34A) : const Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    final display = items.take(4).toList();
    if (display.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'No inventory data',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.6,
      ),
      itemCount: display.length,
      itemBuilder: (_, i) {
        final item = display[i];
        final name = item['name'] as String? ?? '—';
        final qty = (item['quantity'] as num?)?.toInt() ?? 0;
        final unit = item['unit'] as String? ?? '';
        return _InventoryTile(
          icon: _icon(name),
          name: name,
          quantity: qty,
          unit: unit,
          dotColor: _dot(qty),
        );
      },
    );
  }
}

class _InventoryTile extends StatelessWidget {
  final IconData icon;
  final String name, unit;
  final int quantity;
  final Color dotColor;

  const _InventoryTile({
    required this.icon,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.dotColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: _teal),
              const Spacer(),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            quantity == 0
                ? '0 Available'
                : '$quantity ${unit.isNotEmpty ? unit : 'Units'}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: _tealDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(name, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RATING SUMMARY CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RatingSummaryCard extends StatelessWidget {
  final double avgRating;
  final int reviewCount;
  final String summary;
  const _RatingSummaryCard({
    required this.avgRating,
    required this.reviewCount,
    required this.summary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.stars_rounded,
                color: Color(0xFFF59E0B),
                size: 26,
              ),
              const SizedBox(width: 8),
              Text(
                avgRating.toStringAsFixed(1),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _tealDark,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '($reviewCount reviews)',
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          const Text(
            'PATIENT FEEDBACK SUMMARY',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: _teal,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '"$summary"',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}