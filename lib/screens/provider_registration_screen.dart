import 'dart:io';
import 'package:emergency_res_loc_new/data/master_inventory_list.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _teal     = Color(0xFF0D9488);
const _tealDark = Color(0xFF0D4F4A);
const _bgColor  = Color(0xFFF8FAFB);

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() =>
      _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {

  // ── Services ─────────────────────────────────────────────────────────────────
  final _formKey     = GlobalKey<FormState>();
  final _authService = AuthService();
  final _picker      = ImagePicker();
  final _firestore   = FirebaseFirestore.instance;

  // ── Controllers (HFR & NMC Removed) ─────────────────────────
  final _nameController        = TextEditingController();
  final _phoneController       = TextEditingController();
  final _emailController       = TextEditingController();
  final _passwordController    = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController     = TextEditingController();
  final _latController         = TextEditingController();
  final _lonController         = TextEditingController();

  // ── State ────────────────────────────────────────────────────────────────────
  String _selectedType  = 'Multi-Speciality Hospital';
  bool   _isLoading     = true;   
  bool   _isSaving      = false;  

  // Loaded from Firestore
  double        _avgRating           = 0.0;
  int           _reviewCount         = 0;
  bool          _isAvailable         = false;
  bool          _isHFRVerified       = false;
  bool          _isNMCVerified       = false;
  bool          _profileComplete     = false;
  
  File?         _certificateImage;
  String?       _existingCertUrl;
  
  final List<File> _facilityImages = [];
  List<String>  _existingFacilityUrls = [];
  List<Map<String, dynamic>> _inventoryItems = [];

  final List<String> _facilityTypes = masterInventoryList.map((e) => e.name).toList();

  // ── Lifecycle ─────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  @override
  void dispose() {
    for (final c in [
      _nameController, _phoneController, _emailController,
      _passwordController, _addressController, _descriptionController,
      _latController, _lonController
    ]) { c.dispose(); }
    super.dispose();
  }

  // ── load data from Firestore ─────────────────────────────────────────────
  Future<void> _loadExistingData() async {
    final user = _authService.currentUser;
    if (user == null) { setState(() => _isLoading = false); return; }

    try {
      final doc = await _firestore.collection('providers').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final d = doc.data()!;

        _nameController.text        = d['name']        ?? '';
        _phoneController.text       = d['phone']        ?? '';
        _emailController.text       = d['email']        ?? '';
        _addressController.text     = d['address']      ?? '';
        _descriptionController.text = d['description']  ?? '';
        _latController.text         = (d['latitude']  as num?)?.toString() ?? '';
        _lonController.text         = (d['longitude'] as num?)?.toString() ?? '';

        final pType = (d['providerType'] as String?) ?? '';
        _selectedType = _facilityTypes.firstWhere(
              (t) => t.toLowerCase().contains(pType.toLowerCase()),
          orElse: () => _facilityTypes.first,
        );

        _avgRating       = (d['avgRating']    as num?)?.toDouble() ?? 0.0;
        _reviewCount     = (d['reviewCount']  as int?)             ?? 0;
        _isAvailable     = d['isAvailable']   as bool?             ?? false;
        _isHFRVerified   = d['isHFRVerified'] as bool?             ?? false;
        _isNMCVerified   = d['isNMCVerified'] as bool?             ?? false;
        _profileComplete = d['profileComplete'] as bool?           ?? false;

        final cert = d['certificateUrl'] as String? ?? '';
        _existingCertUrl = cert.isEmpty ? null : cert;

        _existingFacilityUrls = List<String>.from(d['facilityUrls'] ?? []);

        final rawInv = d['inventory'] as List? ?? [];
        _inventoryItems = rawInv.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('_loadExistingData: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Image helpers ─────────────────────────────────────────────────────────────
  Future<void> _pickCertificate() async {
    final f = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (f != null) setState(() => _certificateImage = File(f.path));
  }

  Future<void> _pickFacilityImages() async {
    final files = await _picker.pickMultiImage(imageQuality: 80);
    if (files.isNotEmpty) {
      setState(() => _facilityImages.addAll(files.map((x) => File(x.path))));
    }
  }

  // ── Registration flow ─────────────────────────────────────────────────────────
  Future<void> _startRegistrationFlow() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_latController.text.isEmpty) {
      _showSnackBar('Please capture clinic location first.', Colors.orange); return;
    }
    
    if (_certificateImage == null && _existingCertUrl == null) {
      _showSnackBar('Upload your Facility Certificate to proceed.', Colors.orange); return;
    }
    
    final totalPhotos = _existingFacilityUrls.length + _facilityImages.length;
    if (totalPhotos < 5) {
      _showSnackBar('Minimum 5 facility photos required. Current: $totalPhotos', Colors.red);
      return;
    }
    
    setState(() => _isSaving = true);
    
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) phone = '+91$phone';
    phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    try {
      await _authService.startPhoneVerification(
        phoneNumber: phone,
        isLogin: false,
        onCodeSent: (vId, _) {
          setState(() => _isSaving = false);
          _showOtpDialog(vId, phone);
        },
        onVerificationFailed: (e) {
          setState(() => _isSaving = false);
          _showSnackBar('Verification Failed: ${e.message}', Colors.red);
        },
      );
    } catch (e) {
      setState(() => _isSaving = false);
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  void _showOtpDialog(String vId, String phone) {
    final otpCtrl = TextEditingController();
    showDialog(
      context: context, barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Verify Phone', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Enter the 6-digit code sent to $phone', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: otpCtrl,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: '000000',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _teal, width: 2),
              ),
            ),
          ),
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeRegistration(vId, otpCtrl.text.trim());
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _teal, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Verify & Register'),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeRegistration(String vId, String smsCode) async {
    setState(() => _isSaving = true);
    
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) phone = '+91$phone';
    phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    
    try {
      final user = await _authService.registerWithVerifiedPhone(
        email:            _emailController.text.trim(),
        password:         _passwordController.text.trim(),
        verificationId:   vId,
        smsCode:          smsCode,
        fullName:         _nameController.text.trim(),
        userType:         'provider',
        phone:            phone,
      );

      if (user != null) {
        // HFR and NMC have been removed from this initial setup
        await _firestore.collection('providers').doc(user.uid).update({
          'address': _addressController.text.trim(),
          'latitude': double.tryParse(_latController.text) ?? 0.0,
          'longitude': double.tryParse(_lonController.text) ?? 0.0,
          'providerType': _selectedType,
          'profileComplete': true, 
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar(e.toString(), Colors.red);
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isSaving = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() {
        _latController.text = pos.latitude.toString();
        _lonController.text = pos.longitude.toString();
      });
    } catch (e) {
      _showSnackBar('Location Error: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg), backgroundColor: color,
      behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
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

    final hasExistingData = _nameController.text.isNotEmpty;

    return Scaffold(
      backgroundColor: _bgColor,
      body: CustomScrollView(
        slivers: [
          const _RegSliverAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasExistingData) ...[
                      _ProfileStatusBanner(
                        avgRating:     _avgRating,
                        reviewCount:   _reviewCount,
                        isAvailable:   _isAvailable,
                        isHFRVerified: _isHFRVerified,
                        isNMCVerified: _isNMCVerified,
                      ),
                      const SizedBox(height: 16),
                    ],

                    _StepCard(
                      stepNumber: '1',
                      title: 'Facility Identity',
                      child: _FacilityIdentityStep(
                        nameController:       _nameController,
                        phoneController:      _phoneController,
                        addressController:    _addressController,
                        selectedType:         _selectedType,
                        facilityTypes:        _facilityTypes,
                        onTypeChanged:        (v) => setState(() => _selectedType = v!),
                        onUseCurrentLocation: _getCurrentLocation,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _StepCard(
                      stepNumber: '2',
                      title: 'Verification Documents',
                      child: _VerificationDocumentsStep(
                        certificateImage:     _certificateImage,
                        existingCertUrl:      _existingCertUrl,
                        facilityImages:       _facilityImages,
                        existingFacilityUrls: _existingFacilityUrls,
                        onPickCertificate:    _pickCertificate,
                        onPickFacilityImages: _pickFacilityImages,
                      ),
                    ),
                    const SizedBox(height: 16),

                    _StepCard(
                      stepNumber: '3',
                      title: 'Services & Inventory',
                      child: _ServicesInventoryStep(inventoryItems: _inventoryItems),
                    ),
                    const SizedBox(height: 16),

                    _StepCard(
                      stepNumber: '4',
                      title: 'GPS Sync',
                      child: _GpsSyncStep(
                        latController: _latController,
                        lonController: _lonController,
                        isLoading:     _isSaving,
                        onSync:        _getCurrentLocation,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _AuthFieldsSection(
                      emailController:    _emailController,
                      passwordController: _passwordController,
                    ),
                    const SizedBox(height: 28),

                    _SubmitButton(isLoading: _isSaving, onTap: _startRegistrationFlow),
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

// ─────────────────────────────────────────────────────────────────────────────
// INDEPENDENT WIDGET COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _RegSliverAppBar extends StatelessWidget {
  const _RegSliverAppBar();
  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true, backgroundColor: _tealDark, elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('Provider Registration', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
    );
  }
}

class _ProfileStatusBanner extends StatelessWidget {
  final double avgRating;
  final int    reviewCount;
  final bool   isAvailable, isHFRVerified, isNMCVerified;

  const _ProfileStatusBanner({
    required this.avgRating, required this.reviewCount,
    required this.isAvailable, required this.isHFRVerified,
    required this.isNMCVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('CURRENT PROFILE STATUS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Row(children: [
          _StatusPill(
            label: isAvailable ? 'Available' : 'Offline',
            color: isAvailable ? const Color(0xFF16A34A) : Colors.grey,
            bg:    isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            label: 'HFR ${isHFRVerified ? '✓' : '✗'}',
            color: isHFRVerified ? _teal : const Color(0xFFDC2626),
            bg:    isHFRVerified ? const Color(0xFFEFF6F5) : const Color(0xFFFEE2E2),
          ),
          const SizedBox(width: 8),
          _StatusPill(
            label: 'NMC ${isNMCVerified ? '✓' : '✗'}',
            color: isNMCVerified ? _teal : const Color(0xFFDC2626),
            bg:    isNMCVerified ? const Color(0xFFEFF6F5) : const Color(0xFFFEE2E2),
          ),
        ]),
        if (reviewCount > 0) ...[
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 4),
            Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _tealDark)),
            const SizedBox(width: 6),
            Text('($reviewCount reviews)', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ]),
        ],
      ]),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label; final Color color, bg;
  const _StatusPill({required this.label, required this.color, required this.bg});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
  );
}

class _StepCard extends StatelessWidget {
  final String stepNumber, title;
  final Widget child;
  const _StepCard({required this.stepNumber, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
          child: Row(children: [
            Container(
              width: 26, height: 26,
              decoration: const BoxDecoration(color: _tealDark, shape: BoxShape.circle),
              child: Center(child: Text(stepNumber, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white))),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: _tealDark)),
          ]),
        ),
        Padding(padding: const EdgeInsets.all(16), child: child),
      ]),
    );
  }
}

