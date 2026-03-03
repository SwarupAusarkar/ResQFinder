import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // Added missing import
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _nmcIdController = TextEditingController();
  final _hfrIdController = TextEditingController();

  String _selectedType = 'hospital';
  bool _isLoading = false;

  // File Holders
  File? _certificateImage;
  final List<File> _facilityImages = [];

  @override
  void dispose() {
    _nameController.dispose(); _phoneController.dispose(); _emailController.dispose();
    _passwordController.dispose(); _addressController.dispose(); _descriptionController.dispose();
    _latController.dispose(); _lonController.dispose(); _nmcIdController.dispose();
    _hfrIdController.dispose();
    super.dispose();
  }

  // --- Image Picking Methods ---
  Future<void> _pickCertificate() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (pickedFile != null) setState(() => _certificateImage = File(pickedFile.path));
  }

  Future<void> _pickFacilityImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 80);
    if (pickedFiles.isNotEmpty) {
      setState(() => _facilityImages.addAll(pickedFiles.map((xfile) => File(xfile.path))));
    }
  }

  // --- Registration Logic ---
  Future<void> _startRegistrationFlow() async {
    if (!_formKey.currentState!.validate()) return;

    if (_latController.text.isEmpty) {
      _showSnackBar('Please capture clinic location first.', Colors.orange);
      return;
    }
    if (_certificateImage == null) {
      _showSnackBar('Upload your Facility Certificate to proceed.', Colors.orange);
      return;
    }
    if (_facilityImages.length < 5) {
      _showSnackBar('Minimum 5 facility photos required. Current: ${_facilityImages.length}', Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    // Format phone to E.164 for Firebase (e.g. +919876543210)
    String phone = _phoneController.text.trim();
    if (!phone.startsWith('+')) phone = '+91$phone';

    try {
      await _authService.startPhoneVerification(
        phoneNumber: phone,
        onCodeSent: (verificationId, resendToken) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId, phone);
        },
        onVerificationFailed: (e) {
          setState(() => _isLoading = false);
          _showSnackBar("Verification Failed: ${e.message}", Colors.red);
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar(e.toString(), Colors.red);
    }
  }

  void _showOtpDialog(String verificationId, String phone) {
    final otpController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Verify Phone"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the 6-digit code sent to $phone"),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(letterSpacing: 8, fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: "000000", border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finalizeRegistration(verificationId, otpController.text.trim());
            },
            child: const Text("Verify & Register"),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizeRegistration(String verificationId, String smsCode) async {
    setState(() => _isLoading = true);
    try {
      await _authService.registerWithVerifiedPhone(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        verificationId: verificationId,
        smsCode: smsCode,
        fullName: _nameController.text.trim(),
        userType: 'provider',
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        latitude: double.parse(_latController.text),
        longitude: double.parse(_lonController.text),
        providerType: _selectedType,
        description: _descriptionController.text.trim(),
        hfrId: _hfrIdController.text.trim(),
        nmcId: _nmcIdController.text.trim(),
        certificateImage: _certificateImage,
        facilityImages: _facilityImages,
      );

      if (mounted) Navigator.pushReplacementNamed(context, '/provider_guard');
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showSnackBar(e.toString(), Colors.red);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF00897B);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Provider Registration'), backgroundColor: themeColor, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('1. Document Verification', themeColor),
              const Text("Upload facility registration certificate (PDF/Image)", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              _buildUploadButton(
                  onPressed: _pickCertificate,
                  label: _certificateImage == null ? 'Upload Certificate *' : 'Certificate Attached',
                  isDone: _certificateImage != null
              ),

              const SizedBox(height: 24),
              _buildSectionTitle('2. Facility Photos', themeColor),
              const Text("Minimum 5 photos required (Exterior, Reception, Wards).", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 12),
              _buildUploadButton(
                  onPressed: _pickFacilityImages,
                  label: 'Add Photos (${_facilityImages.length}/5)',
                  isDone: _facilityImages.length >= 5
              ),
              if (_facilityImages.isNotEmpty) _buildImagePreviewGrid(),

              const SizedBox(height: 24),
              _buildSectionTitle('3. Identity & Medical IDs', themeColor),
              _buildTextField(_nmcIdController, 'NMC ID (Medical Council No.)', Icons.badge),
              const SizedBox(height: 12),
              _buildTextField(_hfrIdController, 'HFR ID (Facility Reg No.)', Icons.local_hospital),
              const SizedBox(height: 12),
              _buildTextField(_nameController, 'Facility Name', Icons.business),
              const SizedBox(height: 12),
              _buildTextField(_emailController, 'Official Email', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Phone (e.g. 9876543210)', Icons.phone, type: TextInputType.phone),

              const SizedBox(height: 24),
              _buildSectionTitle('4. Location & Services', themeColor),
              _buildLocationCapture(themeColor),
              const SizedBox(height: 12),
              _buildTextField(_addressController, 'Full Address', Icons.map),
              const SizedBox(height: 12),
              _buildTextField(_descriptionController, 'Brief Description', Icons.description, maxLines: 3),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _startRegistrationFlow,
                  style: ElevatedButton.styleFrom(backgroundColor: themeColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('VERIFY & CREATE ACCOUNT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Builders ---
  Widget _buildSectionTitle(String title, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 8.0),
    child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
  );

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType? type, int maxLines = 1, bool obscure = false}) {
    return TextFormField(
      controller: controller, keyboardType: type, maxLines: maxLines, obscureText: obscure,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
      validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
    );
  }

  Widget _buildUploadButton({required VoidCallback onPressed, required String label, bool isDone = false}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(isDone ? Icons.check_circle : Icons.upload),
      label: Text(label),
      style: OutlinedButton.styleFrom(
          foregroundColor: isDone ? Colors.green : Colors.red,
          side: BorderSide(color: isDone ? Colors.green : Colors.red),
          padding: const EdgeInsets.all(16)
      ),
    );
  }

  Widget _buildImagePreviewGrid() {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Wrap(
        spacing: 8, runSpacing: 8,
        children: _facilityImages.map((file) => ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(file, width: 60, height: 60, fit: BoxFit.cover),
        )).toList(),
      ),
    );
  }

  Widget _buildLocationCapture(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.gps_fixed),
            label: Text(_latController.text.isEmpty ? 'Capture GPS Location' : 'Location Captured'),
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
          ),
          if (_latController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Lat: ${_latController.text}, Lon: ${_lonController.text}", style: const TextStyle(fontSize: 10)),
            )
        ],
      ),
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final pos = await Geolocator.getCurrentPosition();
      setState(() { _latController.text = pos.latitude.toString(); _lonController.text = pos.longitude.toString(); });
    } catch (e) {
      _showSnackBar("Location Error: $e", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
}