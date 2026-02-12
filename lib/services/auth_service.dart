// // lib/services/auth_service.dart
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
//
//   User? get currentUser => _auth.currentUser;
//
//   // ** START: MODIFICATION **
//   Future<User?> signUp({
//     required String email,
//     required String password,
//     required String fullName,
//     required String userType,
//     // Add provider-specific fields
//     String? phone,
//     String? address,
//     double? latitude,
//     double? longitude,
//     String? providerType,
//     String? description,
//   }) async {
//   // ** END: MODIFICATION **
//     try {
//       print("📝 Starting sign up for: $email");
//
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       User? user = userCredential.user;
//
//       if (user != null) {
//         print("✓ User created: ${user.uid}");
//
//         // ** START: MODIFICATION **
//         // Consolidate all user data into a single map
//         final userData = {
//           'fullName': fullName,
//           'email': email,
//           'userType': userType,
//           'createdAt': FieldValue.serverTimestamp(),
//         };
//
//         if (userType == 'provider') {
//           userData.addAll({
//             'phone': phone ?? '',
//             'address': address ?? '',
//             'latitude': latitude ?? 0.0,
//             'longitude': longitude ?? 0.0,
//             'type': providerType ?? 'hospital',
//             'description': description ?? '',
//             'isAvailable': true,
//             'rating': 5, // Default rating
//             'profileComplete': true, // Set to true immediately
//             'inventory': [], // Initialize with empty inventory
//           });
//         }
//
//         print("📄 Creating user document with all data: $userData");
//
//         // Use a single `set` operation to create the complete document
//         await _firestore.collection('users').doc(user.uid).set(userData);
//         // ** END: MODIFICATION **
//
//         print("✓ User document created successfully");
//       }
//       return user;
//     } on FirebaseAuthException catch (e) {
//       print("❌ Sign up error: ${e.code} - ${e.message}");
//       throw _handleAuthError(e);
//     } catch (e) {
//       print("❌ Unexpected sign up error: $e");
//       throw 'An unexpected error occurred. Please try again.';
//     }
//   }
//
//   // Sign in with email & password
//   Future<User?> signIn({
//     required String email,
//     required String password,
//   }) async {
//     try {
//       print("🔐 Starting sign in for: $email");
//
//       final userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       print("✓ Sign in successful: ${userCredential.user?.uid}");
//       print("✓ User email: ${userCredential.user?.email}");
//
//       // Verify user document exists
//       if (userCredential.user != null) {
//         final userDoc = await _firestore
//             .collection('users')
//             .doc(userCredential.user!.uid)
//             .get();
//
//         if (userDoc.exists) {
//           print("✓ User document found");
//           print("✓ User data: ${userDoc.data()}");
//         } else {
//           print("⚠️ User document not found! Creating one now...");
//
//           // Create missing user document (temporary fix for existing users)
//           await _firestore.collection('users').doc(userCredential.user!.uid).set({
//             'fullName': email.split('@')[0], // Use email prefix as name
//             'email': email,
//             'userType': 'requester', // Default to requester
//             'createdAt': FieldValue.serverTimestamp(),
//           });
//
//           print("✓ User document created");
//         }
//       }
//
//       return userCredential.user;
//     } on FirebaseAuthException catch (e) {
//       print("❌ Sign in error: ${e.code} - ${e.message}");
//       throw _handleAuthError(e);
//     } catch (e) {
//       print("❌ Unexpected sign in error: $e");
//       throw 'An unexpected error occurred. Please try again.';
//     }
//   }
//
//   Future<void> signOut() async {
//     print("👋 Signing out");
//     await _auth.signOut();
//     print("✓ Sign out complete");
//   }
//
//   Future<DocumentSnapshot?> getUserData(String uid) async {
//     try {
//       print("📖 Fetching user data for: $uid");
//       final doc = await _firestore.collection('users').doc(uid).get();
//
//       if (doc.exists) {
//         print("✓ User data retrieved: ${doc.data()}");
//       } else {
//         print("⚠️ User document doesn't exist");
//       }
//
//       return doc;
//     } catch (e) {
//       print("❌ Error fetching user data: $e");
//       return null;
//     }
//   }
//
//   String _handleAuthError(FirebaseAuthException error) {
//     switch (error.code) {
//       case 'user-not-found':
//         return 'No user found for that email.';
//       case 'wrong-password':
//         return 'Wrong password provided for that user.';
//       case 'invalid-email':
//         return 'The email address is not valid.';
//       case 'email-already-in-use':
//         return 'An account already exists for that email.';
//       case 'weak-password':
//         return 'The password provided is too weak.';
//       case 'invalid-credential':
//         return 'Invalid email or password.';
//       default:
//         return 'An error occurred: ${error.message}';
//     }
//   } }
// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // services/auth_service.dart

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String userType,
    // ADD THESE NEW PARAMETERS
    bool? isHFRVerified,
    bool? isNMCVerified,
    String? hfrId,
    String? nmcId,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required String providerType,
    required String description,
  }) async {
    try {
      // 1. Create the Auth User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 2. Save the expanded data to Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': fullName,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),

          // NEW FIELDS FOR PROVIDER VERIFICATION
          if (userType == 'provider') ...{
            'isHFRVerified': isHFRVerified ?? false,
            'isNMCVerified': isNMCVerified ?? false,
            'hfrId': hfrId ?? '',
            'nmcId': nmcId ?? '',
            'isAvailable': true,
            'profileComplete':
                true, // Marking true since they provided IDs at signup
          },
        });
      }
      return user;
    } catch (e) {
      rethrow; // Pass error back to the UI
    }
  }

  // Sign in and fetch data
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Ensure the document exists on sign-in
      if (userCredential.user != null) {
        final userDoc =
            await _firestore
                .collection('users')
                .doc(userCredential.user!.uid)
                .get();
        if (!userDoc.exists) {
          // Temporary fix for users missing documents
          await _firestore
              .collection('users')
              .doc(userCredential.user!.uid)
              .set({
                'fullName': email.split('@')[0],
                'email': email,
                'userType': 'requester',
                'createdAt': FieldValue.serverTimestamp(),
              });
        }
      }
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    } catch (e) {
      throw 'An unexpected error occurred.';
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      return null;
    }
  }

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      default:
        return 'An error occurred: ${error.message}';
    }
  }
}