class _FacilityIdentityStep extends StatelessWidget {
  final TextEditingController nameController, phoneController, addressController;
  final String selectedType;
  final List<String> facilityTypes;
  final void Function(String?) onTypeChanged;
  final VoidCallback onUseCurrentLocation;

  const _FacilityIdentityStep({
    required this.nameController, required this.phoneController,
    required this.addressController, required this.selectedType,
    required this.facilityTypes, required this.onTypeChanged,
    required this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
    _RegField(controller: nameController, label: 'FACILITY NAME', hint: 'Shanti Hospital', validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
    const SizedBox(height: 12),
    _FacilityTypeDropdown(selected: selectedType, types: facilityTypes, onChanged: onTypeChanged),
    const SizedBox(height: 12),
    _PhoneField(controller: phoneController),
    const SizedBox(height: 12),
    _RegField(controller: addressController, label: 'FACILITY ADDRESS', hint: 'Sector 19A, Airoli, Navi Mumbai 400708', maxLines: 2, validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
    const SizedBox(height: 4),
    Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onUseCurrentLocation,
        child: const Text('☉ Use Current Location', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
      ),
    ),
  ]);
}

class _VerificationDocumentsStep extends StatelessWidget {
  final File?        certificateImage;
  final String?      existingCertUrl;
  final List<File>   facilityImages;
  final List<String> existingFacilityUrls;
  final VoidCallback onPickCertificate, onPickFacilityImages;

