import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- PHONE VERIFICATION ---
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required bool isLogin, // FIX: Added flag to check intent
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // FIX: Only auto-sign in if they are logging in. 
        // If registering, we MUST force them through the manual flow to create the database doc.
        if (isLogin) {
          await _auth.signInWithCredential(credential);
        }
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (_) {},
      timeout: const Duration(seconds: 60),
    );
  }

  // --- SIMPLIFIED REGISTRATION ---
  Future<User?> registerWithVerifiedPhone({
    required String email,
    required String password,
    required String verificationId,
    required String smsCode,
    required String fullName,
    required String userType, 
    required String phone,
  }) async {
    User? user;
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user != null) {
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        await user.linkWithCredential(credential);

        String? fcmToken = await FirebaseMessaging.instance.getToken();

        String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          'userType': userType,
          'phone': phone,
          'createdAt': FieldValue.serverTimestamp(),
          'profileComplete': true,
          'fcmToken': fcmToken,
        };

        if (userType == 'provider') {
          userData.addAll({
            'isAvailable': false, 
            'verificationStatus': 'pending', 
            'inventory': [],
            'latitude': 0.0,
            'longitude': 0.0,
            'address': '',
          });
        }

        await _firestore.collection(collectionPath).doc(user.uid).set(userData);
      }
      return user;
    } catch (e) {
      if (user != null) await user.delete(); 
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

  // --- GET USER DATA ---
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