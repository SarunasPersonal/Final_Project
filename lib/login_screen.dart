import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/home_page.dart';
import 'package:flutter_ucs_app/register_screen.dart';
import 'package:flutter_ucs_app/forgot_password_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for email and password input fields
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Limit the width of the content
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Add padding around the content
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize the column size
                children: [
                  // App logo
                  Image.asset('assets/logo.png', width: 120, height: 120),
                  const SizedBox(height: 30), // Spacing between elements
                  // Welcome text
                  const Text(
                    'Welcome to UCS Colab',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing between elements
                  // Email input field
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress, // Set input type to email
                  ),
                  const SizedBox(height: 20), // Spacing between elements
                  // Password input field
                  TextField(
                    controller: passwordController,
                    obscureText: true, // Hide the password text
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing between elements
                  // Login button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Set button color
                      minimumSize: const Size(double.infinity, 50), // Full-width button
                    ),
                    onPressed: () {
                      // Check if the email and password match the admin credentials
                      if (emailController.text == 'admin@btc.ac.uk' &&
                          passwordController.text == 'admin') {
                        // Set the current user
                        CurrentUser.login(emailController.text, 'admin1');
                        
                        // Navigate to the home page
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HomePage()),
                        );
                      } else {
                        // Show an error message if credentials are invalid
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Invalid email or password'),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      'LOG IN',
                      style: TextStyle(color: secondaryColor), // Set text color
                    ),
                  ),
                  // Create user button
                  TextButton(
                    onPressed: () {
                      // Navigate to the register screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'CREATE USER',
                      style: TextStyle(color: primaryColor), // Set text color
                    ),
                  ),
                  // Forgot password button
                  TextButton(
                    onPressed: () {
                      // Navigate to the forgot password screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'FORGOT PASSWORD?',
                      style: TextStyle(color: primaryColor), // Set text color
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}