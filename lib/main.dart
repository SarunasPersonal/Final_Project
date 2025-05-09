import 'package:flutter/material.dart'; // This imports Flutter's material design package
import 'package:flutter_ucs_app/loading_screen.dart'; // This imports the loading screen widget
import 'package:flutter_ucs_app/theme_provider.dart'; // This imports the theme provider to manage app themes
import 'package:provider/provider.dart'; // This imports the provider package for state management
import 'package:shared_preferences/shared_preferences.dart'; // This imports shared preferences for local data storage

// The main function is the starting point of the app
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Makes sure Flutter is ready before running the app
  await SharedPreferences.getInstance(); // Prepares shared preferences for use
  runApp(
    ChangeNotifierProvider( // Provides the theme provider to the app
      create: (context) => ThemeProvider(), // Creates an instance of the theme provider
      child: const MyApp(), // Sets MyApp as the main widget
    ),
  );
}

// MyApp is the main widget of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key}); // Constructor for MyApp

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>( // Listens for changes in the theme provider
      builder: (context, themeProvider, child) {
        return MaterialApp(
          theme: themeProvider.getTheme(), // Uses the theme from the theme provider
          home: const LoadingScreen(), // Sets the first screen to the loading screen
          debugShowCheckedModeBanner: false, // Removes the debug banner
        );
      },
    );
  }
}
