import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'OTP_verification_screen.dart';

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
  bool _isEmailLogin = true;
  bool _obscurePassword = true;

  static const _teal = Color(0xFF0D9488);
  static const _bgColor = Color(0xFFF0F9F8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _formattedPhone {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) return phone;
    phone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.length == 10 && !phone.startsWith('+')) return '+91$phone';
    return phone;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleEmailLogin() async {
    await _authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _startPhoneLoginFlow() async {
    final phone = _formattedPhone;
    await _authService.startPhoneVerification(
      phoneNumber: phone,
      isLogin: true,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: verificationId,
                isLogin: true,
                formattedPhone: _formattedPhone,
              ),
            ),
          );
        }
      },
      onVerificationFailed: (e) => _onAuthError(e.message),
    );
  }

  Future<void> _startRegistrationFlow(String userType) async {
    final phone = _formattedPhone;
    await _authService.startPhoneVerification(
      phoneNumber: phone,
      isLogin: false,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OtpVerificationScreen(
                verificationId: verificationId,
                isLogin: false,
                userType: userType,
                formattedPhone: _formattedPhone,
                email: _emailController.text.trim(),
                password: _passwordController.text.trim(),
                fullName: _nameController.text.trim(),
              ),
            ),
          );
        }
      },
      onVerificationFailed: (e) => _onAuthError(e.message),
    );
  }

  void _onAuthError(String? message) {
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $message"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userType = args?['userType'] ?? 'requester';
    final isAdmin = userType == 'admin';

    return Scaffold(
      backgroundColor: _bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 20, 28, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _AuthLogo(),
                    const SizedBox(height: 40),

                    if (_isLoginMode) ...[
                      if (!isAdmin) ...[
                        _LoginToggle(
                          isEmail: _isEmailLogin,
                          onToggle: (v) => setState(() => _isEmailLogin = v),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_isEmailLogin || isAdmin) ...[
                        _AuthField(controller: _emailController, hint: 'Email Address', icon: Icons.email_outlined),
                        const SizedBox(height: 14),
                        _PasswordField(
                          controller: _passwordController,
                          obscure: _obscurePassword,
                          onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text('Forgot Password?', style: TextStyle(color: _teal, fontWeight: FontWeight.w600, fontSize: 13)),
                          ),
                        ),
                      ] else ...[
                        _AuthField(controller: _phoneController, hint: 'Phone Number', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                      ],
                    ],

                    if (!_isLoginMode) ...[
                      _AuthField(controller: _nameController, hint: 'Full Name', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 14),
                      _AuthField(controller: _phoneController, hint: 'Phone Number (10 digits)', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      _AuthField(controller: _emailController, hint: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: _passwordController,
                        obscure: _obscurePassword,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ],

                    const SizedBox(height: 28),

                    _PrimaryButton(
                      label: _isLoginMode ? (_isEmailLogin || isAdmin ? 'Sign In' : 'Send OTP') : 'Verify & Register',
                      isLoading: _isLoading,
                      onTap: () => _submitForm(userType),
                    ),

                    const SizedBox(height: 20),

                    if (!isAdmin)
                      _ToggleRow(
                        isLogin: _isLoginMode,
                        onToggle: () => setState(() => _isLoginMode = !_isLoginMode),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: const Color(0xFF0D4F4A), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.medical_services_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text('EMERGEO', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0D4F4A), letterSpacing: 2)),
      ],
    );
  }
}

class _LoginToggle extends StatelessWidget {
  final bool isEmail;
  final void Function(bool) onToggle;
  const _LoginToggle({required this.isEmail, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: Row(
        children: [
          _Tab(label: 'Email / Password', selected: isEmail, onTap: () => onToggle(true)),
          _Tab(label: 'Phone OTP', selected: !isEmail, onTap: () => onToggle(false)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(color: selected ? const Color(0xFF0D9488) : Colors.transparent, borderRadius: BorderRadius.circular(9)),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey[500])),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;

  const _AuthField({required this.controller, required this.hint, required this.icon, this.keyboardType});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: TextFormField(
        controller: controller, keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: hint, hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;

  const _PasswordField({required this.controller, required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
      child: TextFormField(
        controller: controller, obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: 'Password', hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey[400]),
          suffixIcon: IconButton(icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey[400]), onPressed: onToggle),
          border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback onTap;

  const _PrimaryButton({required this.label, required this.isLoading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: double.infinity, height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final bool isLogin;
  final VoidCallback onToggle;
  const _ToggleRow({required this.isLogin, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isLogin ? "Don't have an account? " : "Have an account? ", style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        GestureDetector(onTap: onToggle, child: Text(isLogin ? 'Sign Up' : 'Login', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)))),
      ],
    );
  }
}