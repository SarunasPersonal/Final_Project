class CurrentUser {
  static String? uid;
  static String? email;
  static bool isAdmin = false;

  static void login(String userEmail, String userId, {bool admin = false}) {
    email = userEmail;
    uid = userId;
    isAdmin = admin;
  }

  static void logout() {
    email = null;
    uid = null;
    isAdmin = false;
  }
}
