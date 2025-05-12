// lib/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:logging/logging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_ucs_app/admin/models/current_user.dart';

class FirebaseAuthService extends ChangeNotifier {
  // Create a logger instance for this class
  final _logger = Logger('FirebaseAuthService');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
        _logger.info('User logged in: ${user.email}, isAdmin: $isAdmin');
      } else {
        CurrentUser.logout();
        _logger.info('User logged out');
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
      
      // Update last login timestamp in Firestore
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }
      
      return result.user;
    } catch (e) {
      _logger.warning('Login error: $e');
      rethrow;
    }
  }
  
  // Check if user is an admin
  Future<bool> checkIfUserIsAdmin(String uid) async {
    try {
      // Get admin status from Firestore
      final docSnapshot = await _firestore
          .collection('admin_users')
          .doc(uid)
          .get();
      
      return docSnapshot.exists;
    } catch (e) {
      _logger.warning('Admin check error: $e');
      return false;
    }
  }
  
  // Register with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      // Create the user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      User? user = result.user;
      
      // If user creation was successful, save user data to Firestore
      if (user != null) {
        await _saveUserToFirestore(user, email);
      }
      
      return user;
    } catch (e) {
      _logger.warning('Registration error: $e');
      rethrow;
    }
  }
  
  // Save user data to Firestore
  Future<void> _saveUserToFirestore(User user, String email) async {
    try {
      // Create a document for the user in the 'users' collection
      await _firestore.collection('users').doc(user.uid).set({
        'name': user.displayName ?? email.split('@')[0], // Use part of email as name if no display name
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
      
      _logger.info('User data saved to Firestore');
    } catch (e) {
      _logger.severe('Error saving user to Firestore: $e');
      // Not throwing here to prevent disrupting registration flow
      // Even if Firestore save fails, the auth user will still exist
    }
  }
  
  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      _logger.info('Password reset email sent to $email');
    } catch (e) {
      _logger.warning('Reset password error: $e');
      rethrow;
    }
  }
  
  // Logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _logger.info('User logged out');
    } catch (e) {
      _logger.warning('Logout error: $e');
      rethrow;
    }
  }
}