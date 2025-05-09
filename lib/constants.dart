import 'package:flutter/material.dart';

const Color primaryColor = Color(0xFFAD1E3C);
const Color secondaryColor = Color(0xFFEECB28);
const Color whiteColor = Colors.white;

// Current user details (for simple in-memory authentication)
class CurrentUser {
  static String? email;
  static String? userId;
  
  static bool isLoggedIn() => email != null && userId != null;
  
  static void login(String userEmail, String id) {
    email = userEmail;
    userId = id;
  }
  
  static void logout() {
    email = null;
    userId = null;
  }
}