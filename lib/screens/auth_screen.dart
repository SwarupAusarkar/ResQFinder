// <<<<<<< HEAD
// // import 'package:flutter/material.dart';
// // import '../services/auth_service.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// //
// // // Authentication screen for both user types
// // class AuthScreen extends StatefulWidget {
// //   const AuthScreen({super.key});
// //
// //   @override
// //   State<AuthScreen> createState() => _AuthScreenState();
// // }
// //
// // class _AuthScreenState extends State<AuthScreen> {
// //   final _formKey = GlobalKey<FormState>();
// //   final _emailController = TextEditingController();
// //   final _passwordController = TextEditingController();
// //   final _nameController = TextEditingController();
// //   final AuthService _authService = AuthService();
// //
// //   bool _isLoading = false;
// //   bool _isLoginMode = true;
// //   bool _obscurePassword = true;
// //
// //   @override
// //   void dispose() {
// //     _emailController.dispose();
// //     _passwordController.dispose();
// //     _nameController.dispose();
// //     super.dispose();
// //   }
// //
// //   Future<void> _submitForm(String userType) async {
// //     if (!_formKey.currentState!.validate()) return;
// //
// //     setState(() {
// //       _isLoading = true;
// //     });
// //
// //     try {
// //       if (_isLoginMode) {
// //         // Log in user
// //         print("🔑 Attempting sign in...");
// //         final user = await _authService.signIn(
// //           email: _emailController.text.trim(),
// //           password: _passwordController.text.trim(),
// //         );
// //
// //         if (user != null) {
// //           print("✓ Sign in successful, fetching user data...");
// //
// //           // Get user data to determine routing
// //           final userDoc = await FirebaseFirestore.instance
// //               .collection('users')
// //               .doc(user.uid)
// //               .get();
// //
// //           if (userDoc.exists && mounted) {
// //             final userData = userDoc.data()!;
// //             final actualUserType = userData['userType'] as String?;
// //
// //             print("✓ User type: $actualUserType");
// //
// //             // Navigate based on user type
// //             if (actualUserType == 'provider') {
// //               final profileComplete = userData['profileComplete'] as bool? ?? false;
// //
// //               if (!profileComplete) {
// //                 print("→ Navigating to ManageServicesScreen");
// //                 Navigator.pushReplacementNamed(context, '/manage-services');
// //               } else {
// //                 print("→ Navigating to ProviderDashboardScreen");
// //                 Navigator.pushReplacementNamed(context, '/provider-dashboard');
// //               }
// //             } else {
// //               print("→ Navigating to ServiceSelectionScreen");
// //               Navigator.pushReplacementNamed(context, '/service-selection');
// //             }
// //           }
// //         }
// //       } else {
// //         // Register new user
// //         print("📝 Attempting sign up...");
// //         final user = await _authService.signUp(
// //           email: _emailController.text.trim(),
// //           password: _passwordController.text.trim(),
// //           fullName: _nameController.text.trim(),
// //           userType: userType,
// //         );
// //
// //         if (user != null && mounted) {
// //           print("✓ Sign up successful");
// //
// //           // Navigate based on user type
// //           if (userType == 'provider') {
// //             print("→ Navigating to ManageServicesScreen");
// //             Navigator.pushReplacementNamed(context, '/manage-services');
// //           } else {
// //             print("→ Navigating to ServiceSelectionScreen");
// //             Navigator.pushReplacementNamed(context, '/service-selection');
// //           }
// //         }
// //       }
// //     } catch (e) {
// //       print("❌ Auth error: $e");
// //       // Show error message if login/signup fails
// //       if (mounted) {
// //         ScaffoldMessenger.of(context).showSnackBar(
// //           SnackBar(
// //             content: Text(e.toString()),
// //             backgroundColor: Theme.of(context).colorScheme.error,
// //           ),
// //         );
// //       }
// //     } finally {
// //       if (mounted) {
// //         setState(() {
// //           _isLoading = false;
// //         });
// //       }
// //     }
// //   }
// //
// //   void _toggleFormMode() {
// //     setState(() {
// //       _isLoginMode = !_isLoginMode;
// //     });
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     // Get user type from navigation arguments
// //     final args =
// //         ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
// //     final userType = args?['userType'] ?? 'requester';
// //     final isProvider = userType == 'provider';
// //
// //     return Scaffold(
// //       appBar: AppBar(
// //         title: Text(isProvider ? 'Provider Portal' : 'User Sign In'),
// //         backgroundColor: isProvider ? Colors.green : Colors.blue,
// //         foregroundColor: Colors.white,
// //       ),
// //       body: SingleChildScrollView(
// //         padding: const EdgeInsets.all(24.0),
// //         child: Form(
// //           key: _formKey,
// //           child: Column(
// //             crossAxisAlignment: CrossAxisAlignment.stretch,
// //             children: [
// //               const SizedBox(height: 40),
// //
// //               // Welcome message
// //               Text(
// //                 _isLoginMode
// //                     ? 'Welcome Back!'
// //                     : 'Create Your Account',
// //                 style: const TextStyle(
// //                   fontSize: 28,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 8),
// //               Text(
// //                 isProvider
// //                     ? 'Access your provider dashboard'
// //                     : 'Find emergency services near you',
// //                 style: TextStyle(
// //                   fontSize: 16,
// //                   color: Colors.grey[600],
// //                 ),
// //                 textAlign: TextAlign.center,
// //               ),
// //               const SizedBox(height: 40),
// //
// //               if (!_isLoginMode) ...[
// //                 TextFormField(
// //                   controller: _nameController,
// //                   decoration: InputDecoration(
// //                     labelText: 'Full Name',
// //                     prefixIcon: const Icon(Icons.person_outline),
// //                     border: OutlineInputBorder(
// //                       borderRadius: BorderRadius.circular(12),
// //                     ),
// //                   ),
// //                   validator: (value) {
// //                     if (value == null || value.isEmpty) {
// //                       return 'Please enter your full name';
// //                     }
// //                     return null;
// //                   },
// //                 ),
// //                 const SizedBox(height: 16),
// //               ],
// //
// //               // Email field
// //               TextFormField(
// //                 controller: _emailController,
// //                 keyboardType: TextInputType.emailAddress,
// //                 decoration: InputDecoration(
// //                   labelText: 'Email Address',
// //                   prefixIcon: const Icon(Icons.email_outlined),
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || !value.contains('@')) {
// //                     return 'Please enter a valid email';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 16),
// //
// //               // Password field
// //               TextFormField(
// //                 controller: _passwordController,
// //                 obscureText: _obscurePassword,
// //                 decoration: InputDecoration(
// //                   labelText: 'Password',
// //                   prefixIcon: const Icon(Icons.lock_outlined),
// //                   suffixIcon: IconButton(
// //                     icon: Icon(
// //                       _obscurePassword ? Icons.visibility_off : Icons.visibility,
// //                     ),
// //                     onPressed: () {
// //                       setState(() {
// //                         _obscurePassword = !_obscurePassword;
// //                       });
// //                     },
// //                   ),
// //                   border: OutlineInputBorder(
// //                     borderRadius: BorderRadius.circular(12),
// //                   ),
// //                 ),
// //                 validator: (value) {
// //                   if (value == null || value.length < 6) {
// //                     return 'Password must be at least 6 characters';
// //                   }
// //                   return null;
// //                 },
// //               ),
// //               const SizedBox(height: 24),
// //
// //               // Sign in/register button
// //               ElevatedButton(
// //                 onPressed: _isLoading ? null : () => _submitForm(userType),
// //                 style: ElevatedButton.styleFrom(
// //                   backgroundColor: isProvider ? Colors.green : Colors.blue,
// //                   foregroundColor: Colors.white,
// //                   padding: const EdgeInsets.symmetric(vertical: 16),
// //                 ),
// //                 child: _isLoading
// //                     ? const SizedBox(
// //                         height: 20,
// //                         width: 20,
// //                         child: CircularProgressIndicator(
// //                           strokeWidth: 2,
// //                           valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
// //                         ),
// //                       )
// //                     : Text(
// //                         _isLoginMode ? 'Sign In' : 'Register',
// //                         style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
// //                       ),
// //               ),
// //               const SizedBox(height: 16),
// //
// //               // Toggle between login/register
// //               TextButton(
// //                 onPressed: _toggleFormMode,
// //                 child: Text(_isLoginMode
// //                     ? 'Don\'t have an account? Register'
// //                     : 'Already have an account? Sign In'),
// //               ),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   } }
// import 'package:firebase_messaging/firebase_messaging.dart';
// =======
// >>>>>>> upstream/main
// import 'package:flutter/material.dart';
// import '../services/auth_service.dart';
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
//   final _phoneController = TextEditingController(); // NEW
//   final _hfrController = TextEditingController();
//   final _nmcController = TextEditingController();
//
//   final AuthService _authService = AuthService();
//
//   bool _isLoading = false;
//   bool _isLoginMode = true;
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
//   // ---------------------------------------------------------------------------
//   // ⚡ ACTION: SUBMIT FORM
//   // ---------------------------------------------------------------------------
//   Future<void> _submitForm(String userType) async {
//     if (!_formKey.currentState!.validate()) return;
//
//     setState(() => _isLoading = true);
//
//     try {
//       if (_isLoginMode) {
//         // --- LOGIN FLOW (Standard) ---
//         await _handleLogin();
//       } else {
// <<<<<<< HEAD
//         // REGISTER: Create user with unverified status but allow entry
//         FirebaseMessaging messaging=FirebaseMessaging.instance;
//         String? token=await messaging.getToken();
//           final user = await _authService.signUp(
//             email: _emailController.text.trim(),
//             password: _passwordController.text.trim(),
//             fullName: _nameController.text.trim(),
//             userType: userType,
//             isHFRVerified: userType == "provider" ? false : null,
//             isNMCVerified: userType == 'provider' ? false : null,
//             hfrId: userType == 'provider' ? _hfrController.text.trim() : null,
//             nmcId: userType == 'provider' ? _nmcController.text.trim() : null,
//             phone: '',
//             address: '',
//             latitude: 0.0,
//             longitude: 0.0,
//             providerType: '',
//             description: '',
//             fcmToken: token,
//           );
//
//         if (user != null && mounted) {
//           if (userType == 'provider') {
//             // Nw providers go to MANAGE SERVICES after signup as requested
//             Navigator.pushReplacementNamed(context, '/manage-services');
//           } else {
//             Navigator.pushReplacementNamed(context, '/service-selection');
//           }
//         }
// =======
//         // --- REGISTRATION FLOW (OTP Gatekeeper) ---
//         await _startRegistrationFlow(userType);
// >>>>>>> upstream/main
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString()), backgroundColor:Color(0xFF00897B)),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//
//   // Logic for Login
//   Future<void> _handleLogin() async {
//     final user = await _authService.signIn(
//       email: _emailController.text.trim(),
//       password: _passwordController.text.trim(),
//     );
//
//     if (user != null && mounted) {
//       final userDoc = await _authService.getUserData(user.uid);
//
//       if (userDoc != null && userDoc.exists) {
//         final userData = userDoc.data() as Map<String, dynamic>;
//         final actualUserType = userData['userType'];
//
//         if (actualUserType == 'provider') {
//           Navigator.pushReplacementNamed(context, '/provider-dashboard');
//         } else {
//           Navigator.pushReplacementNamed(context, '/service-selection');
//         }
//       }
//     }
//   }
//
//   // Logic for Registration Trigger
//   Future<void> _startRegistrationFlow(String userType) async {
//     final phone = _phoneController.text.trim();
//
//     // 1. Trigger OTP
//     await _authService.startPhoneVerification(
//       phoneNumber: phone,
//       onCodeSent: (verificationId, resendToken) {
//         // 2. Hide Loader & Show Dialog
//         setState(() => _isLoading = false);
//         _showOtpDialog(verificationId, userType);
//       },
//       onVerificationFailed: (e) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text("Verification Failed: ${e.message}"), backgroundColor: Colors.red),
//         );
//       },
//     );
//   }
//
//   // ---------------------------------------------------------------------------
//   // 💬 UI: OTP DIALOG
//   // ---------------------------------------------------------------------------
//   void _showOtpDialog(String verificationId, String userType) {
//     final otpController = TextEditingController();
//
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: const Text("Verify Phone Number"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text("Enter the 6-digit code sent to ${_phoneController.text}"),
//             const SizedBox(height: 16),
//             TextField(
//               controller: otpController,
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 labelText: "OTP Code",
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("Cancel"),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context); // Close dialog
//               _finalizeRegistration(verificationId, otpController.text.trim(), userType);
//             },
//             child: const Text("Verify & Register"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Logic to actually create the account after OTP is entered
//   Future<void> _finalizeRegistration(String verificationId, String smsCode, String userType) async {
//     setState(() => _isLoading = true); // Show loader again
//
//     try {
//       final isProvider = userType == 'provider';
//
//       final user = await _authService.registerWithVerifiedPhone(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         verificationId: verificationId,
//         smsCode: smsCode,
//         fullName: _nameController.text.trim(),
//         userType: userType,
//         phone: _phoneController.text.trim(),
//
//         // Optional Provider Fields
//         hfrId: isProvider ? _hfrController.text.trim() : null,
//         nmcId: isProvider ? _nmcController.text.trim() : null,
//         isHFRVerified: isProvider ? false : null,
//         isNMCVerified: isProvider ? false : null,
//
//         // Placeholders for now
//         address: '',
//         latitude: 0.0,
//         longitude: 0.0,
//         providerType: isProvider ? 'hospital' : '',
//         description: '',
//       );
//
//       if (user != null && mounted) {
//         Navigator.pushReplacementNamed(
//           context,
//           userType == 'provider' ? '/manage-services' : '/service-selection'
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isLoading = false);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // 🎨 UI BUILD
//   // ---------------------------------------------------------------------------
//   @override
//   Widget build(BuildContext context) {
// <<<<<<< HEAD
//     final args =
//     ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
// =======
//     final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
// >>>>>>> upstream/main
//     final userType = args?['userType'] ?? 'requester';
//     final isProvider = userType == 'provider';
//
//     return Scaffold(
//       appBar: AppBar(
//         title: Text(isProvider ? 'Medical Provider Portal' : 'Citizen Sign In'),
//         backgroundColor: Color(0xFF00897B),
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // ... Header Text ...
//               const SizedBox(height: 20),
//               Text(
//                 _isLoginMode ? 'Welcome Back' : 'Join the Network',
//                 style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 30),
//
//               // Full Name (Register Only)
//               if (!_isLoginMode) ...[
//                 _buildTextField(_nameController, 'Full Name', Icons.person_outline),
//                 const SizedBox(height: 16),
//
//                 // NEW: Phone Number Field
//                  _buildTextField(
//                   _phoneController,
//                   'Phone Number (+91...)',
//                   Icons.phone,
//                   keyboardType: TextInputType.phone
//                 ),
//                 const SizedBox(height: 16),
//               ],
//
//               _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
//               const SizedBox(height: 16),
//               _buildTextField(_passwordController, 'Password', Icons.lock_outlined, isPassword: true),
//               const SizedBox(height: 16),
//
//               // Provider IDs (Register Only)
//               if (!_isLoginMode && isProvider) ...[
//                 const Divider(height: 40),
// <<<<<<< HEAD
//                 const Text(
//                   "Professional Credentials",
//                   style: TextStyle(
//                     fontWeight: FontWeight.bold,
//                     color: Color(0xFF00897B),
//                   ),
//                 ),
// =======
//                 const Text("Professional Credentials", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
// >>>>>>> upstream/main
//                 const SizedBox(height: 12),
//                 _buildTextField(_hfrController, 'HFR Facility ID', Icons.account_balance_outlined),
//                 const SizedBox(height: 16),
//                 _buildTextField(_nmcController, 'NMC Registration No.', Icons.medical_services_outlined),
//                 const SizedBox(height: 24),
//               ],
//
//               ElevatedButton(
//                 onPressed: _isLoading ? null : () => _submitForm(userType),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Color(0xFF00897B),
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                 ),
// <<<<<<< HEAD
//                 child:
//                 _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : Text(
//                   _isLoginMode ? 'SIGN IN' : 'REGISTER AS PROVIDER',
//                 ),
// =======
//                 child: _isLoading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : Text(_isLoginMode ? 'SIGN IN' : 'VERIFY & REGISTER'),
// >>>>>>> upstream/main
//               ),
//
//               TextButton(
//                 onPressed: () => setState(() => _isLoginMode = !_isLoginMode),
//                 child: Text(_isLoginMode ? 'New here? Create account' : 'Have an account? Login'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
// <<<<<<< HEAD
//   Widget _buildTextField(
//       TextEditingController controller,
//       String label,
//       IconData icon, {
//         bool isPassword = false,
//         TextInputType? keyboardType,
//       }) {
// =======
//   Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isPassword = false, TextInputType? keyboardType}) {
// >>>>>>> upstream/main
//     return TextFormField(
//       controller: controller,
//       obscureText: isPassword && _obscurePassword,
//       keyboardType: keyboardType,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
// <<<<<<< HEAD
//         suffixIcon:
//         isPassword
//             ? IconButton(
//           icon: Icon(
//             _obscurePassword ? Icons.visibility_off : Icons.visibility,
//           ),
//           onPressed:
//               () =>
//               setState(() => _obscurePassword = !_obscurePassword),
//         )
//             : null,
// =======
//         suffixIcon: isPassword
//           ? IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _obscurePassword = !_obscurePassword))
//           : null,
// >>>>>>> upstream/main
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//       validator: (val) => (val == null || val.isEmpty) ? 'Required field' : null,
//     );
//   } }
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/auth_service.dart';
import 'OTP_verification_screen.dart';

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
  final _phoneController = TextEditingController();
  final _hfrController = TextEditingController();
  final _nmcController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoginMode = true;
  bool _isEmailLogin = true;
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

  // Smart formatter that auto-appends +91 if missing
  String get _formattedPhone {
    String phone = _phoneController.text.trim();
    if (phone.isEmpty) return phone;
    if (phone.startsWith('+')) return phone;

    phone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (phone.length == 10) {
      return '+91$phone';
    }
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $message"), backgroundColor: Colors.red));
    }
  }

  void _showOtpDialog(
      String verificationId,
      String? userType, {
        required bool isLogin,
      }) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Drag Indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 32),

                /// Icon + Loader
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (isVerifying)
                      const SizedBox(
                        width: 80,
                        height: 80,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF00897B),
                          ),
                        ),
                      ),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00897B).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_outlined,
                        size: 40,
                        color: Color(0xFF00897B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// Title
                Text(
                  isLogin ? 'Login OTP' : 'Verify Phone',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                /// Subtitle
                Text(
                  'Enter the 6-digit code sent to $_formattedPhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 32),

                /// OTP Field
                TextField(
                  controller: otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  enabled: !isVerifying,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 16,
                  ),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '------',
                    hintStyle: TextStyle(
                      color: Colors.grey[300],
                      letterSpacing: 16,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                      BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00897B),
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                /// Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isVerifying
                        ? null
                        : () async {
                      if (otpController.text.trim().length != 6) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                            Text('Please enter 6-digit code'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      setState(() => isVerifying = true);

                      Navigator.pop(context);

                      if (isLogin) {
                        await _finalizePhoneLogin(
                          verificationId,
                          otpController.text.trim(),
                        );
                      } else {
                        await _finalizeRegistration(
                          verificationId,
                          otpController.text.trim(),
                          userType!,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00897B),
                      disabledBackgroundColor:
                      Colors.grey[300],
                      padding:
                      const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isVerifying
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                        AlwaysStoppedAnimation<Color>(
                            Colors.white),
                      ),
                    )
                        : const Text(
                      'VERIFY CODE',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                /// Cancel
                TextButton(
                  onPressed:
                  isVerifying ? null : () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: isVerifying
                          ? Colors.grey
                          : const Color(0xFF00897B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
          Navigator.pushReplacementNamed(context, userData['userType'] == 'provider' ? '/provider-dashboard' : '/service-selection');
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
        nmcId: userType == 'provider' ? _nmcController.text.trim() : null,
      );

      if (user != null && mounted) {
        Navigator.pushReplacementNamed(context, userType == 'provider' ? '/manage-services' : '/service-selection');
      }
    } catch (e) { _onAuthError(e.toString()); }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final userType = args?['userType'] ?? 'requester';
    final isProvider = userType == 'provider';
    final themeColor = const Color(0xFF00897B);

    return Scaffold(
      appBar: AppBar(title: Text(isProvider ? 'Medical Provider Portal' : 'Citizen Sign In'), backgroundColor: themeColor, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(_isLoginMode ? 'Welcome Back' : 'Join the Network', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 30),

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

              if (!_isLoginMode) ...[
                _buildTextField(_nameController, 'Full Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Phone Number (10 digits)', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
                if (isProvider) ...[
                  _buildTextField(_hfrController, 'HFR Facility ID', Icons.account_balance),
                  const SizedBox(height: 16),
                  _buildTextField(_nmcController, 'NMC Doctor ID', Icons.verified_user),
                  const SizedBox(height: 16),
                ],
              ],

              if (_isEmailLogin || !_isLoginMode) ...[
                _buildTextField(_emailController, 'Email Address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildTextField(_passwordController, 'Password', Icons.lock_outlined, isPassword: true),
                const SizedBox(height: 16),
              ],

              if (_isLoginMode && !_isEmailLogin) ...[
                _buildTextField(_phoneController, 'Phone Number', Icons.phone, keyboardType: TextInputType.phone),
                const SizedBox(height: 16),
              ],

              ElevatedButton(
                onPressed: _isLoading ? null : () => _submitForm(userType),
                style: ElevatedButton.styleFrom(backgroundColor: themeColor, padding: const EdgeInsets.symmetric(vertical: 16)),
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