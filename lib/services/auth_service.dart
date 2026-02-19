import 'dart:io'; 
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance; 

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
      verificationCompleted: (_) {}, 
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
    
    File? certificateImage,
    List<File>? facilityImages,
  }) async {
    User? user;
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      user = userCredential.user;

      if (user != null) {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode);
        await user.linkWithCredential(credential);

        String? certUrl;
        List<String> facilityUrls = [];

        if (userType == 'provider') {
          if (certificateImage != null) {
            final certRef = _storage.ref().child('provider_certs/${user.uid}_cert.jpg');
            await certRef.putFile(certificateImage);
            certUrl = await certRef.getDownloadURL();
          }

          if (facilityImages != null && facilityImages.isNotEmpty) {
            for (int i = 0; i < facilityImages.length; i++) {
              final facRef = _storage.ref().child('provider_facilities/${user.uid}/fac_img_$i.jpg');
              await facRef.putFile(facilityImages[i]);
              String url = await facRef.getDownloadURL();
              facilityUrls.add(url);
            }
          }
        }

        String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
        
        final Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'name': fullName,
          'userType': userType,
          'phone': phone,
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
            'isHFRVerified': false, 
            'isNMCVerified': false, 
            'hfrId': hfrId ?? '',
            'nmcId': nmcId ?? '',
            'isAvailable': false, 
            'inventory': [], 
            'certificateUrl': certUrl ?? '',
            'facilityUrls': facilityUrls,
            'verificationStatus': 'pending', 
          });
        }

        await _firestore.collection(collectionPath).doc(user.uid).set(userData);
      }
      return user;
    } on FirebaseAuthException catch (e) {
      if (user != null) await user.delete(); 
      throw _handleAuthError(e);
    } catch (e) {
      if (user != null) await user.delete();
      rethrow;
    }
  }

  Future<User?> signUp({
     required String email, required String password, required String fullName, required String userType,
     required String phone, required String address, required double latitude, required double longitude,
     required String providerType, required String description, String? hfrId, String? nmcId,
  }) async {
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

  // NEW: Login purely with Phone Number OTP
  Future<User?> signInWithPhone({required String verificationId, required String smsCode}) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
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