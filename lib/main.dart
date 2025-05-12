// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/loading_screen.dart';
import 'package:flutter_ucs_app/services/firebase_auth_service.dart';
import 'package:flutter_ucs_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:logging/logging.dart';
import 'package:flutter_ucs_app/models/room_model.dart'; // Import for RoomService

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure logging
  _setupLogging();
  
  // Initialize Firebase with the correct options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize RoomService to load default rooms if needed
  final roomService = RoomService();
  await roomService.initializeDefaultRooms();
  
  // Run the app with providers
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => FirebaseAuthService()),
      ],
      child: const MyApp(),
    ),
  );
}

// Configure logging for the application
void _setupLogging() {
  // Only set up logging once
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    debugPrint('${record.level.name}: ${record.time}: ${record.message}');
    if (record.error != null) {
      debugPrint('Error: ${record.error}');
    }
    if (record.stackTrace != null) {
      debugPrint('Stack trace: ${record.stackTrace}');
    }
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'UCS Booking App',
          theme: themeProvider.getTheme(),
          home: const LoadingScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}