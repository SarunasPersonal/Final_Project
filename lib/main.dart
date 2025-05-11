import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/loading_screen.dart';
import 'package:flutter_ucs_app/services/firebase_auth_service.dart'; // Add this import
import 'package:flutter_ucs_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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

// adding to github just in case 
