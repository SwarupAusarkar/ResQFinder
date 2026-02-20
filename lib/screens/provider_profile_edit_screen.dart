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

  // Image handling
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location updated!'), backgroundColor: Colors.green));
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

      // Upload New Certificate
      if (_newCertificateImage != null) {
        String ext = path.extension(_newCertificateImage!.path); // gets '.pdf' or '.jpg'
        final ref = FirebaseStorage.instance.ref().child('provider_certs/${user.uid}_cert$ext');
        await ref.putFile(_newCertificateImage!);
        finalCertUrl = await ref.getDownloadURL();
      }

      // Upload New Facility Images
      for (int i = 0; i < _newFacilityImages.length; i++) {
        final ref = FirebaseStorage.instance.ref().child('provider_facilities/${user.uid}/fac_img_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await ref.putFile(_newFacilityImages[i]);
        String url = await ref.getDownloadURL();
        finalFacilityUrls.add(url);
      }

      // Save everything to Firestore
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green));
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
      appBar: AppBar(title: const Text('Edit Profile'), backgroundColor: Colors.green, foregroundColor: Colors.white),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // VERIFICATION STATUS BANNER
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _verificationStatus == 'approved' ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(_verificationStatus == 'approved' ? Icons.check_circle : Icons.pending, 
                               color: _verificationStatus == 'approved' ? Colors.green : Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _verificationStatus == 'approved' 
                                  ? 'Your facility is verified and online.' 
                                  : 'Account pending admin verification. You cannot receive requests yet.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: _verificationStatus == 'approved' ? Colors.green[800] : Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- DOCUMENT UPLOADS SECTION ---
                    const Text('Verification Documents', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 12),
                    
                    // Certificate
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Facility Certificate', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            if (_existingCertUrl != null && _newCertificateImage == null)
                            const ListTile(
                              leading: Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
                              title: Text("Certificate Uploaded"),
                              subtitle: Text("Stored in Database"),
                            )
                          else if (_newCertificateImage != null)
                            ListTile(
                              leading: const Icon(Icons.upload_file, color: Colors.green, size: 40),
                              title: Text("New File Selected"),
                              subtitle: Text(_newCertificateImage!.path.split('/').last),
                            ),
                            TextButton.icon(
                              onPressed: _pickCertificate,
                              icon: const Icon(Icons.upload_file),
                              label: const Text('Upload New Certificate'),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Facility Photos
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Facility Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: [
                                // Show existing network images
                                ..._existingFacilityUrls.map((url) => ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(url, width: 70, height: 70, fit: BoxFit.cover))),
                                // Show newly picked local images
                                ..._newFacilityImages.map((file) => Stack(
                                  alignment: Alignment.topRight,
                                  children: [
                                    ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(file, width: 70, height: 70, fit: BoxFit.cover)),
                                    GestureDetector(
                                      onTap: () => setState(() => _newFacilityImages.remove(file)),
                                      child: Container(decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white), child: const Icon(Icons.cancel, color: Colors.red, size: 20)),
                                    )
                                  ],
                                )),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _pickFacilityImages,
                              icon: const Icon(Icons.add_a_photo),
                              label: const Text('Add More Photos'),
                            )
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- BASIC INFO SECTION ---
                    const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 12),
                    TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Provider Name', prefixIcon: const Icon(Icons.business), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _addressController, maxLines: 2, decoration: InputDecoration(labelText: 'Address', prefixIcon: const Icon(Icons.location_on), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v?.isEmpty ?? true ? 'Required' : null),
                    const SizedBox(height: 16),
                    TextFormField(controller: _descriptionController, maxLines: 3, decoration: InputDecoration(labelText: 'Description', prefixIcon: const Icon(Icons.description), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
                    const SizedBox(height: 24),

                    // --- LOCATION SECTION ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue[200]!)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [Icon(Icons.my_location, color: Colors.blue[700]), const SizedBox(width: 8), Text('Location', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]))]),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(onPressed: _isSaving ? null : _updateLocation, icon: const Icon(Icons.gps_fixed), label: const Text('Update Current Location'), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 45))),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _latController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder(), isDense: true), validator: (v) => v?.isEmpty ?? true ? 'Required' : null)),
                              const SizedBox(width: 12),
                              Expanded(child: TextFormField(controller: _lonController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder(), isDense: true), validator: (v) => v?.isEmpty ?? true ? 'Required' : null)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes & Upload', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}