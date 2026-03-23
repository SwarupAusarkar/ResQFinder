import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class CitizenRegisterScreen extends StatefulWidget {
  const CitizenRegisterScreen({super.key});

  @override
  State<CitizenRegisterScreen> createState() => _CitizenRegisterScreenState();
}

class _CitizenRegisterScreenState extends State<CitizenRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // 1. Create Auth User
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Create Firestore Document with our required Schema
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'fullName': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'role': 'citizen', // Critical for RBAC
        'createdAt': FieldValue.serverTimestamp(),
        // Schema for Emergency SMS Scheme
        'emergencyContacts': [
          {
            'name': _emergencyNameController.text.trim(),
            'phone': _emergencyPhoneController.text.trim(),
          }
        ],
      });

      if (mounted) {
        Navigator.of(context).pop(); // Go back to login or dashboard
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Registration Failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryTeal = Color(0xFF00897B);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Citizen Registration", style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryTeal)),
              const SizedBox(height: 8),
              const Text("Join ResQFinder to access emergency services.", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 32),

              _buildLabel("FULL NAME"),
              _buildTextField(_nameController, Icons.person_outline, "Enter your full name"),

              const SizedBox(height: 16),
              _buildLabel("EMAIL ADDRESS"),
              _buildTextField(_emailController, Icons.email_outlined, "name@example.com", isEmail: true),

              const SizedBox(height: 16),
              _buildLabel("PASSWORD"),
              _buildPasswordField(),

              const SizedBox(height: 32),
              const Row(
                children: [
                  Icon(Icons.contact_phone, color: Colors.redAccent, size: 20),
                  SizedBox(width: 8),
                  Text("EMERGENCY CONTACT", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                ],
              ),
              const Divider(),
              const SizedBox(height: 16),

              _buildTextField(_emergencyNameController, Icons.face, "Contact Name"),
              const SizedBox(height: 12),
              _buildTextField(_emergencyPhoneController, Icons.phone, "Contact Phone Number", isPhone: true),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("REGISTER AS CITIZEN", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helper Widgets ---

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
    );
  }

  Widget _buildTextField(TextEditingController controller, IconData icon, String hint, {bool isEmail = false, bool isPhone = false}) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : (isPhone ? TextInputType.phone : TextInputType.text),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF00897B)),
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.isEmpty ? "Required field" : null,
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF00897B)),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        hintText: "••••••••",
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
      validator: (v) => v!.length < 6 ? "Minimum 6 characters" : null,
    );
  }
}