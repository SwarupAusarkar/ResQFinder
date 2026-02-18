import 'package:flutter/material.dart';
import '../services/auth_service.dart';
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); // NEW
  final _hfrController = TextEditingController();
  final _nmcController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _hfrController.dispose();
    _nmcController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ⚡ ACTION: SUBMIT FORM
  // ---------------------------------------------------------------------------
  Future<void> _submitForm(String userType) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        // --- LOGIN FLOW (Standard) ---
        await _handleLogin();
      } else {
        // --- REGISTRATION FLOW (OTP Gatekeeper) ---
        await _startRegistrationFlow(userType);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic for Login
  Future<void> _handleLogin() async {
    final user = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (user != null && mounted) {
      final userDoc = await _authService.getUserData(user.uid);

      if (userDoc != null && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        final actualUserType = userData['userType'];
        
        if (actualUserType == 'provider') {
          Navigator.pushReplacementNamed(context, '/provider-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/service-selection');
        }
      }
    }
  }

  // Logic for Registration Trigger
  Future<void> _startRegistrationFlow(String userType) async {
    final phone = _phoneController.text.trim();
    
    // 1. Trigger OTP
    await _authService.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        // 2. Hide Loader & Show Dialog
        setState(() => _isLoading = false);
        _showOtpDialog(verificationId, userType);
      },
      onVerificationFailed: (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Verification Failed: ${e.message}"), backgroundColor: Colors.red),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 💬 UI: OTP DIALOG
  // ---------------------------------------------------------------------------
  void _showOtpDialog(String verificationId, String userType) {
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
              decoration: const InputDecoration(
                labelText: "OTP Code",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              _finalizeRegistration(verificationId, otpController.text.trim(), userType);
            },
            child: const Text("Verify & Register"),
          ),
        ],
      ),
    );
  }

  // Logic to actually create the account after OTP is entered
  Future<void> _finalizeRegistration(String verificationId, String smsCode, String userType) async {
    setState(() => _isLoading = true); // Show loader again

    try {
      final isProvider = userType == 'provider';
      
      final user = await _authService.registerWithVerifiedPhone(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        verificationId: verificationId,
        smsCode: smsCode,
        fullName: _nameController.text.trim(),
        userType: userType,
        phone: _phoneController.text.trim(),
        
        // Optional Provider Fields
        hfrId: isProvider ? _hfrController.text.trim() : null,
        nmcId: isProvider ? _nmcController.text.trim() : null,
        isHFRVerified: isProvider ? false : null,
        isNMCVerified: isProvider ? false : null,
        
        // Placeholders for now
        address: '',
        latitude: 0.0,
        longitude: 0.0,
        providerType: isProvider ? 'hospital' : '',
        description: '',
      );

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(
          context, 
          userType == 'provider' ? '/manage-services' : '/service-selection'
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 🎨 UI BUILD
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userType = args?['userType'] ?? 'requester';
    final isProvider = userType == 'provider';

    return Scaffold(
      appBar: AppBar(
        title: Text(isProvider ? 'Medical Provider Portal' : 'Citizen Sign In'),
        backgroundColor: isProvider ? Colors.green : Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... Header Text ...
              const SizedBox(height: 20),
              Text(
                _isLoginMode ? 'Welcome Back' : 'Join the Network',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),

              // Full Name (Register Only)
              if (!_isLoginMode) ...[
                _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                
                // NEW: Phone Number Field
                 _buildTextField(
                  _phoneController, 
                  'Phone Number (+91...)', 
                  Icons.phone,
                  keyboardType: TextInputType.phone
                ),
                const SizedBox(height: 16),
              ],

              _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildTextField(_passwordController, 'Password', Icons.lock_outlined, isPassword: true),
              const SizedBox(height: 16),

              // Provider IDs (Register Only)
              if (!_isLoginMode && isProvider) ...[
                const Divider(height: 40),
                const Text("Professional Credentials", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                const SizedBox(height: 12),
                _buildTextField(_hfrController, 'HFR Facility ID', Icons.account_balance_outlined),
                const SizedBox(height: 16),
                _buildTextField(_nmcController, 'NMC Registration No.', Icons.medical_services_outlined),
                const SizedBox(height: 24),
              ],

              ElevatedButton(
                onPressed: _isLoading ? null : () => _submitForm(userType),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isProvider ? Colors.green : Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : Text(_isLoginMode ? 'SIGN IN' : 'VERIFY & REGISTER'),
              ),

              TextButton(
                onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
                child: Text(_isLoginMode ? 'New here? Create account' : 'Have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: isPassword 
          ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
          : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
    );
  }
}