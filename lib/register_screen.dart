import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controllers for text fields
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: whiteColor, // Set app bar background color
        elevation: 0, // Remove shadow
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor), // Back button
          onPressed: () => Navigator.pop(context), // Navigate back
        ),
        title: const Text(
          'Create Account', // App bar title
          style: TextStyle(color: primaryColor),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Limit max width
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Add padding
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize column size
                children: [
                  // Title text
                  const Text(
                    'Join UCS Booking',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing
                  // Subtitle text
                  const Text(
                    'Create an account to start booking spaces across UCS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30), // Spacing
                  // Email input field
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress, // Email keyboard
                  ),
                  const SizedBox(height: 20), // Spacing
                  // Password input field
                  TextField(
                    controller: passwordController,
                    obscureText: true, // Hide text for password
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing
                  // Confirm password input field
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true, // Hide text for password
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 30), // Spacing
                  // Create account button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Button color
                      minimumSize: const Size(double.infinity, 50), // Full width
                    ),
                    onPressed: () {
                      // Simple validation
                      if (emailController.text.isEmpty ||
                          passwordController.text.isEmpty ||
                          confirmPasswordController.text.isEmpty) {
                        // Show error if any field is empty
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please fill in all fields'),
                          ),
                        );
                        return;
                      }

                      if (passwordController.text !=
                          confirmPasswordController.text) {
                        // Show error if passwords do not match
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Passwords do not match'),
                          ),
                        );
                        return;
                      }

                      // Show success message
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Account created successfully!'),
                        ),
                      );

                      // Navigate back to login screen
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(color: secondaryColor), // Button text color
                    ),
                  ),
                  const SizedBox(height: 20), // Spacing
                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center align
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to sign in
                        },
                        child: const Text(
                          'Sign In',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
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
