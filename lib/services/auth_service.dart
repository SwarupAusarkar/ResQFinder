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
    required String userType, // 'requester' or 'provider'
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
        // 2. ROUTING: Determine target collection
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

        // 3. Add Role-Specific Data
        if (userType == 'provider') {
          userData.addAll({
            'isHFRVerified': isHFRVerified ?? false,
            'isNMCVerified': isNMCVerified ?? false,
            'hfrId': hfrId ?? '',
            'nmcId': nmcId ?? '',
            'address': address,
            'latitude': latitude,
            'longitude': longitude,
            'providerType': providerType,
            'description': description,
            'isAvailable': true,
            'inventory': [], // Initialized as empty list for providers
          });
        }

        // 4. Save to the specific collection
        await _firestore.collection(collectionPath).doc(user.uid).set(userData);
      }
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Verify user document exists in one of the two collections
        final userDoc = await getUserData(userCredential.user!.uid);
        
        if (userDoc == null || !userDoc.exists) {
          // Default to requester if document is missing (temporary migration logic)
          await _firestore
              .collection('requesters')
              .doc(userCredential.user!.uid)
              .set({
                'name': email.split('@')[0],
                'email': email,
                'userType': 'requester',
                'createdAt': FieldValue.serverTimestamp(),
                'profileComplete': false,
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

  // Updated to search both collections
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      // Check requesters first
      var doc = await _firestore.collection('requesters').doc(uid).get();
      if (doc.exists) return doc;

      // Then check providers
      doc = await _firestore.collection('providers').doc(uid).get();
      if (doc.exists) return doc;

      return null;
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