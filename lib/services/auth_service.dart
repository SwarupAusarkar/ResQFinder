// import 'dart:async';
// import 'dart:io';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_storage/firebase_storage.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final FirebaseStorage _storage = FirebaseStorage.instance;
//
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
//   User? get currentUser => _auth.currentUser;
//
//   // --- PHONE VERIFICATION START ---
//   Future<void> startPhoneVerification({
//     required String phoneNumber,
//     required Function(String verificationId, int? resendToken) onCodeSent,
//     required Function(FirebaseAuthException) onVerificationFailed,
//   }) async {
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) async {
//         // Auto-resolution (mostly Android)
//         await _auth.signInWithCredential(credential);
//       },
//       verificationFailed: onVerificationFailed,
//       codeSent: onCodeSent,
//       codeAutoRetrievalTimeout: (_) {},
//       timeout: const Duration(seconds: 60),
//     );
//   }
//
//   // --- REGISTRATION WITH IMAGES & CREDENTIALS ---
//   Future<User?> registerWithVerifiedPhone({
//     required String email,
//     required String password,
//     required String verificationId,
//     required String smsCode,
//     required String fullName,
//     required String userType,
//     required String phone,
//     String? address,
//     double? latitude,
//     double? longitude,
//     String? providerType,
//     String? description,
//     String? hfrId,
//     String? nmcId,
//     String? fcmToken,
//     File? certificateImage,
//     List<File>? facilityImages,
//   }) async {
//     User? user;
//     try {
//       // 1. Create Email Account
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
//           email: email,
//           password: password
//       );
//       user = userCredential.user;
//
//       if (user != null) {
//         // 2. Link Phone
//         PhoneAuthCredential credential = PhoneAuthProvider.credential(
//             verificationId: verificationId,
//             smsCode: smsCode
//         );
//         await user.linkWithCredential(credential);
//
//         // 3. Upload Images if Provider
//         String? certUrl;
//         List<String> facilityUrls = [];
//
//         if (userType == 'provider') {
//           if (certificateImage != null) {
//             final certRef = _storage.ref().child('provider_certs/${user.uid}_cert.jpg');
//             await certRef.putFile(certificateImage);
//             certUrl = await certRef.getDownloadURL();
//           }
//
//           if (facilityImages != null && facilityImages.isNotEmpty) {
//             for (int i = 0; i < facilityImages.length; i++) {
//               final facRef = _storage.ref().child('provider_facilities/${user.uid}/fac_img_$i.jpg');
//               await facRef.putFile(facilityImages[i]);
//               facilityUrls.add(await facRef.getDownloadURL());
//             }
//           }
//         }
//
//         // 4. Save to Firestore (Common Fields)
//         String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
//         Map<String, dynamic> userData = {
//           'uid': user.uid,
//           'email': email,
//           'name': fullName,
//           'userType': userType,
//           'phone': phone,
//           'createdAt': FieldValue.serverTimestamp(),
//           'profileComplete': true,
//           'fcmToken': fcmToken,
//         };
//
//         // 5. Add Provider Specific Fields
//         if (userType == 'provider') {
//           userData.addAll({
//             'address': address ?? '',
//             'latitude': latitude ?? 0.0,
//             'longitude': longitude ?? 0.0,
//             'providerType': providerType ?? 'hospital',
//             'description': description ?? '',
//             'isHFRVerified': false,
//             'isNMCVerified': false,
//             'hfrId': hfrId ?? '',
//             'nmcId': nmcId ?? '',
//             'isAvailable': false,
//             'inventory': [],
//             'certificateUrl': certUrl ?? '',
//             'facilityUrls': facilityUrls,
//             'verificationStatus': 'pending',
//           });
//         }
//
//         await _firestore.collection(collectionPath).doc(user.uid).set(userData);
//       }
//       return user;
//     } catch (e) {
//       if (user != null) await user.delete(); // Cleanup on failure
//       rethrow;
//     }
//   }
//
//   // --- CONSOLIDATED SIGN IN (Email + FCM Update) ---
//   Future<User?> signIn({
//     required String email,
//     required String password,
//     String? currentFcmToken,
//   }) async {
//     try {
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//           email: email,
//           password: password
//       );
//
//       if (userCredential.user != null && currentFcmToken != null) {
//         await _updateFcmToken(userCredential.user!.uid, currentFcmToken);
//       }
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthError(e);
//     }
//   }
//
//   // --- SIGN IN WITH PHONE ONLY ---
//   Future<User?> signInWithPhone({
//     required String verificationId,
//     required String smsCode,
//     String? currentFcmToken,
//   }) async {
//     try {
//       PhoneAuthCredential credential = PhoneAuthProvider.credential(
//         verificationId: verificationId,
//         smsCode: smsCode,
//       );
//       UserCredential userCredential = await _auth.signInWithCredential(credential);
//
//       if (userCredential.user != null && currentFcmToken != null) {
//         await _updateFcmToken(userCredential.user!.uid, currentFcmToken);
//       }
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthError(e);
//     }
//   }
//
//   // Private Helper to avoid repeating FCM logic
//   Future<void> _updateFcmToken(String uid, String token) async {
//     // We try to update in both collections since we don't know the role yet
//     await _firestore.collection('providers').doc(uid).update({'fcmToken': token}).catchError((_){});
//     await _firestore.collection('requesters').doc(uid).update({'fcmToken': token}).catchError((_){});
//   }
//
//   Future<void> signOut() async => await _auth.signOut();
//
//   Future<DocumentSnapshot?> getUserData(String uid) async {
//     var doc = await _firestore.collection('requesters').doc(uid).get();
//     if (doc.exists) return doc;
//     doc = await _firestore.collection('providers').doc(uid).get();
//     if (doc.exists) return doc;
//     return null;
//   }
//
//   String _handleAuthError(FirebaseAuthException error) {
//     switch (error.code) {
//       case 'invalid-verification-code': return 'The SMS code is invalid.';
//       case 'user-not-found': return 'No user found with this email.';
//       case 'wrong-password': return 'Incorrect password.';
//       default: return error.message ?? 'An error occurred';
//     }
//   } }
import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // --- PHONE VERIFICATION START ---
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user != null) {
        // Link phone
        PhoneAuthCredential credential = PhoneAuthProvider.credential(
          verificationId: verificationId,
          smsCode: smsCode,
        );
        await user.linkWithCredential(credential);

        // Upload images if provider
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

        // Get FCM token
        String? fcmToken = await FirebaseMessaging.instance.getToken();

        // Save to Firestore
        String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
        Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'name': fullName,
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
    } catch (e) {
      if (user != null) await user.delete();
      rethrow;
    }
  }

  // --- SIGN IN (Email + FCM Update) ---
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
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

  // --- SIGN IN WITH PHONE ---
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

  // --- Helper: Refresh FCM Token in Correct Collection ---
  Future<void> _refreshFcmToken(String uid) async {
    String? token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    // First check if user exists in requesters
    var requesterDoc = await _firestore.collection('requesters').doc(uid).get();
    if (requesterDoc.exists) {
      await _firestore.collection('requesters').doc(uid).update({'fcmToken': token});
      return;
    }

    // Else check providers
    var providerDoc = await _firestore.collection('providers').doc(uid).get();
    if (providerDoc.exists) {
      await _firestore.collection('providers').doc(uid).update({'fcmToken': token});
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
    switch (error.code) {
      case 'invalid-verification-code': return 'The SMS code is invalid.';
      case 'user-not-found': return 'No user found with this email.';
      case 'wrong-password': return 'Incorrect password.';
      default: return error.message ?? 'An error occurred';
    }
  }
}
