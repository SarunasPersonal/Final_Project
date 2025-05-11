import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService extends ChangeNotifier {
  // Create a logger instance for this class
  final _logger = Logger('FirebaseAuthService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  
  // Constructor: Initialize and set up auth state listener
FirebaseAuthService() {
  _setupLogging();
  
  _auth.authStateChanges().listen((User? user) async {
    _user = user;
    
    // Update CurrentUser global helper
    if (user != null) {
      bool isAdmin = await checkIfUserIsAdmin(user.uid);
      CurrentUser.login(user.email ?? '', user.uid, admin: isAdmin);
    } else {
      CurrentUser.logout();
    }
    
    notifyListeners();
  });
}
  
  // Set up logging configuration
  void _setupLogging() {
    // Only set up logging once
    if (Logger.root.level == Level.INFO) return;
    
    // Configure root logger
    Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        debugPrint('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          debugPrint('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          debugPrint('Stack trace: ${record.stackTrace}');
        }
      }
    });
  }
  
  // Getter for current user
  User? get currentUser => _user;
  
  // Check if user is logged in
  bool get isLoggedIn => _user != null;
  
  // Login with email and password
  Future<User?> loginWithEmailPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      _logger.warning('Login error', e);
      rethrow;
    }
  }
  Future<bool> checkIfUserIsAdmin(String uid) async {
  try {
    // Get admin status from Firestore (you'll need to create this collection)
    final docSnapshot = await FirebaseFirestore.instance
        .collection('admin_users')
        .doc(uid)
        .get();
    
    return docSnapshot.exists;
  } catch (e) {
    _logger.warning('Admin check error', e);
    return false;
  }
}
  
  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      _logger.warning('Registration error', e);
      rethrow;
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      _logger.warning('Reset password error', e);
      rethrow;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      _logger.warning('Logout error', e);
      rethrow;
    }
  }
}