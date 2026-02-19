// // lib/screens/provider_registration_screen.dart
//
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/auth_service.dart';
//
// class ProviderRegistrationScreen extends StatefulWidget {
//   const ProviderRegistrationScreen({super.key});
//
//   @override
//   State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
// }
//
// class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _phoneController = TextEditingController();
//   final _addressController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _latController = TextEditingController();
//   final _lonController = TextEditingController();
//
//   String _selectedType = 'hospital';
//   bool _isLoading = false;
//   bool _obscurePassword = true;
//   Position? _currentPosition;
//
//   final List<String> _providerTypes = ['hospital', 'police', 'ambulance'];
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     _descriptionController.dispose();
//     _latController.dispose();
//     _lonController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _getCurrentLocation() async {
//     setState(() => _isLoading = true);
//
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled) {
//         throw 'Location services are disabled';
//       }
//
//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//         if (permission == LocationPermission.denied) {
//           throw 'Location permissions are denied';
//         }
//       }
//
//       final position = await Geolocator.getCurrentPosition();
//       setState(() {
//         _currentPosition = position;
//         _latController.text = position.latitude.toStringAsFixed(6);
//         _lonController.text = position.longitude.toStringAsFixed(6);
//       });
//
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Location captured successfully!'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }
//
//   // ** START: MODIFICATION **
//   Future<void> _register() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     if (_latController.text.isEmpty || _lonController.text.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please capture or enter your location'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isLoading = true);
//
//     try {
//       // Call the updated signUp method with all provider data
//       final user = await AuthService().signUp(
//         email: _emailController.text.trim(),
//         password: _passwordController.text.trim(),
//         fullName: _nameController.text.trim(),
//         userType: 'provider',
//         phone: _phoneController.text.trim(),
//         address: _addressController.text.trim(),
//         latitude: double.parse(_latController.text),
//         longitude: double.parse(_lonController.text),
//         providerType: _selectedType,
//         description: _descriptionController.text.trim(),
//       );
//
//       if (user != null && mounted) {
//         // Since profile is now complete on creation, navigate to the inventory screen
//         Navigator.pushReplacementNamed(context, '/manage-inventory');
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Registration failed: $e'), backgroundColor: Colors.red),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isLoading = false);
//       }
//     }
//   }
//   // ** END: MODIFICATION **
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Provider Registration'),
//         backgroundColor: Colors.green,
//         foregroundColor: Colors.white,
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               const Text(
//                 'Register as Service Provider',
//                 style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Provide your details to help people in emergencies',
//                 style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                 textAlign: TextAlign.center,
//               ),
//               const SizedBox(height: 32),
//
//               // Name
//               TextFormField(
//                 controller: _nameController,
//                 decoration: InputDecoration(
//                   labelText: 'Provider Name *',
//                   prefixIcon: const Icon(Icons.business),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
//               ),
//               const SizedBox(height: 16),
//
//               // Email
//               TextFormField(
//                 controller: _emailController,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: InputDecoration(
//                   labelText: 'Email *',
//                   prefixIcon: const Icon(Icons.email),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 validator: (v) => v?.contains('@') ?? false ? null : 'Invalid email',
//               ),
//               const SizedBox(height: 16),
//
//               // Password
//               TextFormField(
//                 controller: _passwordController,
//                 obscureText: _obscurePassword,
//                 decoration: InputDecoration(
//                   labelText: 'Password *',
//                   prefixIcon: const Icon(Icons.lock),
//                   suffixIcon: IconButton(
//                     icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
//                     onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                   ),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 validator: (v) => (v?.length ?? 0) < 6 ? 'Min 6 characters' : null,
//               ),
//               const SizedBox(height: 16),
//
//               // Phone
//               TextFormField(
//                 controller: _phoneController,
//                 keyboardType: TextInputType.phone,
//                 decoration: InputDecoration(
//                   labelText: 'Phone Number *',
//                   prefixIcon: const Icon(Icons.phone),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
//               ),
//               const SizedBox(height: 16),
//
//               // Provider Type
//               DropdownButtonFormField<String>(
//                 value: _selectedType,
//                 decoration: InputDecoration(
//                   labelText: 'Provider Type *',
//                   prefixIcon: const Icon(Icons.category),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 items: _providerTypes.map((type) {
//                   return DropdownMenuItem(
//                     value: type,
//                     child: Text(type[0].toUpperCase() + type.substring(1)),
//                   );
//                 }).toList(),
//                 onChanged: (v) => setState(() => _selectedType = v!),
//               ),
//               const SizedBox(height: 16),
//
//               // Address
//               TextFormField(
//                 controller: _addressController,
//                 maxLines: 2,
//                 decoration: InputDecoration(
//                   labelText: 'Full Address *',
//                   prefixIcon: const Icon(Icons.location_on),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
//               ),
//               const SizedBox(height: 16),
//
//               // Description
//               TextFormField(
//                 controller: _descriptionController,
//                 maxLines: 3,
//                 decoration: InputDecoration(
//                   labelText: 'Description (optional)',
//                   prefixIcon: const Icon(Icons.description),
//                   border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//                   hintText: 'Tell people about your services...',
//                 ),
//               ),
//               const SizedBox(height: 24),
//
//               // Location Section
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.blue[50],
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(color: Colors.blue[200]!),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(Icons.my_location, color: Colors.blue[700]),
//                         const SizedBox(width: 8),
//                         Text(
//                           'Location *',
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.blue[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     ElevatedButton.icon(
//                       onPressed: _isLoading ? null : _getCurrentLocation,
//                       icon: const Icon(Icons.gps_fixed),
//                       label: const Text('Auto-Detect Current Location'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.blue,
//                         foregroundColor: Colors.white,
//                         minimumSize: const Size(double.infinity, 45),
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     const Text('OR enter manually:', style: TextStyle(fontSize: 12)),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: TextFormField(
//                             controller: _latController,
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                               labelText: 'Latitude',
//                               border: OutlineInputBorder(),
//                               isDense: true,
//                             ),
//                             validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
//                           ),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: TextFormField(
//                             controller: _lonController,
//                             keyboardType: TextInputType.number,
//                             decoration: const InputDecoration(
//                               labelText: 'Longitude',
//                               border: OutlineInputBorder(),
//                               isDense: true,
//                             ),
//                             validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 32),
//
//               // Register Button
//               ElevatedButton(
//                 onPressed: _isLoading ? null : _register,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//                 ),
//                 child: _isLoading
//                     ? const CircularProgressIndicator(color: Colors.white)
//                     : const Text('Register & Continue', style: TextStyle(fontSize: 16)),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   } }
// lib/screens/provider_registration_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProviderRegistrationScreen extends StatefulWidget {
  const ProviderRegistrationScreen({super.key});

  @override
  State<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends State<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for general info
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // CRITICAL: Controllers for Double Verification
  final _nmcIdController = TextEditingController(); // National Medical Commission
  final _hfrIdController = TextEditingController(); // Health Facility Registry

  bool _isLoading = false;
  bool _isAvailableInitial = true; // Default status for new providers

  Future<void> _registerProvider() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "No authenticated user found";

      // Prepare the user document with verification flags
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': 'provider',

        // Verification Fields
        'nmcId': _nmcIdController.text.trim(),
        'hfrId': _hfrIdController.text.trim(),
        'isNMCVerified': false, // Admin must verify manually
        'isHFRVerified': false, // Admin must verify manually

        // Availability Toggle Field
        'isAvailable': _isAvailableInitial,

        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        // Navigate to the Verification Guard we discussed earlier
        Navigator.pushReplacementNamed(context, '/provider_guard');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Registration Error: $e"), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Provider Registration"), backgroundColor:Color(0xFF00897B) , foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Professional Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              _buildTextField(_nameController, "Full Name", Icons.person, "Enter your name"),
              _buildTextField(_phoneController, "Phone Number", Icons.phone, "Enter contact number", isPhone: true),

              const Divider(height: 40),
              const Text("Medical Verification (Required)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color:Color(0xFF00897B))),
              const SizedBox(height: 15),

              // NMC Field
              _buildTextField(_nmcIdController, "NMC ID (Doctor Reg No.)", Icons.badge, "e.g. NMC/12345/2023"),

              // HFR Field
              _buildTextField(_hfrIdController, "HFR ID (Facility Reg No.)", Icons.local_hospital, "e.g. HFR/FAC/999"),

              const SizedBox(height: 20),

              // Initial Availability Toggle
              SwitchListTile(
                title: const Text("Set Status to Available immediately?"),
                subtitle: const Text("You can change this later from your dashboard"),
                value: _isAvailableInitial,
                activeColor: const Color(0xFF00897B),
                onChanged: (val) => setState(() => _isAvailableInitial = val),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _registerProvider,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00897B),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("COMPLETE REGISTRATION", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, String hint, {bool isPhone = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        validator: (value) => value!.isEmpty ? "Required field" : null,
      ),
    );
  }
}