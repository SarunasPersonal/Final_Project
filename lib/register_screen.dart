// Modified RegisterScreen with Name and Surname fields
// lib/register_screen.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/home_page.dart';
import 'package:flutter_ucs_app/services/firebase_auth_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controllers for text fields - added name and surname
  final nameController = TextEditingController();
  final surnameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  
  // Loading and error state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    // Clean up controllers when the widget is removed
    nameController.dispose();
    surnameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
  
  // Validate email format
  bool _isValidEmail(String email) {
    // Basic email validation
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  
  // Validate password strength
  bool _isValidPassword(String password) {
    // Password should be at least 6 characters
    return password.length >= 6;
  }

  // Register the user with Firebase
  Future<void> _registerUser() async {
    // Clear any previous error messages
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    // Validate inputs
    if (nameController.text.isEmpty ||
        surnameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        confirmPasswordController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please fill in all fields';
        _isLoading = false;
      });
      return;
    }

    if (!_isValidEmail(emailController.text.trim())) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
        _isLoading = false;
      });
      return;
    }

    if (!_isValidPassword(passwordController.text)) {
      setState(() {
        _errorMessage = 'Password must be at least 6 characters long';
        _isLoading = false;
      });
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Passwords do not match';
        _isLoading = false;
      });
      return;
    }

    try {
      // Get Firebase Auth service from provider
      final authService = Provider.of<FirebaseAuthService>(context, listen: false);
      
      // Register the user with email and password
      final user = await authService.registerWithEmailPassword(
        emailController.text.trim(),
        passwordController.text,
      );
      
      if (!mounted) return;
      
      if (user != null) {
        // Save additional user data to Firestore
        await _saveUserDataToFirestore(user.uid);
        
        // Registration successful
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate to home page after short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        });
      }
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Auth specific errors
      setState(() {
        switch (e.code) {
          case 'email-already-in-use':
            _errorMessage = 'The email address is already in use';
            break;
          case 'invalid-email':
            _errorMessage = 'The email address is not valid';
            break;
          case 'operation-not-allowed':
            _errorMessage = 'Email/password accounts are not enabled';
            break;
          case 'weak-password':
            _errorMessage = 'The password is too weak';
            break;
          default:
            _errorMessage = 'Registration failed: ${e.message}';
        }
      });
    } catch (e) {
      // Handle generic errors
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      // Reset loading state if still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Save user data to Firestore
  Future<void> _saveUserDataToFirestore(String uid) async {
    try {
      // Format the full name properly with proper capitalization
      final firstName = _capitalizeFirstLetter(nameController.text.trim());
      final lastName = _capitalizeFirstLetter(surnameController.text.trim());
      final fullName = '$firstName $lastName';
      
      // Create a document for the user in the 'users' collection
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'firstName': firstName,
        'lastName': lastName,
        'fullName': fullName,
        'email': emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving user data to Firestore: $e');
      // This won't interrupt the registration flow, but logs the error
    }
  }
  
  // Helper method to capitalize first letter of each word
  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return '';
    return text.split(' ')
        .map((word) => word.isNotEmpty 
            ? word[0].toUpperCase() + word.substring(1).toLowerCase() 
            : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: whiteColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: primaryColor),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  const SizedBox(height: 20),
                  
                  // Subtitle text
                  const Text(
                    'Create an account to start booking spaces across UCS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Error message display
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(10),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800),
                      ),
                    ),
                  
                  // Name input field (new)
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: primaryColor),
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  
                  // Surname input field (new)
                  TextField(
                    controller: surnameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: primaryColor),
                    ),
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  
                  // Email input field
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email, color: primaryColor),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  
                  // Password input field
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock, color: primaryColor),
                      helperText: 'Must be at least 6 characters long',
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 20),
                  
                  // Confirm password input field
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline, color: primaryColor),
                    ),
                    enabled: !_isLoading,
                  ),
                  const SizedBox(height: 30),
                  
                  // Create account button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: _isLoading ? null : _registerUser,
                    child: _isLoading
                      ? const CircularProgressIndicator(color: secondaryColor)
                      : const Text(
                          'CREATE ACCOUNT',
                          style: TextStyle(color: secondaryColor),
                        ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Already have an account?'),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.pop(context);
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