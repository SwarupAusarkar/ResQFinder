//
// import 'dart:async';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
//   User? get currentUser => _auth.currentUser;
//
// <<<<<<< HEAD
//   Future<User?> signUp({
// =======
//   // ---------------------------------------------------------------------------
//   // 🚀 REGISTRATION FLOW (OTP Only for Verification)
//   // ---------------------------------------------------------------------------
//
//   // Step 1: Trigger the SMS Code
//   Future<void> startPhoneVerification({
//     required String phoneNumber,
//     required Function(String verificationId, int? resendToken) onCodeSent,
//     required Function(FirebaseAuthException) onVerificationFailed,
//   }) async {
//     await _auth.verifyPhoneNumber(
//       phoneNumber: phoneNumber,
//       verificationCompleted: (PhoneAuthCredential credential) {
//         // Auto-resolution (mostly Android).
//         // We generally handle this in the UI or ignore to force manual code entry for consistency.
//       },
//       verificationFailed: onVerificationFailed,
//       codeSent: onCodeSent,
//       codeAutoRetrievalTimeout: (String verificationId) {},
//       timeout: const Duration(seconds: 60),
//     );
//   }
//
//   // Step 2: Finalize Account Creation (Email + Pass + Verified Phone)
//   Future<User?> registerWithVerifiedPhone({
// >>>>>>> upstream/main
//     required String email,
//     required String password,
//     required String verificationId,
//     required String smsCode,
//     // Profile Data
//     required String fullName,
//     required String userType,
// <<<<<<< HEAD
//     String? verificationType,
//     String? hfrId,
//     String? nmcId,
//     bool? isHFRVerified,
//     bool? isNMCVerified,
//     required String phone,
//     required String address,
//     required double latitude,
//     required double longitude,
//     required String providerType,
//     required String description,
//     required String? fcmToken, // Added parameter
// =======
//     required String phone,
//     String? address,
//     double? latitude,
//     double? longitude,
//     String? providerType,
//     String? description,
//     bool? isHFRVerified,
//     bool? isNMCVerified,
//     String? hfrId,
//     String? nmcId,
// >>>>>>> upstream/main
//   }) async {
//     User? user;
//     try {
// <<<<<<< HEAD
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
// =======
//       // A. Create the Basic Email/Password Account
//       UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
// >>>>>>> upstream/main
//         email: email,
//         password: password,
//       );
//       user = userCredential.user;
//
//       if (user != null) {
// <<<<<<< HEAD
//         // 1. Base user data (shared by both roles)
//         final Map<String, dynamic> userData = {
//           'uid': user.uid,
//           'email': email,
//           'fullName': fullName,
//           'userType': userType,
//           'fcmToken': fcmToken ?? '', // Store token here for both roles
//           'createdAt': FieldValue.serverTimestamp(),
//         };
//
//         // 2. Provider specific data
//         if (userType == 'provider') {
//           userData.addAll({
//             'phone': phone,
//             'address': address,
//             'latitude': latitude,
//             'longitude': longitude,
//             'type': providerType,
//             'description': description,
//             'verificationType': verificationType ?? 'Individual',
//             'isHFRVerified': isHFRVerified ?? false,
//             'isNMCVerified': isNMCVerified ?? false,
//             'hfrId': hfrId ?? '',
//             'nmcId': nmcId ?? '',
//             'isAvailable': true,
//             'profileComplete': true,
//           });
//         }
//
//         // 3. Create the document in one go
//         await _firestore.collection('users').doc(user.uid).set(userData);
// =======
//         // B. Link the Phone Credential to this Account
//         // This proves the phone number belongs to this email user
//         PhoneAuthCredential credential = PhoneAuthProvider.credential(
//           verificationId: verificationId,
//           smsCode: smsCode,
//         );
//
//         await user.linkWithCredential(credential);
//
//         // C. Save Data to Firestore
//         await saveUserData(
//           user: user,
//           fullName: fullName,
//           userType: userType,
//           email: email,
//           phone: phone, // This is now verified
//           address: address,
//           latitude: latitude,
//           longitude: longitude,
//           providerType: providerType,
//           description: description,
//           isHFRVerified: isHFRVerified,
//           isNMCVerified: isNMCVerified,
//           hfrId: hfrId,
//           nmcId: nmcId,
//         );
// >>>>>>> upstream/main
//       }
//       return user;
//     } on FirebaseAuthException catch (e) {
//       // Rollback: If linking fails (e.g., invalid code), delete the half-created email user
//       // so they can try again.
//       if (user != null) await user.delete();
//       throw _handleAuthError(e);
//     } catch (e) {
// <<<<<<< HEAD
// =======
//       if (user != null) await user.delete();
// >>>>>>> upstream/main
//       rethrow;
//     }
//   }
//
// <<<<<<< HEAD
//   // UPDATED: Sync Token on Sign In
//   // It's best practice to update the token every time they log in
//   // because tokens can change/expire.
// =======
//   // ---------------------------------------------------------------------------
//   // 🔑 LOGIN FLOW (Standard Email/Password)
//   // ---------------------------------------------------------------------------
//
// >>>>>>> upstream/main
//   Future<User?> signIn({
//     required String email,
//     required String password,
//     String? currentFcmToken, // Optional: Update token on login
//   }) async {
//     try {
//       final userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
// <<<<<<< HEAD
//
//       if (userCredential.user != null) {
//         final uid = userCredential.user!.uid;
//
//         // Prepare updates
//         Map<String, dynamic> updates = {};
//         if (currentFcmToken != null) {
//           updates['fcmToken'] = currentFcmToken;
//         }
//
//         final userDoc = await _firestore.collection('users').doc(uid).get();
//
//         if (!userDoc.exists) {
//           // Create document if missing
//           await _firestore.collection('users').doc(uid).set({
//             'fullName': email.split('@')[0],
//             'email': email,
//             'userType': 'requester',
//             'fcmToken': currentFcmToken ?? '',
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//         } else if (updates.isNotEmpty) {
//           // Update existing document with new FCM token
//           await _firestore.collection('users').doc(uid).update(updates);
//         }
//       }
// =======
// >>>>>>> upstream/main
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       throw _handleAuthError(e);
//     } catch (e) {
//       throw 'An unexpected error occurred.';
//     }
//   }
//
//   // ---------------------------------------------------------------------------
//   // 💾 SHARED HELPERS
//   // ---------------------------------------------------------------------------
//
//   Future<void> saveUserData({
//     required User user,
//     required String fullName,
//     required String userType,
//     String? email,
//     String? phone,
//     String? address,
//     double? latitude,
//     double? longitude,
//     String? providerType,
//     String? description,
//     bool? isHFRVerified,
//     bool? isNMCVerified,
//     String? hfrId,
//     String? nmcId,
//   }) async {
//     String collectionPath = (userType == 'provider') ? 'providers' : 'requesters';
//
//     final Map<String, dynamic> userData = {
//       'uid': user.uid,
//       'name': fullName,
//       'userType': userType,
//       'createdAt': FieldValue.serverTimestamp(),
//       'profileComplete': true,
//       if (email != null) 'email': email,
//       if (phone != null) 'phone': phone,
//     };
//
//     if (userType == 'provider') {
//       userData.addAll({
//         'isHFRVerified': isHFRVerified ?? false,
//         'isNMCVerified': isNMCVerified ?? false,
//         'hfrId': hfrId ?? '',
//         'nmcId': nmcId ?? '',
//         'address': address ?? '',
//         'latitude': latitude ?? 0.0,
//         'longitude': longitude ?? 0.0,
//         'providerType': providerType ?? 'hospital',
//         'description': description ?? '',
//         'isAvailable': true,
//         'inventory': [],
//       });
//     }
//
//     await _firestore.collection(collectionPath).doc(user.uid).set(userData, SetOptions(merge: true));
//   }
//
// <<<<<<< HEAD
// =======
//   Future<DocumentSnapshot?> getUserData(String uid) async {
//     try {
//       var doc = await _firestore.collection('requesters').doc(uid).get();
//       if (doc.exists) return doc;
//       doc = await _firestore.collection('providers').doc(uid).get();
//       if (doc.exists) return doc;
//       return null;
//     } catch (e) {
//       return null;
//     }
//   }
//
//   Future<void> signOut() async => await _auth.signOut();
//
// >>>>>>> upstream/main
//   String _handleAuthError(FirebaseAuthException error) {
//     switch (error.code) {
//       case 'email-already-in-use': return 'Email already in use.';
//       case 'credential-already-in-use': return 'This phone number is already linked to another account.';
//       case 'invalid-verification-code': return 'The SMS code is invalid.';
//       case 'weak-password': return 'Password is too weak.';
//       case 'user-not-found': return 'No user found with this email.';
//       case 'wrong-password': return 'Incorrect password.';
//       default: return error.message ?? 'Authentication error';
//     }
//   }
// }
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ---------------------------------------------------------------------------
  // 🚀 REGISTRATION FLOW (Phone Verification + Email/Password)
  // ---------------------------------------------------------------------------

  Future<void> startPhoneVerification({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException) onVerificationFailed,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        // Auto-resolution (mostly Android). Usually handled in UI.
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: (String verificationId) {},
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
    String? fcmToken,
  }) async {
    User? user;
    try {
      // A. Create the Email/Password Account
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      user = userCredential.user;

      if (user != null) {
        // B. Link the Phone Credential
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
          phone: phone,
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

        // D. Store FCM Token if provided
        if (fcmToken != null) {
          await _firestore.collection('users').doc(user.uid).set({
            'fcmToken': fcmToken,
          }, SetOptions(merge: true));
        }
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

  // ---------------------------------------------------------------------------
  // 🔑 LOGIN FLOW (Email/Password)
  // ---------------------------------------------------------------------------

  Future<User?> signIn({
    required String email,
    required String password,
    String? currentFcmToken,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        if (currentFcmToken != null) {
          await _firestore.collection('users').doc(uid).set({
            'fcmToken': currentFcmToken,
          }, SetOptions(merge: true));
        }
      }
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
