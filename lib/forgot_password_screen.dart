import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Controller for the email input field
    final emailController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: whiteColor, // Set the background color of the app bar
        elevation: 0, // Remove shadow from the app bar
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor), // Back button
          onPressed: () => Navigator.pop(context), // Navigate back to the previous screen
        ),
        title: const Text(
          'Reset Password', // Title of the screen
          style: TextStyle(color: primaryColor),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400), // Limit the width of the content
            child: Padding(
              padding: const EdgeInsets.all(24.0), // Add padding around the content
              child: Column(
                mainAxisSize: MainAxisSize.min, // Minimize the vertical size of the column
                children: [
                  const Icon(
                    Icons.lock_reset, // Lock reset icon
                    size: 80,
                    color: primaryColor,
                  ),
                  const SizedBox(height: 20), // Add spacing
                  const Text(
                    'Forgot Your Password?', // Header text
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20), // Add spacing
                  const Text(
                    'Enter your email address below and we\'ll send you instructions to reset your password.', // Instruction text
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30), // Add spacing
                  TextField(
                    controller: emailController, // Bind the controller to the text field
                    decoration: const InputDecoration(
                      labelText: 'Email Address', // Label for the text field
                      border: OutlineInputBorder(), // Add a border around the text field
                      prefixIcon: Icon(Icons.email, color: primaryColor), // Email icon
                    ),
                    keyboardType: TextInputType.emailAddress, // Set keyboard type to email
                  ),
                  const SizedBox(height: 30), // Add spacing
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, // Set button background color
                      minimumSize: const Size(double.infinity, 50), // Set button size
                    ),
                    onPressed: () {
                      // Validate email is not empty
                      if (emailController.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter your email address'), // Show error message
                          ),
                        );
                        return;
                      }

                      // In a real app, you would trigger a password reset email
                      // For now, just show a success message and return to login
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Password reset email sent!'), // Show success message
                        ),
                      );
                      
                      // Navigate back to login screen
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'RESET PASSWORD', // Button text
                      style: TextStyle(color: secondaryColor),
                    ),
                  ),
                  const SizedBox(height: 20), // Add spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center, // Center the row
                    children: [
                      const Text('Remember your password?'), // Prompt text
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context); // Navigate back to the login screen
                        },
                        child: const Text(
                          'Sign In', // Sign-in button text
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