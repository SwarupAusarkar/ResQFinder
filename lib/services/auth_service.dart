import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 🚀 REGISTRATION FLOW (OTP Only for Verification)
  // ---------------------------------------------------------------------------

  // Step 1: Trigger the SMS Code
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-resolution (mostly Android). 
        // We generally handle this in the UI or ignore to force manual code entry for consistency.
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // Step 2: Finalize Account Creation (Email + Pass + Verified Phone)
  Future<User?> registerWithVerifiedPhone({
    required String email,
    required String password,
    required String verificationId,
    required String smsCode,
    // Profile Data
    required String fullName,
    required String userType,
    required String phone,
    String? address,
    double? latitude,
    double? longitude,
    String? providerType,
    String? description,
    bool? isHFRVerified,
    bool? isNMCVerified,
    String? hfrId,
    String? nmcId,
  }) async {
    User? user;
    try {
      // A. Create the Basic Email/Password Account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user != null) {
        // B. Link the Phone Credential to this Account
        // This proves the phone number belongs to this email user
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        
        await user.linkWithCredential(credential);

        // C. Save Data to Firestore
        await saveUserData(
          user: user,
          fullName: fullName,
          userType: userType,
          email: email,
          phone: phone, // This is now verified
          address: address,
          latitude: latitude,
          longitude: longitude,
          providerType: providerType,
          description: description,
          isHFRVerified: isHFRVerified,
          isNMCVerified: isNMCVerified,
          hfrId: hfrId,
          nmcId: nmcId,
        );
      }
      return user;
    } on FirebaseAuthException catch (e) {
      // Rollback: If linking fails (e.g., invalid code), delete the half-created email user
      // so they can try again.
      if (user != null) await user.delete();
      throw _handleAuthError(e);
    } catch (e) {
      if (user != null) await user.delete();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔑 LOGIN FLOW (Standard Email/Password)
  // ---------------------------------------------------------------------------

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  // ---------------------------------------------------------------------------
  // 💾 SHARED HELPERS
  // ---------------------------------------------------------------------------

  Future<void> saveUserData({
    required User user,
    required String fullName,
    required String userType,
    String? email,
    String? phone,
    String? address,
    double? latitude,
    double? longitude,
    String? providerType,
    String? description,
    bool? isHFRVerified,
    bool? isNMCVerified,
    String? hfrId,
    String? nmcId,
  }) async {
    String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';

    final Map<String, dynamic> userData = {
      'uid': user.uid,
      'name': fullName,
      'userType': userType,
      'createdAt': FieldValue.serverTimestamp(),
      'profileComplete': true,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
    };

    if (userType == 'provider') {
      userData.addAll({
        'isHFRVerified': isHFRVerified ?? false,
        'isNMCVerified': isNMCVerified ?? false,
        'hfrId': hfrId ?? '',
        'nmcId': nmcId ?? '',
        'address': address ?? '',
        'latitude': latitude ?? 0.0,
        'longitude': longitude ?? 0.0,
        'providerType': providerType ?? 'hospital',
        'description': description ?? '',
        'isAvailable': true,
        'inventory': [],
      });
    }

    await _firestore.collection(collectionPath).doc(user.uid).set(userData, SetOptions(merge: true));
  }

  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      var doc = await _firestore.collection('requesters').doc(uid).get();
      if (doc.exists) return doc;
      doc = await _firestore.collection('providers').doc(uid).get();
      if (doc.exists) return doc;
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use': return 'Email already in use.';
      case 'credential-already-in-use': return 'This phone number is already linked to another account.';
      case 'invalid-verification-code': return 'The SMS code is invalid.';
      case 'weak-password': return 'Password is too weak.';
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      default: return error.message ?? 'Authentication error';
    }
  }
}