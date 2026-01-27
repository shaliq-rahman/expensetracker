import 'package:firebase_auth/firebase_auth.dart';
import 'package:expense_tracker/services/user_service.dart';
import 'package:expense_tracker/services/fcm_service.dart';
import 'package:expense_tracker/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserService _userService = UserService();
  final FCMService _fcmService = FCMService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign In with Email and Password
  Future<UserCredential> signIn(String email, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // On successful login, save FCM token and subscribe
      if (credential.user != null) {
        try {
          await _fcmService.saveTokenToDatabase(credential.user!.uid);
          await _fcmService.subscribeToTopic('xtrack-users');
        } catch (e) {
          print("FCM Setup failed (non-critical): $e");
        }
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Up with Email and Password
  Future<UserCredential> signUp(String email, String password, String name) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Create user document
        String? fcmToken;
        try {
          fcmToken = await _fcmService.getToken();
        } catch (e) {
          print("Failed to get FCM token (non-critical): $e");
        }
        
        UserModel newUser = UserModel(
          id: credential.user!.uid,
          email: email,
          displayName: name,
          fcmToken: fcmToken,
        );

        await _userService.createUser(newUser);
        
        // Subscribe to topic
        try {
          await _fcmService.subscribeToTopic('xtrack-users');
        } catch (e) {
          print("Failed to subscribe to topic (non-critical): $e");
        }
      }

      return credential;
    } catch (e) {
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
