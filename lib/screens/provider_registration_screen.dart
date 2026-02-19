import 'package:flutter/material.dart';
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
  
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _hfrController = TextEditingController();
  final _nmcController = TextEditingController();

  String _selectedType = 'hospital';
  String _verificationMethod = 'HFR'; 
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose(); _emailController.dispose(); _passwordController.dispose();
    _phoneController.dispose(); _addressController.dispose(); _descriptionController.dispose();
    _latController.dispose(); _lonController.dispose(); _hfrController.dispose(); _nmcController.dispose();
    super.dispose();
  }

  // --- STEP 1: TRIGGER OTP ---
  Future<void> _startRegistrationFlow() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latController.text.isEmpty || _lonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please capture clinic location first.')));
      return;
    }

    setState(() => _isLoading = true);
    final phone = _phoneController.text.trim();

    try {
      await _authService.startPhoneVerification(
        phoneNumber: phone,
        onCodeSent: (verificationId, resendToken) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId); // Show Dialog when SMS is sent
        },
        onVerificationFailed: (e) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Verification Failed: ${e.message}"), backgroundColor: Colors.red));
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    }
  }

  // --- STEP 2: SHOW DIALOG ---
  void _showOtpDialog(String verificationId) {
    final otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Verify Phone Number"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the 6-digit code sent to ${_phoneController.text}"),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "OTP Code", border: OutlineInputBorder()),
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

  // --- STEP 3: CREATE ACCOUNT ---
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
        hfrId: _verificationMethod == 'HFR' ? _hfrController.text.trim() : null,
        nmcId: _verificationMethod == 'NMC' ? _nmcController.text.trim() : null,
        isHFRVerified: false,
        isNMCVerified: false,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/provider-dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    }
  }

  // ... (Keep your exact build() and _getCurrentLocation() methods from your previous code here) ...
  // JUST ENSURE the ElevatedButton calls `_startRegistrationFlow` instead of `_register`

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Provider Registration'), backgroundColor: Colors.green),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('1. Verification Details'),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'HFR', label: Text('HFR (Facility)'), icon: Icon(Icons.local_hospital)),
                  ButtonSegment(value: 'NMC', label: Text('NMC (Doctor)'), icon: Icon(Icons.person)),
                ],
                selected: {_verificationMethod},
                onSelectionChanged: (val) => setState(() => _verificationMethod = val.first),
              ),
              const SizedBox(height: 16),
              if (_verificationMethod == 'HFR')
                _buildTextField(_hfrController, 'HFR ID', Icons.badge, required: true)
              else
                _buildTextField(_nmcController, 'NMC Registration No.', Icons.medical_services, required: true),

              const SizedBox(height: 24),
              _buildSectionTitle('2. Facility Information'),
              const SizedBox(height: 12),
              _buildTextField(_nameController, 'Facility/Provider Name', Icons.business),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Facility Type', border: OutlineInputBorder()),
                items: ['hospital', 'clinic', 'pharmacy', 'blood_bank'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                onChanged: (v) => setState(() => _selectedType = v!),
              ),
              const SizedBox(height: 12),
              
              // PHONE MUST BE CORRECT FORMAT (+91...)
              _buildTextField(_phoneController, 'Contact Phone (+91...)', Icons.phone, type: TextInputType.phone),
              
              const SizedBox(height: 12),
              _buildTextField(_emailController, 'Official Email', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _buildTextField(_passwordController, 'Password', Icons.lock, obscure: true),
              const SizedBox(height: 12),
              _buildTextField(_addressController, 'Physical Address', Icons.map),
              const SizedBox(height: 12),
              _buildTextField(_descriptionController, 'Services Description', Icons.description, maxLines: 3),

              const SizedBox(height: 24),
              _buildSectionTitle('3. Location'),
              const SizedBox(height: 12),
              _buildLocationSection(),

              const SizedBox(height: 32),
              ElevatedButton(
                // CALLS THE NEW OTP FLOW
                onPressed: _isLoading ? null : _startRegistrationFlow, 
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('VERIFY PHONE & REGISTER'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Keep these helper methods from your previous code
  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ElevatedButton.icon(
            onPressed: _getCurrentLocation,
            icon: const Icon(Icons.gps_fixed),
            label: const Text('Capture Current Location'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildTextField(_latController, 'Latitude', Icons.location_on, enabled: false)),
              const SizedBox(width: 12),
              Expanded(child: _buildTextField(_lonController, 'Longitude', Icons.location_on, enabled: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool obscure = false, TextInputType? type, int maxLines = 1, bool enabled = true, bool required = true}) {
    return TextFormField(
      controller: controller, obscureText: obscure, keyboardType: type, maxLines: maxLines, enabled: enabled,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), filled: !enabled, fillColor: enabled ? null : Colors.grey[200]),
      validator: required ? (v) => (v == null || v.isEmpty) ? '$label required' : null : null,
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'Location services disabled.';
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Permissions denied.';
      }
      final pos = await Geolocator.getCurrentPosition();
      setState(() { _latController.text = pos.latitude.toString(); _lonController.text = pos.longitude.toString(); });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => _isLoading = false);
    }
  }
}