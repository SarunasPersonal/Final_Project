import 'package:flutter/material.dart';

// Colors
const Color primaryColor = Color(0xFFAD1E3C);
const Color secondaryColor = Color(0xFFEECB28);
const Color whiteColor = Colors.white;

// Text Styles
const TextStyle headingStyle = TextStyle(
  fontSize: 24,
  fontWeight: FontWeight.bold,
  color: Colors.black87,
);

const TextStyle subheadingStyle = TextStyle(
  fontSize: 18,
  fontWeight: FontWeight.w500,
  color: Colors.black54,
);

const TextStyle bodyStyle = TextStyle(
  fontSize: 16,
  color: Colors.black87,
);

// Spacing
const double defaultPadding = 16.0;
const double defaultBorderRadius = 8.0;

// Animation Durations
const Duration defaultAnimationDuration = Duration(milliseconds: 300);

// API Endpoints
const String baseUrl = 'https://api.example.com';
const String roomsEndpoint = '/rooms';
const String bookingsEndpoint = '/bookings';
const String usersEndpoint = '/users';

// Error Messages
const String genericErrorMessage = 'Something went wrong. Please try again.';
const String networkErrorMessage =
    'Network error. Please check your connection.';
const String validationErrorMessage = 'Please check your input and try again.';

// Success Messages
const String bookingSuccessMessage = 'Booking created successfully!';
const String updateSuccessMessage = 'Updated successfully!';
const String deleteSuccessMessage = 'Deleted successfully!';
