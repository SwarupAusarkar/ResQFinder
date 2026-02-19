import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 📞 PHONE OTP + REGISTRATION FLOW
  // ---------------------------------------------------------------------------

  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (_) {}, // Handled manually via UI
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

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
      // 1. Create Basic Account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user != null) {
        // 2. Link Phone to Account
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        await user.linkWithCredential(credential);

        // 3. Save Data to Firestore (Providers or Requesters)
        String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
        
        final Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'name': fullName,
          'userType': userType,
          'phone': phone, // Verified!
          'createdAt': FieldValue.serverTimestamp(),
          'profileComplete': true,
        };

        if (userType == 'provider') {
          userData.addAll({
            'address': address ?? '',
            'latitude': latitude ?? 0.0,
            'longitude': longitude ?? 0.0,
            'providerType': providerType ?? 'hospital',
            'description': description ?? '',
            'isHFRVerified': isHFRVerified ?? false,
            'isNMCVerified': isNMCVerified ?? false,
            'hfrId': hfrId ?? '',
            'nmcId': nmcId ?? '',
            'isAvailable': true,
            'inventory': [], 
          });
        }

        await _firestore.collection(collectionPath).doc(user.uid).set(userData);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (user != null) await user.delete(); // Rollback if OTP fails
      throw _handleAuthError(e);
    } catch (e) {
      if (user != null) await user.delete();
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📝 STANDARD SIGN UP (Fallback / Direct)
  // ---------------------------------------------------------------------------
  Future<User?> signUp({
     // ... (Keep your existing signUp method here just in case you need it later) ...
     required String email, required String password, required String fullName, required String userType,
     required String phone, required String address, required double latitude, required double longitude,
     required String providerType, required String description, String? hfrId, String? nmcId,
  }) async {
    // Standard creation logic...
    UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    User? user = result.user;
    if (user != null) {
      String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
      await _firestore.collection(collectionPath).doc(user.uid).set({
        'uid': user.uid, 'email': email, 'name': fullName, 'userType': userType, 'phone': phone,
        'createdAt': FieldValue.serverTimestamp(), 'profileComplete': true,
        if (userType == 'provider') ...{
          'address': address, 'latitude': latitude, 'longitude': longitude, 'providerType': providerType,
          'description': description, 'isHFRVerified': false, 'isNMCVerified': false, 'hfrId': hfrId ?? '',
          'nmcId': nmcId ?? '', 'isAvailable': true, 'inventory': [], 
        }
      });
    }
    return user;
  }

  // ---------------------------------------------------------------------------
  // 🔑 LOGIN & HELPERS
  // ---------------------------------------------------------------------------
  Future<User?> signIn({required String email, required String password}) async {
    final userCredential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<DocumentSnapshot?> getUserData(String uid) async {
    var doc = await _firestore.collection('requesters').doc(uid).get();
    if (doc.exists) return doc;
    doc = await _firestore.collection('providers').doc(uid).get();
    if (doc.exists) return doc;
    return null;
  }

  String _handleAuthError(FirebaseAuthException error) {
    if (error.code == 'invalid-verification-code') return 'The SMS code is invalid.';
    return error.message ?? 'An error occurred';
  }
}