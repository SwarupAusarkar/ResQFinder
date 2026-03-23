import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- PHONE VERIFICATION ---
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto-resolution on Android
        await _auth.signInWithCredential(credential);
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // --- REGISTRATION WITH IMAGES & CREDENTIALS ---
  Future<User?> registerWithVerifiedPhone({
    required String email,
    required String password,
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String userType, // "provider" or "requester"
    required String phone,
    String? address,
    double? latitude,
    double? longitude,
    String? providerType,
    String? description,
    String? hfrId,
    String? nmcId,
    File? certificateImage,
    List<File>? facilityImages,
  }) async {
    User? user;
    try {
      // 1. Create Email Account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user != null) {
        // 2. Link the verified phone number to the account
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        await user.linkWithCredential(credential);

        // 3. Upload images to Firebase Storage if user is a Provider
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
              facilityUrls.add(await facRef.getDownloadURL());
            }
          }
        }

        // 4. Get FCM token for notifications
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // 5. Prepare Firestore Data
        String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'fullName': fullName, // Standardized field name
          'userType': userType,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'profileComplete': true,
          'fcmToken': fcmToken,
        };

        if (userType == 'provider') {
          userData.addAll({
            'address': address ?? '',
            'latitude': latitude ?? 0.0,
            'longitude': longitude ?? 0.0,
            'providerType': providerType ?? 'hospital',
            'description': description ?? '',
            'hfrId': hfrId ?? '',
            'nmcId': nmcId ?? '',
            'isHFRVerified': false,
            'isNMCVerified': false,
            'isAvailable': false, // SECURE: Default to offline
            'verificationStatus': 'pending', // SECURE: Needs admin approval
            'inventory': [],
            'certificateUrl': certUrl ?? '',
            'facilityUrls': facilityUrls,
          });
        }

        await _firestore.collection(collectionPath).doc(user.uid).set(userData);
      }
      return user;
    } catch (e) {
      if (user != null) await user.delete(); // Cleanup Auth user if Firestore fails
      rethrow;
    }
  }

  // --- EMAIL SIGN IN ---
  Future<User?> signIn({required String email, required String password}) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        await _refreshFcmToken(userCredential.user!.uid);
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- PHONE SIGN IN ---
  Future<User?> signInWithPhone({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _auth.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _refreshFcmToken(userCredential.user!.uid);
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // --- REFRESH FCM TOKEN HELPER ---
  Future<void> _refreshFcmToken(String uid) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) return;

      // Check requesters first, then providers
      var requesterDoc = await _firestore.collection('requesters').doc(uid).get();
      if (requesterDoc.exists) {
        await _firestore.collection('requesters').doc(uid).update({'fcmToken': token});
      } else {
        var providerDoc = await _firestore.collection('providers').doc(uid).get();
        if (providerDoc.exists) {
          await _firestore.collection('providers').doc(uid).update({'fcmToken': token});
        }
      }
    } catch (e) {
      debugPrint("FCM Refresh Error: $e");
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  // --- GET USER DATA (Role Agnostic) ---
  Future<DocumentSnapshot?> getUserData(String uid) async {
    var doc = await _firestore.collection('requesters').doc(uid).get();
    if (doc.exists) return doc;
    doc = await _firestore.collection('providers').doc(uid).get();
    if (doc.exists) return doc;
    return null;
  }

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-verification-code': return 'The SMS code is invalid.';
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      case 'email-already-in-use': return 'An account already exists with this email.';
      default: return error.message ?? 'An authentication error occurred';
    }
  }
}