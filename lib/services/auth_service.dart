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
  }) async {
    try {
      print("📝 Starting sign up for: $email");
      
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = userCredential.user;

      if (user != null) {
        print("✓ User created: ${user.uid}");
        
        final userData = {
          'fullName': fullName,
          'email': email,
          'userType': userType,
          'createdAt': FieldValue.serverTimestamp(),
          if (userType == 'provider') ...{
            'services': [],
            'profileComplete': false,
          }
        };
        
        print("📄 Creating user document: $userData");
        
        await _firestore.collection('users').doc(user.uid).set(userData);
        
        print("✓ User document created successfully");
      }
      return user;
    } on FirebaseAuthException catch (e) {
      print("❌ Sign up error: ${e.code} - ${e.message}");
      throw _handleAuthError(e);
    } catch (e) {
      print("❌ Unexpected sign up error: $e");
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  // Sign in with email & password
  Future<User?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print("🔐 Starting sign in for: $email");
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("✓ Sign in successful: ${userCredential.user?.uid}");
      print("✓ User email: ${userCredential.user?.email}");
      
      // Verify user document exists
      if (userCredential.user != null) {
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        
        if (userDoc.exists) {
          print("✓ User document found");
          print("✓ User data: ${userDoc.data()}");
        } else {
          print("⚠️ User document not found! Creating one now...");
          
          // Create missing user document (temporary fix for existing users)
          await _firestore.collection('users').doc(userCredential.user!.uid).set({
            'fullName': email.split('@')[0], // Use email prefix as name
            'email': email,
            'userType': 'requester', // Default to requester
            'createdAt': FieldValue.serverTimestamp(),
          });
          
          print("✓ User document created");
        }
      }
      
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Sign in error: ${e.code} - ${e.message}");
      throw _handleAuthError(e);
    } catch (e) {
      print("❌ Unexpected sign in error: $e");
      throw 'An unexpected error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    print("👋 Signing out");
    await _auth.signOut();
    print("✓ Sign out complete");
  }

  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      print("📖 Fetching user data for: $uid");
      final doc = await _firestore.collection('users').doc(uid).get();
      
      if (doc.exists) {
        print("✓ User data retrieved: ${doc.data()}");
      } else {
        print("⚠️ User document doesn't exist");
      }
      
      return doc;
    } catch (e) {
      print("❌ Error fetching user data: $e");
      return null;
    }
  }

  String _handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      default:
        return 'An error occurred: ${error.message}';
    }
  }
}