import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'dart:async';
import 'package:flutter_ucs_app/login_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller; // Animation controller to manage the animation lifecycle
  late Animation<double> _animation; // Animation object for controlling the fade effect

  @override
  void initState() {
    super.initState();

    // Initialize the animation controller with a duration of 3 seconds
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Define a sequence of animations for the fade effect
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20), // Fade in
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 20), // Stay fully visible
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 20), // Fade out
    ]).animate(_controller);

    // Start the animation
    _controller.forward();

    // Navigate to the LoginScreen after 3 seconds
    Timer(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    // Dispose of the animation controller to free resources
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor, // Set the background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center the content vertically
          children: [
            // FadeTransition widget to apply the fade animation to the logo
            FadeTransition(
              opacity: _animation, // Bind the animation to the opacity property
              child: Image.asset('assets/logo.png', width: 200), // Display the logo
            ),
          ],
        ),
      ),
    );
  }
}