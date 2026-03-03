import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;

class ProviderProfileEditScreen extends StatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  State<ProviderProfileEditScreen> createState() => _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState extends State<ProviderProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _verificationStatus = 'pending';

  final ImagePicker _picker = ImagePicker();
  String? _existingCertUrl;
  List<String> _existingFacilityUrls = [];
  File? _newCertificateImage;
  List<File> _newFacilityImages = [];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('providers').doc(user.uid).get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _nameController.text = data['name'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _latController.text = data['latitude']?.toString() ?? '';
          _lonController.text = data['longitude']?.toString() ?? '';
          _verificationStatus = data['verificationStatus'] ?? 'pending';

          _existingCertUrl = data['certificateUrl'] == '' ? null : data['certificateUrl'];
          _existingFacilityUrls = List<String>.from(data['facilityUrls'] ?? []);

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading profile: $e')));
        Navigator.pop(context);
      }
    }
  }

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
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() => _newFacilityImages.addAll(pickedFiles.map((x) => File(x.path))));
    }
  }

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
            backgroundColor: Color(0xFF00897B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final user = AuthService().currentUser;
    if (user == null) return;

    try {
      String? finalCertUrl = _existingCertUrl;
      List<String> finalFacilityUrls = List.from(_existingFacilityUrls);

      if (_newCertificateImage != null) {
        String ext = path.extension(_newCertificateImage!.path);
        final ref = FirebaseStorage.instance.ref().child('provider_certs/${user.uid}_cert$ext');
        await ref.putFile(_newCertificateImage!);
        finalCertUrl = await ref.getDownloadURL();
      }

      for (int i = 0; i < _newFacilityImages.length; i++) {
        final ref = FirebaseStorage.instance.ref().child('provider_facilities/${user.uid}/fac_img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(_newFacilityImages[i]);
        String url = await ref.getDownloadURL();
        finalFacilityUrls.add(url);
      }

      await FirebaseFirestore.instance.collection('providers').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'latitude': double.parse(_latController.text),
        'longitude': double.parse(_lonController.text),
        'certificateUrl': finalCertUrl ?? '',
        'facilityUrls': finalFacilityUrls,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Color(0xFF00897B))
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Save failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Provider Profile'),
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00897B)))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildVerificationBanner(),
              const SizedBox(height: 24),

              const Text('Verification Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
              const SizedBox(height: 12),
              _buildCertificateCard(),
              const SizedBox(height: 12),
              _buildFacilityPhotosCard(),
              const SizedBox(height: 24),

              const Text('Basic Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF00897B))),
              const SizedBox(height: 12),
              _buildTextField(_nameController, 'Facility Name', Icons.business),
              const SizedBox(height: 16),
              _buildTextField(_phoneController, 'Contact Number', Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 16),
              _buildTextField(_addressController, 'Physical Address', Icons.location_on, maxLines: 2),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Services Description', Icons.description, maxLines: 3),
              const SizedBox(height: 24),

              _buildLocationSection(),
              const SizedBox(height: 32),

              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Component Helpers ---

  Widget _buildVerificationBanner() {
    bool isApproved = _verificationStatus == 'approved';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isApproved ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isApproved ? Colors.green[200]! : Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(isApproved ? Icons.verified_user : Icons.pending_actions,
              color: isApproved ? Colors.green[700] : Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isApproved ? 'Your facility is verified.' : 'Verification pending. You will appear online once approved.',
              style: TextStyle(fontWeight: FontWeight.w600, color: isApproved ? Colors.green[900] : Colors.orange[900]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00897B), width: 2)),
      ),
      validator: (v) => v?.isEmpty ?? true ? 'This field is required' : null,
    );
  }

  Widget _buildCertificateCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (_newCertificateImage != null)
              ListTile(leading: const Icon(Icons.file_present, color: Colors.green), title: Text(_newCertificateImage!.path.split('/').last))
            else if (_existingCertUrl != null)
              const ListTile(leading: Icon(Icons.check_circle, color: Color(0xFF00897B)), title: Text("Certificate Uploaded")),
            TextButton.icon(onPressed: _pickCertificate, icon: const Icon(Icons.upload_file), label: const Text('Update Certificate')),
          ],
        ),
      ),
    );
  }

  Widget _buildFacilityPhotosCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Wrap(
              spacing: 8, runSpacing: 8,
              children: [
                ..._existingFacilityUrls.map((url) => _buildPhotoThumbnail(Image.network(url, fit: BoxFit.cover))),
                ..._newFacilityImages.map((file) => _buildPhotoThumbnail(Image.file(file, fit: BoxFit.cover), onRemove: () => setState(() => _newFacilityImages.remove(file)))),
              ],
            ),
            const SizedBox(height: 8),
            TextButton.icon(onPressed: _pickFacilityImages, icon: const Icon(Icons.add_a_photo), label: const Text('Add Facility Photos')),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(Widget child, {VoidCallback? onRemove}) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 70, height: 70, child: child)),
        if (onRemove != null)
          GestureDetector(onTap: onRemove, child: const CircleAvatar(radius: 10, backgroundColor: Colors.white, child: Icon(Icons.close, size: 14, color: Colors.red))),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.teal[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _updateLocation,
            icon: const Icon(Icons.my_location),
            label: const Text('Sync Current GPS'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: TextFormField(controller: _latController, decoration: const InputDecoration(labelText: 'Lat', isDense: true))),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _lonController, decoration: const InputDecoration(labelText: 'Lon', isDense: true))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton(
      onPressed: _isSaving ? null : _saveProfile,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00897B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('SAVE CHANGES', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}