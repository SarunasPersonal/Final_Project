import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/loading_screen.dart';
import 'package:flutter_ucs_app/theme_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences (needed for theme settings)
  await SharedPreferences.getInstance();
  
  runApp(
    // Wrap the entire app with ChangeNotifierProvider
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use Consumer to listen to theme changes
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'UCS Booking App',
          // Apply the theme from ThemeProvider
          theme: themeProvider.getTheme(),
          home: const LoadingScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}