import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get the current user
  User? get currentUser => _auth.currentUser;

  // Stream for authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email, password, and full name
  Future<UserCredential?> signUp({
    required String fullName,
    required String email,
    required String password,
    required String userType, // 'requester' or 'provider'
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // After creating the user, store additional details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'userType': userType,
        'createdAt': Timestamp.now(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors
      print('Firebase Auth Exception: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred during sign up: $e');
      rethrow;
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Exception: ${e.message}');
      rethrow;
    } catch (e) {
      print('An unexpected error occurred during sign in: $e');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Get user type from Firestore
  Future<String?> getUserType(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return doc.get('userType');
      }
      return null;
    } catch (e) {
      print('Error getting user type: $e');
      return null;
    }
  }
}