  const _VerificationDocumentsStep({
    required this.certificateImage, required this.existingCertUrl,
    required this.facilityImages, required this.existingFacilityUrls,
    required this.onPickCertificate, required this.onPickFacilityImages,
  });

  bool get _hasCert => certificateImage != null || existingCertUrl != null;
  int get  _photoCount => existingFacilityUrls.length + facilityImages.length;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFFEA580C)),
          SizedBox(width: 8),
          Expanded(child: Text('We verify all providers within 24 hours to maintain the integrity of emergency services.', style: TextStyle(fontSize: 11, color: Color(0xFF92400E), height: 1.4))),
        ]),
      ),
      const SizedBox(height: 14),
      const Text('Medical Registration Certificate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tealDark)),
      const SizedBox(height: 8),
      GestureDetector(
        onTap: onPickCertificate,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _hasCert ? _teal : const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: Column(children: [
            Icon(_hasCert ? Icons.check_circle_rounded : Icons.upload_file_rounded, size: 32, color: _hasCert ? _teal : Colors.grey[400]),
            const SizedBox(height: 6),
            Text(
              certificateImage != null ? certificateImage!.path.split('/').last : (existingCertUrl != null ? 'Certificate uploaded ✓' : 'Click to upload PDF or Image'),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (!_hasCert) Text('Maximum file size: 5MB', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
          ]),
        ),
      ),
      const SizedBox(height: 14),
      Row(children: [
        const Text('Facility Photos (Exterior & Wards)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _tealDark)),
        const Spacer(),
        Text('$_photoCount/5', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _photoCount >= 5 ? _teal : const Color(0xFFDC2626))),
      ]),
      const SizedBox(height: 4),
      Text('Minimum 5 photos required', style: TextStyle(fontSize: 10, color: Colors.grey[400])),
      const SizedBox(height: 8),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...existingFacilityUrls.map((url) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(url, width: 64, height: 64, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 64, height: 64, decoration: BoxDecoration(color: const Color(0xFFF0FDF9), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.broken_image_rounded, color: _teal))),
        )),
        ...facilityImages.map((file) => ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(file, width: 64, height: 64, fit: BoxFit.cover),
        )),
        GestureDetector(
          onTap: onPickFacilityImages,
          child: Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5)),
            child: const Icon(Icons.add_rounded, color: _teal, size: 24),
          ),
        ),
      ]),
    ]);
  }
}

