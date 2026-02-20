import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(); 

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isEmailLogin = true; // NEW: Toggle between Email / Phone login
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  // NEW: Smart formatter that auto-appends +91 if missing
  String get _formattedPhone {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) return phone;
    if (phone.startsWith('+')) return phone;
    
    // Strip everything but numbers
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) {
      return '+91$phone';
    } else if (phone.length == 12 && phone.startsWith('91')) {
      return '+$phone';
    }
    return '+$phone'; // Fallback
  }

  Future<void> _submitForm(String userType) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isLoginMode) {
        if (_isEmailLogin) {
          await _handleEmailLogin();
        } else {
          await _startPhoneLoginFlow();
        }
      } else {
        await _startRegistrationFlow(userType);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    final user = await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (user != null && mounted) {
      if (user.email == 'admin@resqfinder.com') {
        Navigator.pushReplacementNamed(context, '/admin-dashboard');
        return; 
      }
      final userDoc = await _authService.getUserData(user.uid);
      if (userDoc != null && userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        Navigator.pushReplacementNamed(context, userData['userType'] == 'provider' ? '/provider-dashboard' : '/service-selection');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile not found. Please register."), backgroundColor: Colors.red));
        await _authService.signOut();
      }
    }
  }

  Future<void> _startPhoneLoginFlow() async {
    final phone = _formattedPhone;
    if (phone.isEmpty) return;

    await _authService.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId, null, isLogin: true);
        }
      },
      onVerificationFailed: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.message}"), backgroundColor: Colors.red));
        }
      },
    );
  }

  Future<void> _startRegistrationFlow(String userType) async {
    final phone = _formattedPhone;
    
    await _authService.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId, userType, isLogin: false);
        }
      },
      onVerificationFailed: (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed: ${e.message}"), backgroundColor: Colors.red));
        }
      },
    );
  }

  void _showOtpDialog(String verificationId, String? userType, {required bool isLogin}) {
    final otpController = TextEditingController();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(isLogin ? "Login OTP" : "Verify Phone"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Enter the 6-digit code sent to $_formattedPhone"),
            const SizedBox(height: 16),
            TextField(controller: otpController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "OTP Code", border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); 
              if (isLogin) {
                _finalizePhoneLogin(verificationId, otpController.text.trim());
              } else {
                _finalizeRegistration(verificationId, otpController.text.trim(), userType!);
              }
            },
            child: Text(isLogin ? "Verify & Login" : "Verify & Register"),
          ),
        ],
      ),
    );
  }

  Future<void> _finalizePhoneLogin(String verificationId, String smsCode) async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.signInWithPhone(verificationId: verificationId, smsCode: smsCode);
      if (user != null && mounted) {
        final userDoc = await _authService.getUserData(user.uid);
        if (userDoc != null && userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          Navigator.pushReplacementNamed(context, userData['userType'] == 'provider' ? '/provider-dashboard' : '/service-selection');
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile not found. Please register."), backgroundColor: Colors.red));
           await _authService.signOut();
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _finalizeRegistration(String verificationId, String smsCode, String userType) async {
    setState(() => _isLoading = true); 
    try {
      final user = await _authService.registerWithVerifiedPhone(
        email: _emailController.text.trim(), password: _passwordController.text.trim(),
        verificationId: verificationId, smsCode: smsCode,
        fullName: _nameController.text.trim(), userType: userType,
        phone: _formattedPhone, // Validated Phone
      );

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, userType == 'provider' ? '/manage-services' : '/service-selection');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userType = args?['userType'] ?? 'requester';
    final isProvider = userType == 'provider';

    return Scaffold(
      appBar: AppBar(title: Text(isProvider ? 'Medical Provider Portal' : 'Citizen Sign In'), backgroundColor: isProvider ? Colors.green : Colors.blue, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text(_isLoginMode ? 'Welcome Back' : 'Join the Network', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 30),

              // LOGIN TOGGLE
              if (_isLoginMode) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ChoiceChip(label: const Text('Email'), selected: _isEmailLogin, onSelected: (val) => setState(() => _isEmailLogin = true)),
                    const SizedBox(width: 16),
                    ChoiceChip(label: const Text('Phone OTP'), selected: !_isEmailLogin, onSelected: (val) => setState(() => _isEmailLogin = false)),
                  ],
                ),
                const SizedBox(height: 24),
              ],

              // DYNAMIC FORM FIELDS
              if (!_isLoginMode) ...[
                _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Phone Number (10 digits)', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock_outlined, isPassword: true),
                const SizedBox(height: 16),
              ] else if (_isLoginMode && _isEmailLogin) ...[
                _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock_outlined, isPassword: true),
                const SizedBox(height: 16),
              ] else if (_isLoginMode && !_isEmailLogin) ...[
                _buildTextField(_phoneController, 'Phone Number (10 digits)', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isLoading ? null : () => _submitForm(userType),
                style: ElevatedButton.styleFrom(backgroundColor: isProvider ? Colors.green : Colors.blue, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : Text(_isLoginMode ? 'SIGN IN' : 'VERIFY & REGISTER', style: const TextStyle(color: Colors.white)),
              ),

              TextButton(onPressed: () => setState(() => _isLoginMode = !_isLoginMode), child: Text(_isLoginMode ? 'New here? Create account' : 'Have an account? Login')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller, obscureText: isPassword && _obscurePassword, keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label, prefixIcon: Icon(icon),
        suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
    );
  }
}