import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFAD1E3C);
const Color secondaryColor = Color(0xFFEECB28);
const Color whiteColor = Colors.white;

// Current user details (for simple in-memory authentication)
class CurrentUser {
  static String? email;
  static String? userId;
  static bool isAdmin = false; // Add this line
  
  static bool isLoggedIn() => email != null && userId != null;
  
  static void login(String userEmail, String id, {bool admin = false}) { // Update this
    email = userEmail;
    userId = id;
    isAdmin = admin;
  }
  
  static void logout() {
    email = null;
    userId = null;
    isAdmin = false; // Add this line
  }
}