class _ServicesInventoryStep extends StatelessWidget {
  final List<Map<String, dynamic>> inventoryItems;
  const _ServicesInventoryStep({required this.inventoryItems});

  static IconData _icon(String n) {
    n = n.toLowerCase();
    if (n.contains('blood'))            return Icons.bloodtype_rounded;
    if (n.contains('icu') || n.contains('bed')) return Icons.bed_rounded;
    if (n.contains('ventilator'))       return Icons.air_rounded;
    if (n.contains('oxygen'))           return Icons.bubble_chart_rounded;
    if (n.contains('ambulance'))        return Icons.local_taxi_rounded;
    if (n.contains('cylinder'))         return Icons.propane_tank_rounded;
    return Icons.medical_services_rounded;
  }

  static Color _bg(String n) {
    n = n.toLowerCase();
    if (n.contains('blood'))                       return const Color(0xFFFEE2E2);
    if (n.contains('oxygen') || n.contains('cyl')) return const Color(0xFFEFF6FF);
    return const Color(0xFFEFF6F5);
  }

  static Color _fg(String n) {
    n = n.toLowerCase();
    if (n.contains('blood'))                       return const Color(0xFFDC2626);
    if (n.contains('oxygen') || n.contains('cyl')) return const Color(0xFF2563EB);
    return _teal;
  }

