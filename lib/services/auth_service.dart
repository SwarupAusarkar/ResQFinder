import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<User?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String userType,
    String? verificationType,
    String? hfrId,
    String? nmcId,
    bool? isHFRVerified,
    bool? isNMCVerified,
    required String phone,
    required String address,
    required double latitude,
    required double longitude,
    required String providerType,
    required String description,
    required String? fcmToken, // Added parameter
  }) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        // 1. Base user data (shared by both roles)
        final Map<String, dynamic> userData = {
          'uid': user.uid,
          'email': email,
          'fullName': fullName,
          'userType': userType,
          'fcmToken': fcmToken ?? '', // Store token here for both roles
          'createdAt': FieldValue.serverTimestamp(),
        };

        // 2. Provider specific data
        if (userType == 'provider') {
          userData.addAll({
            'phone': phone,
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'type': providerType,
            'description': description,
            'verificationType': verificationType ?? 'Individual',
            'isHFRVerified': isHFRVerified ?? false,
            'isNMCVerified': isNMCVerified ?? false,
            'hfrId': hfrId ?? '',
            'nmcId': nmcId ?? '',
            'isAvailable': true,
            'profileComplete': true,
          });
        }

        // 3. Create the document in one go
        await _firestore.collection('users').doc(user.uid).set(userData);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  // UPDATED: Sync Token on Sign In
  // It's best practice to update the token every time they log in
  // because tokens can change/expire.
  Future<User?> signIn({
    required String email,
    required String password,
    String? currentFcmToken, // Optional: Update token on login
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final uid = userCredential.user!.uid;

        // Prepare updates
        Map<String, dynamic> updates = {};
        if (currentFcmToken != null) {
          updates['fcmToken'] = currentFcmToken;
        }

        final userDoc = await _firestore.collection('users').doc(uid).get();

        if (!userDoc.exists) {
          // Create document if missing
          await _firestore.collection('users').doc(uid).set({
            'fullName': email.split('@')[0],
            'email': email,
            'userType': 'requester',
            'fcmToken': currentFcmToken ?? '',
            'createdAt': FieldValue.serverTimestamp(),
          });
        } else if (updates.isNotEmpty) {
          // Update existing document with new FCM token
          await _firestore.collection('users').doc(uid).update(updates);
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