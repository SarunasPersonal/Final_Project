import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ucs_app/constants.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  double _fontSize = 1.0; // 1.0 is normal, 1.2 is large, 0.8 is small
  bool _isHighContrast = false;
  bool _isBoldText = false;
  bool _isLoaded = false;
  
  // Getters
  bool get isDarkMode => _isDarkMode;
  double get fontSize => _fontSize;
  bool get isHighContrast => _isHighContrast;
  bool get isBoldText => _isBoldText;
  bool get isLoaded => _isLoaded;
  
  // Constructor loads saved preferences
  ThemeProvider() {
    _loadPreferences();
  }
  
  // Load saved preferences from SharedPreferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load values
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
      _fontSize = prefs.getDouble('fontSize') ?? 1.0;
      _isHighContrast = prefs.getBool('isHighContrast') ?? false;
      _isBoldText = prefs.getBool('isBoldText') ?? false;
      
      _isLoaded = true;
      notifyListeners();
    } catch (e) {
      // Use defaults if there's an error
      _isDarkMode = false;
      _fontSize = 1.0;
      _isHighContrast = false;
      _isBoldText = false;
      _isLoaded = true;
      notifyListeners();
    }
  }
  
  // Save preferences
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', _isDarkMode);
      await prefs.setDouble('fontSize', _fontSize);
      await prefs.setBool('isHighContrast', _isHighContrast);
      await prefs.setBool('isBoldText', _isBoldText);
    } catch (e) {
      // Handle error silently
    }
  }
  
  // Toggle dark mode
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }
  
  // Set font size
  void setFontSize(double size) {
    _fontSize = size;
    _savePreferences();
    notifyListeners();
  }
  
  // Toggle high contrast
  void toggleHighContrast() {
    _isHighContrast = !_isHighContrast;
    _savePreferences();
    notifyListeners();
  }
  
  // Toggle bold text
  void toggleBoldText() {
    _isBoldText = !_isBoldText;
    _savePreferences();
    notifyListeners();
  }
  
  // Reset all settings to default
  void resetToDefaults() {
    _isDarkMode = false;
    _fontSize = 1.0;
    _isHighContrast = false;
    _isBoldText = false;
    _savePreferences();
    notifyListeners();
  }
  
  // Get theme based on current settings
  ThemeData getTheme() {
    final baseTheme = _isDarkMode ? _darkTheme : _lightTheme;
    
    // Apply high contrast if enabled
    if (_isHighContrast) {
      return _buildHighContrastTheme();
    }
    
    // Apply regular theme with font size and bold text adjustments
    return baseTheme.copyWith(
      textTheme: _getTextTheme(baseTheme.brightness),
      primaryTextTheme: _getTextTheme(baseTheme.brightness),
    );
  }
  
  // Create a text theme with the appropriate font size and weight
  TextTheme _getTextTheme(Brightness brightness) {
    final double scaleFactor = _fontSize;
    final FontWeight regularWeight = _isBoldText ? FontWeight.w500 : FontWeight.w400;
    final FontWeight mediumWeight = _isBoldText ? FontWeight.w700 : FontWeight.w500;
    final FontWeight lightWeight = _isBoldText ? FontWeight.w400 : FontWeight.w300;
    final Color textColor = brightness == Brightness.dark ? Colors.white : Colors.black;
    
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 96 * scaleFactor,
        fontWeight: lightWeight,
        color: textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 60 * scaleFactor,
        fontWeight: lightWeight,
        color: textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 48 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      headlineLarge: TextStyle(
        fontSize: 40 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 34 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 24 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 20 * scaleFactor,
        fontWeight: mediumWeight,
        color: textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      titleSmall: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: mediumWeight,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14 * scaleFactor,
        fontWeight: regularWeight,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12 * scaleFactor,
        fontWeight: regularWeight,
        color: brightness == Brightness.dark ? Colors.white70 : Colors.black54,
      ),
    );
  }
  
  ThemeData _buildHighContrastTheme() {
    final highContrastColorScheme = _isDarkMode 
      ? const ColorScheme.dark(
          primary: Colors.yellow,
          onPrimary: Colors.black,
          secondary: Colors.white,
          onSecondary: Colors.black,
          surface: Colors.black,
          onSurface: Colors.yellow,
          error: Colors.red,
          onError: Colors.white,
        )
      : const ColorScheme.light(
          primary: Colors.black,
          onPrimary: Colors.white,
          secondary: Colors.black,
          onSecondary: Colors.white,
          surface: Colors.white,
          onSurface: Colors.black,
          error: Colors.red,
          onError: Colors.white,
        );
        
    return ThemeData(
      brightness: _isDarkMode ? Brightness.dark : Brightness.light,
      useMaterial3: true,
      colorScheme: highContrastColorScheme,
      textTheme: _getTextTheme(_isDarkMode ? Brightness.dark : Brightness.light),
      primaryTextTheme: _getTextTheme(_isDarkMode ? Brightness.dark : Brightness.light),
      scaffoldBackgroundColor: _isDarkMode ? Colors.black : Colors.white,
      cardTheme: CardTheme(
        color: _isDarkMode ? Colors.black : Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: _isDarkMode ? Colors.yellow : Colors.black,
            width: 2,
          ),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _isDarkMode ? Colors.yellow : Colors.black,
          foregroundColor: _isDarkMode ? Colors.black : Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: _isDarkMode ? Colors.white : Colors.black,
              width: 1,
            ),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: _isDarkMode ? Colors.yellow : Colors.black,
          side: BorderSide(
            color: _isDarkMode ? Colors.yellow : Colors.black,
            width: 2,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _isDarkMode ? Colors.yellow : Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: _isDarkMode ? Colors.black : Colors.white,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isDarkMode ? Colors.yellow : Colors.black,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isDarkMode ? Colors.yellow : Colors.black,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: _isDarkMode ? Colors.white : Colors.blue,
            width: 3,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: _isDarkMode ? Colors.black : Colors.white,
        foregroundColor: _isDarkMode ? Colors.yellow : Colors.black,
        elevation: 4,
        iconTheme: IconThemeData(
          color: _isDarkMode ? Colors.yellow : Colors.black,
        ),
        titleTextStyle: TextStyle(
          color: _isDarkMode ? Colors.yellow : Colors.black,
          fontSize: 20 * _fontSize,
          fontWeight: _isBoldText ? FontWeight.bold : FontWeight.w500,
        ),
      ),
    );
  }
  
  // Light theme
  final ThemeData _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: primaryColor,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
  
  // Dark theme
  final ThemeData _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primaryColor,
    fontFamily: 'Roboto',
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Color(0xFF121212),
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E1E1E),
      foregroundColor: primaryColor,
      elevation: 0,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: secondaryColor,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFF2C2C2C),
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    ),
  );
}