  @override
  Widget build(BuildContext context) {
    final rows = inventoryItems.isNotEmpty
        ? inventoryItems
        : [
      {'name': 'A+ Blood', 'quantity': 0, 'unit': 'Units'},
      {'name': 'ICU Bed',  'quantity': 0, 'unit': 'Beds'},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ...rows.map((item) {
        final name = item['name'] as String? ?? 'Item';
        final qty  = (item['quantity'] as num?)?.toInt() ?? 0;
        final unit = item['unit'] as String? ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _InventoryRow(
            icon: _icon(name), label: name, unit: unit.isNotEmpty ? unit : 'Total Available',
            quantity: qty, iconColor: _fg(name), iconBg: _bg(name),
          ),
        );
      }),
      const SizedBox(height: 4),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ...['Ventilator', 'Oxygen', 'Ambulance'].map((s) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE2E8F0)), borderRadius: BorderRadius.circular(20)),
          child: Text('+ $s', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
        )),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(border: Border.all(color: _teal), borderRadius: BorderRadius.circular(20), color: const Color(0xFFEFF6F5)),
          child: const Text('+ Add Service', style: TextStyle(fontSize: 12, color: _teal, fontWeight: FontWeight.w600)),
        ),
      ]),
    ]);
  }
}

class _GpsSyncStep extends StatelessWidget {
  final TextEditingController latController, lonController;
  final bool isLoading;
  final VoidCallback onSync;

  const _GpsSyncStep({
    required this.latController, required this.lonController,
    required this.isLoading, required this.onSync,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        height: 100,
        decoration: BoxDecoration(color: const Color(0xFFEFF6F5), borderRadius: BorderRadius.circular(12)),
        child: Stack(alignment: Alignment.center, children: [
          GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 6),
            itemCount: 36,
            itemBuilder: (_, __) => Container(decoration: BoxDecoration(border: Border.all(color: const Color(0xFFD1FAE5), width: 0.5))),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)]),
            child: const Icon(Icons.location_pin, size: 32, color: _teal),
          ),
        ]),
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _CoordDisplay(label: 'LATITUDE', value: latController.text.isEmpty ? '—' : latController.text)),
        Expanded(child: _CoordDisplay(label: 'LONGITUDE', value: lonController.text.isEmpty ? '—' : lonController.text)),
      ]),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: onSync,
        child: Container(
          width: double.infinity, height: 44,
          decoration: BoxDecoration(color: const Color(0xFFEFF6F5), borderRadius: BorderRadius.circular(12), border: Border.all(color: _teal.withOpacity(0.3))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            isLoading
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _teal, strokeWidth: 2))
                : const Icon(Icons.sync_rounded, color: _teal, size: 16),
            const SizedBox(width: 8),
            const Text('Sync GPS Position', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _teal)),
          ]),
        ),
      ),
    ]);
  }
}

class _CoordDisplay extends StatelessWidget {
  final String label, value;
  const _CoordDisplay({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1)),
    const SizedBox(height: 2),
    Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _tealDark)),
  ]);
}

class _AuthFieldsSection extends StatelessWidget {
  final TextEditingController emailController, passwordController;

