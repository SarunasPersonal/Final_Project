class CurrentUser {
  static String? userId;
  static String? email;
  static bool isAdmin = false;

  // Login method to set user data
  static void login(String userEmail, String id, {bool admin = false}) {
    email = userEmail;
    userId = id;
    isAdmin = admin;
  }

  // Logout method to clear user data
  static void logout() {
    email = null;
    userId = null;
    isAdmin = false;
  }
}