
//
// import 'package:flutter/material.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
// import '../services/auth_service.dart';
// import 'OTP_verification_screen.dart';
//
// class AuthScreen extends StatefulWidget {
//   const AuthScreen({super.key});
//
//   @override
//   State<AuthScreen> createState() => _AuthScreenState();
// }
//
// class _AuthScreenState extends State<AuthScreen> {
//   final _formKey = GlobalKey<FormState>();
//
//   // Controllers
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _nameController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _hfrController = TextEditingController();
//   final _nmcController = TextEditingController();
//
//   final AuthService _authService = AuthService();
//
//   bool _isLoading = false;
//   bool _isLoginMode = true;
//   bool _isEmailLogin = true;
//   bool _obscurePassword = true;
//
//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     _nameController.dispose();
//     _phoneController.dispose();
//     _hfrController.dispose();
//     _nmcController.dispose();
//     super.dispose();
//   }
//
//   // Smart formatter that auto-appends +91 if missing
//   String get _formattedPhone {
//     String phone = _phoneController.text.trim();
//     if (phone.isEmpty) return phone;
//     if (phone.startsWith('+')) return phone;
//
//     phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
//     if (phone.length == 10) {
//       return '+91$phone';
//     }
//     return '+$phone';
//   }
//
//   Future<void> _submitForm(String userType) async {
//     if (!_formKey.currentState!.validate()) return;
//     setState(() => _isLoading = true);
//
//     try {
//       if (_isLoginMode) {
//         if (_isEmailLogin) {
//           await _handleEmailLogin();
//         } else {
//           await _startPhoneLoginFlow();
//         }
//       } else {
//         await _startRegistrationFlow(userType);
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   Future<void> _handleEmailLogin() async {
//     final user = await _authService.signIn(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );
//
//     if (user != null && mounted) {
//       if (user.email == 'admin@resqfinder.com') {
//         Navigator.pushReplacementNamed(context, '/admin-dashboard');
//         return;
//       }
//       final userDoc = await _authService.getUserData(user.uid);
//       if (userDoc != null && userDoc.exists) {
//         final userData = userDoc.data() as Map<String, dynamic>;
//         Navigator.pushReplacementNamed(context, userData['userType'] == 'provider' ? '/provider-dashboard' : '/service-selection');
//       }
//     }
//   }
//
//   Future<void> _startPhoneLoginFlow() async {
//     final phone = _formattedPhone;
//     await _authService.startPhoneVerification(
//       phoneNumber: phone,
//       onCodeSent: (verificationId, resendToken) {
//         if (mounted) {
//           setState(() => _isLoading = false);
//           _showOtpDialog(verificationId, null, isLogin: true);
//         }
//       },
//       onVerificationFailed: (e) => _onAuthError(e.message),
//     );
//   }
//
//   Future<void> _startRegistrationFlow(String userType) async {
//     final phone = _formattedPhone;
//     await _authService.startPhoneVerification(
//       phoneNumber: phone,
//       onCodeSent: (verificationId, resendToken) {
//         if (mounted) {
//           setState(() => _isLoading = false);
//           // Navigator.push(
//           //   context,
//           //   MaterialPageRoute(
//           //     builder: (_) => OtpVerificationScreen(
//           //       verificationId: verificationId,
//           //       isLogin: false,
//           //       userType: userType,
//           //       formattedPhone: _formattedPhone,
//           //     ),
//           //   ),
//           // );
//            _showOtpDialog(verificationId, userType, isLogin: false);
//         }
//       },
//       onVerificationFailed: (e) => _onAuthError(e.message),
//     );
//   }
//
//   void _onAuthError(String? message) {
//     if (mounted) {
//       setState(() => _isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $message"), backgroundColor: Colors.red));
//     }
//   }
//
//   void _showOtpDialog(
//       String verificationId,
//       String? userType, {
//         required bool isLogin,
//       }) {
//     final otpController = TextEditingController();
//     bool isVerifying = false;
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       isDismissible: false,
//       enableDrag: false,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setState) => Container(
//           height: MediaQuery.of(context).size.height * 0.6,
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
//           ),
//           child: Padding(
//             padding: EdgeInsets.only(
//               left: 24,
//               right: 24,
//               top: 24,
//               bottom: MediaQuery.of(context).viewInsets.bottom + 24,
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 /// Drag Indicator
//                 Container(
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//
//                 /// Icon + Loader
//                 Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     if (isVerifying)
//                       const SizedBox(
//                         width: 80,
//                         height: 80,
//                         child: CircularProgressIndicator(
//                           strokeWidth: 3,
//                           valueColor: AlwaysStoppedAnimation<Color>(
//                             Color(0xFF00897B),
//                           ),
//                         ),
//                       ),
//                     Container(
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF00897B).withOpacity(0.1),
//                         shape: BoxShape.circle,
//                       ),
//                       child: const Icon(
//                         Icons.sms_outlined,
//                         size: 40,
//                         color: Color(0xFF00897B),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//
//                 /// Title
//                 Text(
//                   isLogin ? 'Login OTP' : 'Verify Phone',
//                   style: const TextStyle(
//                     fontSize: 24,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//
//                 /// Subtitle
//                 Text(
//                   'Enter the 6-digit code sent to $_formattedPhone',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey[600],
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//
//                 /// OTP Field
//                 TextField(
//                   controller: otpController,
//                   keyboardType: TextInputType.number,
//                   textAlign: TextAlign.center,
//                   maxLength: 6,
//                   enabled: !isVerifying,
//                   style: const TextStyle(
//                     fontSize: 32,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 16,
//                   ),
//                   decoration: InputDecoration(
//                     counterText: '',
//                     hintText: '------',
//                     hintStyle: TextStyle(
//                       color: Colors.grey[300],
//                       letterSpacing: 16,
//                     ),
//                     filled: true,
//                     fillColor: Colors.grey[50],
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: BorderSide.none,
//                     ),
//                     enabledBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide:
//                       BorderSide(color: Colors.grey[300]!),
//                     ),
//                     focusedBorder: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(12),
//                       borderSide: const BorderSide(
//                         color: Color(0xFF00897B),
//                         width: 2,
//                       ),
//                     ),
//                     contentPadding: const EdgeInsets.symmetric(
//                       vertical: 20,
//                       horizontal: 16,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 24),
//
//                 /// Verify Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: isVerifying
//                         ? null
//                         : () async {
//                       if (otpController.text.trim().length != 6) {
//                         ScaffoldMessenger.of(context)
//                             .showSnackBar(
//                           const SnackBar(
//                             content:
//                             Text('Please enter 6-digit code'),
//                             backgroundColor: Colors.red,
//                           ),
//                         );
//                         return;
//                       }
//
//                       setState(() => isVerifying = true);
//
//                       Navigator.pop(context);
//
//                       if (isLogin) {
//                         await _finalizePhoneLogin(
//                           verificationId,
//                           otpController.text.trim(),
//                         );
//                       } else {
//                         await _finalizeRegistration(
//                           verificationId,
//                           otpController.text.trim(),
//                           userType!,
//                         );
//                       }
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: const Color(0xFF00897B),
//                       disabledBackgroundColor:
//                       Colors.grey[300],
//                       padding:
//                       const EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius:
//                         BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: isVerifying
//                         ? const SizedBox(
//                       height: 20,
//                       width: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         valueColor:
//                         AlwaysStoppedAnimation<Color>(
//                             Colors.white),
//                       ),
//                     )
//                         : const Text(
//                       'VERIFY CODE',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 16),
//
//                 /// Cancel
//                 TextButton(
//                   onPressed:
//                   isVerifying ? null : () => Navigator.pop(context),
//                   child: Text(
//                     'Cancel',
//                     style: TextStyle(
//                       color: isVerifying
//                           ? Colors.grey
//                           : const Color(0xFF00897B),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<void> _finalizePhoneLogin(String verificationId, String smsCode) async {
//     setState(() => _isLoading = true);
//     try {
//       final user = await _authService.signInWithPhone(verificationId: verificationId, smsCode: smsCode);
//       if (user != null && mounted) {
//         final userDoc = await _authService.getUserData(user.uid);
//         if (userDoc != null && userDoc.exists) {
//           final userData = userDoc.data() as Map<String, dynamic>;
//           Navigator.pushReplacementNamed(context, userData['userType'] == 'provider' ? '/provider-dashboard' : '/service-selection');
//         }
//       }
//     } catch (e) { _onAuthError(e.toString()); }
//   }
//
//   Future<void> _finalizeRegistration(String verificationId, String smsCode, String userType) async {
//     setState(() => _isLoading = true);
//     try {
//       final user = await _authService.registerWithVerifiedPhone(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         verificationId: verificationId,
//         smsCode: smsCode,
//         fullName: _nameController.text.trim(),
//         userType: userType,
//         phone: _formattedPhone,
//         hfrId: userType == 'provider' ? _hfrController.text.trim() : null,
//         nmcId: userType == 'provider' ? _nmcController.text.trim() : null,
//       );
//
//       if (user != null && mounted) {
//         Navigator.pushReplacementNamed(context, userType == 'provider' ? '/manage-services' : '/service-selection');
//       }
//     } catch (e) { _onAuthError(e.toString()); }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
//     final userType = args?['userType'] ?? 'requester';
//     final isProvider = userType == 'provider';
//     final themeColor = const Color(0xFF00897B);
//
//     return Scaffold(
//       appBar: AppBar(title: Text(isProvider ? 'Medical Provider Portal' : 'Citizen Sign In'), backgroundColor: themeColor, foregroundColor: Colors.white),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               Text(_isLoginMode ? 'Welcome Back' : 'Join the Network', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
//               const SizedBox(height: 30),
//
//               if (_isLoginMode) ...[
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     ChoiceChip(label: const Text('Email'), selected: _isEmailLogin, onSelected: (val) => setState(() => _isEmailLogin = true)),
//                     const SizedBox(width: 16),
//                     ChoiceChip(label: const Text('Phone OTP'), selected: !_isEmailLogin, onSelected: (val) => setState(() => _isEmailLogin = false)),
//                   ],
//                 ),
//                 const SizedBox(height: 24),
//               ],
//
//               if (!_isLoginMode) ...[
//                 _buildTextField(_nameController, 'Full Name', Icons.person_outline),
//                 const SizedBox(height: 16),
//                 _buildTextField(_phoneController, 'Phone Number (10 digits)', Icons.phone, keyboardType: TextInputType.phone),
//                 const SizedBox(height: 16),
//                 if (isProvider) ...[
//                   _buildTextField(_hfrController, 'HFR Facility ID', Icons.account_balance),
//                   const SizedBox(height: 16),
//                   _buildTextField(_nmcController, 'NMC Doctor ID', Icons.verified_user),
//                   const SizedBox(height: 16),
//                 ],
//               ],
//
//               if (_isEmailLogin || !_isLoginMode) ...[
//                 _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
//                 const SizedBox(height: 16),
//                 _buildTextField(_passwordController, 'Password', Icons.lock_outlined, isPassword: true),
//                 const SizedBox(height: 16),
//               ],
//
//               if (_isLoginMode && !_isEmailLogin) ...[
//                 _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
//                 const SizedBox(height: 16),
//               ],
//
//               ElevatedButton(
//                 onPressed: _isLoading ? null : () => _submitForm(userType),
//                 style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 16)),
//                 child: _isLoading
//                     ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
//                     : Text(_isLoginMode ? 'SIGN IN' : 'VERIFY & REGISTER', style: const TextStyle(color: Colors.white)),
//               ),
//
//               TextButton(onPressed: () => setState(() => _isLoginMode = !_isLoginMode), child: Text(_isLoginMode ? 'New here? Create account' : 'Have an account? Login')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
//     return TextFormField(
//       controller: controller, obscureText: isPassword && _obscurePassword, keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label, prefixIcon: Icon(icon),
//         suffixIcon: isPassword ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)) : null,
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
//     );
//   }
// }
// lib/screens/auth_screen.dart

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

  // ── Controllers (unchanged) ──────────────────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hfrController = TextEditingController();
  final _nmcController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isEmailLogin = true;
  bool _obscurePassword = true;

  // ── Design tokens ────────────────────────────────────────────────────────────
  static const _teal = Color(0xFF0D9488);
  static const _tealDark = Color(0xFF0D4F4A);
  static const _bgColor = Color(0xFFF0F9F8);

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

  // ── Logic (ALL UNCHANGED) ─────────────────────────────────────────────────────
  String get _formattedPhone {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) return phone;
    if (phone.startsWith('+')) return phone;
    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) return '+91$phone';
    return '+$phone';
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
        final type = userData['userType'];
        if (type == 'provider') {
          Navigator.pushReplacementNamed(context, '/provider-dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/service-selection');
        }
      }
    }
  }

  Future<void> _startPhoneLoginFlow() async {
    final phone = _formattedPhone;
    await _authService.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showOtpDialog(verificationId, null, isLogin: true);
        }
      },
      onVerificationFailed: (e) => _onAuthError(e.message),
    );
  }

  Future<void> _startRegistrationFlow(String userType) async {
    final phone = _formattedPhone;
    await _authService.startPhoneVerification(
      phoneNumber: phone,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() => _isLoading = false);

          // Navigator.push(
          //   context,
          //   MaterialPageRoute(
          //     builder: (_) => OtpVerificationScreen(
          //       verificationId: verificationId,
          //       isLogin: false,
          //       userType: userType,
          //       formattedPhone: _formattedPhone,
          //     ),
          //   ),
          // );

          _showOtpDialog(verificationId, userType, isLogin: false);
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

  void _showOtpDialog(String verificationId, String? userType, {required bool isLogin}) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(context).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 32),
                Stack(alignment: Alignment.center, children: [
                  if (isVerifying) const SizedBox(width: 80, height: 80, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00897B)))),
                  Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: const Color(0xFF00897B).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.sms_outlined, size: 40, color: Color(0xFF00897B))),
                ]),
                const SizedBox(height: 24),
                const Text('Verify OTP', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Enter the 6-digit code', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(height: 24),
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !isVerifying,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, letterSpacing: 14),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: const TextStyle(color: Colors.grey, letterSpacing: 14),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF00897B), width: 2)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 18),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerifying ? null : () async {
                      if (otpController.text.trim().length != 6) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter 6-digit code'), backgroundColor: Colors.red));
                        return;
                      }
                      setSheetState(() => isVerifying = true);
                      Navigator.pop(context);
                      if (isLogin) {
                        await _finalizePhoneLogin(verificationId, otpController.text.trim());
                      } else {
                        await _finalizeRegistration(verificationId, otpController.text.trim(), userType!);
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: isVerifying
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('VERIFY CODE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(onPressed: isVerifying ? null : () => Navigator.pop(context), child: Text('Cancel', style: TextStyle(color: isVerifying ? Colors.grey : const Color(0xFF00897B), fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
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
          final type = userData['userType'];
          Navigator.pushReplacementNamed(context, type == 'provider' ? '/provider-main' : '/service-selection');
        }
      }
    } catch (e) { _onAuthError(e.toString()); }
  }

  Future<void> _finalizeRegistration(String verificationId, String smsCode, String userType) async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.registerWithVerifiedPhone(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        verificationId: verificationId,
        smsCode: smsCode,
        fullName: _nameController.text.trim(),
        userType: userType,
        phone: _formattedPhone,
        hfrId: userType == 'provider' ? _hfrController.text.trim() : null,
        nmcId: userType == 'provider' ? _nmcController.text.trim() : null, isHFRVerified: true, isNMCVerified: true,
      );
      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, userType == 'provider' ? '/offer-approval' : '/service-selection');
      }
    } catch (e) { _onAuthError(e.toString()); }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userType = args?['userType'] ?? 'requester';
    final isAdmin = userType == 'admin';
    final isProvider = userType == 'provider';

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

                    // ── Login form fields ──────────────────────────────────────
                    if (_isLoginMode) ...[
                      // Toggle email / phone (not shown for admin)
                      if (!isAdmin) ...[
                        _LoginToggle(
                          isEmail: _isEmailLogin,
                          onToggle: (v) => setState(() => _isEmailLogin = v),
                        ),
                        const SizedBox(height: 24),
                      ],
                      if (_isEmailLogin || isAdmin) ...[
                        _AuthField(
                          controller: _emailController,
                          hint: 'Email Address',
                          icon: Icons.email_outlined,
                        ),
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
                        _AuthField(
                          controller: _phoneController,
                          hint: 'Phone Number',
                          icon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                        ),
                      ],
                    ],

                    // ── Register form fields ───────────────────────────────────
                    if (!_isLoginMode) ...[
                      _AuthField(controller: _nameController, hint: 'Full Name', icon: Icons.person_outline_rounded),
                      const SizedBox(height: 14),
                      _AuthField(controller: _phoneController, hint: 'Phone Number (10 digits)', icon: Icons.phone_outlined, keyboardType: TextInputType.phone),
                      const SizedBox(height: 14),
                      if (isProvider) ...[
                        _AuthField(controller: _hfrController, hint: 'HFR Facility ID', icon: Icons.account_balance_outlined),
                        const SizedBox(height: 14),
                        _AuthField(controller: _nmcController, hint: 'NMC Doctor ID', icon: Icons.verified_user_outlined),
                        const SizedBox(height: 14),
                      ],
                      _AuthField(controller: _emailController, hint: 'Email Address', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _PasswordField(
                        controller: _passwordController,
                        obscure: _obscurePassword,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // ── Primary CTA ─────────────────────────────────────────────
                    _PrimaryButton(
                      label: _isLoginMode
                          ? (_isEmailLogin || isAdmin ? 'Sign In' : 'Send OTP')
                          : 'Verify & Register',
                      isLoading: _isLoading,
                      onTap: () => _submitForm(userType),
                    ),

                    const SizedBox(height: 20),

                    // ── Toggle login/register ──────────────────────────────────
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

// ── Sub-components ────────────────────────────────────────────────────────────

class _AuthLogo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF0D4F4A),
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.medical_services_rounded, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 14),
        const Text(
          'EMERGEO',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0D4F4A), letterSpacing: 2),
        ),
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
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF0D9488) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.grey[500]),
          ),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Icon(icon, size: 18, color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(fontSize: 14, color: Color(0xFF0D4F4A)),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, size: 18, color: Colors.grey[400]),
          suffixIcon: IconButton(
            icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.grey[400]),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF0D4F4A), Color(0xFF0D9488)], begin: Alignment.centerLeft, end: Alignment.centerRight),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: const Color(0xFF0D9488).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
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
        GestureDetector(
          onTap: onToggle,
          child: Text(
            isLogin ? 'Sign Up' : 'Login',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0D9488)),
          ),
        ),
      ],
    );
  }
}