  const _AuthFieldsSection({
    required this.emailController, required this.passwordController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.lock_rounded, size: 16, color: _teal),
          SizedBox(width: 8),
          Text('Account Credentials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: _tealDark)),
        ]),
        const SizedBox(height: 14),
        _RegField(controller: emailController, label: 'OFFICIAL EMAIL', hint: 'hospital@example.com', keyboardType: TextInputType.emailAddress, validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
        const SizedBox(height: 12),
        _RegField(controller: passwordController, label: 'PASSWORD', hint: 'Minimum 8 characters', isPassword: true, validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
      ]),
    );
  }
}

class _RegField extends StatelessWidget {
  final TextEditingController controller;
  final String hint, label;
  final TextInputType? keyboardType;
  final int  maxLines;
  final bool isPassword;
  final String? Function(String?)? validator;

  const _RegField({
    required this.controller, required this.hint, required this.label,
    this.keyboardType, this.maxLines = 1, this.isPassword = false,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: TextFormField(
        controller: controller, keyboardType: keyboardType, maxLines: maxLines, obscureText: isPassword,
        style: const TextStyle(fontSize: 14, color: _tealDark),
        decoration: InputDecoration(hintText: hint, hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13)),
        validator: validator,
      ),
    ),
  ]);
}

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  const _PhoneField({required this.controller});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('CONTACT NUMBER', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
          decoration: const BoxDecoration(border: Border(right: BorderSide(color: Color(0xFFE2E8F0)))),
          child: const Text('+91', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _tealDark)),
        ),
        Expanded(
          child: TextFormField(
            controller: controller, keyboardType: TextInputType.phone,
            style: const TextStyle(fontSize: 14, color: _tealDark),
            decoration: const InputDecoration(hintText: '99999 99999', hintStyle: TextStyle(color: Color(0xFFCBD5E1), fontSize: 13), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 13)),
            validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
          ),
        ),
      ]),
    ),
  ]);
}

class _FacilityTypeDropdown extends StatelessWidget {
  final String selected;
  final List<String> types;
  final void Function(String?) onChanged;
  const _FacilityTypeDropdown({required this.selected, required this.types, required this.onChanged});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('FACILITY TYPE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), letterSpacing: 1.2)),
    const SizedBox(height: 6),
    Container(
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: DropdownButtonFormField<String>(
        value: selected, isExpanded: true,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4)),
        style: const TextStyle(fontSize: 14, color: _tealDark),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _teal),
        dropdownColor: Colors.white,
        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
        onChanged: onChanged,
      ),
    ),
  ]);
}

class _InventoryRow extends StatelessWidget {
  final IconData icon; final String label, unit; final int quantity; final Color iconColor, iconBg;
  const _InventoryRow({required this.icon, required this.label, required this.unit, required this.quantity, required this.iconColor, required this.iconBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFE2E8F0))),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: iconColor)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _tealDark)), Text(unit, style: TextStyle(fontSize: 11, color: Colors.grey[400]))])),
        Row(children: [
          _QtyBtn(icon: Icons.remove_rounded, onTap: () {}),
          const SizedBox(width: 10),
          Text('$quantity', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _tealDark)),
          const SizedBox(width: 10),
          _QtyBtn(icon: Icons.add_rounded, onTap: () {}, isAdd: true),
        ]),
      ]),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap; final bool isAdd;
  const _QtyBtn({required this.icon, required this.onTap, this.isAdd = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 28, height: 28,
      decoration: BoxDecoration(color: isAdd ? _teal : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, size: 16, color: isAdd ? Colors.white : Colors.grey[600]),
    ),
  );
}

class _SubmitButton extends StatelessWidget {
  final bool isLoading; final VoidCallback onTap;
  const _SubmitButton({required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: isLoading ? null : onTap,
    child: Container(
      width: double.infinity, height: 54,
      decoration: BoxDecoration(gradient: const LinearGradient(colors: [_tealDark, _teal], begin: Alignment.centerLeft, end: Alignment.centerRight), borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: _teal.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))]),
      child: Center(child: isLoading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Row(mainAxisSize: MainAxisSize.min, children: [Text('Submit for Verification', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)), SizedBox(width: 8), Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18)])),
    ),
  );
}