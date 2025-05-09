import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // AppBar with a back button and title
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Accessibility Settings',
          style: TextStyle(color: primaryColor),
        ),
      ),
      body: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Section: Display Mode
                _buildSectionTitle('Display Mode'),
                const SizedBox(height: 10),
                Card(
                  child: SwitchListTile(
                    // Toggle for Dark Mode
                    title: Row(
                      children: [
                        Icon(
                          themeProvider.isDarkMode 
                              ? Icons.dark_mode 
                              : Icons.light_mode,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          themeProvider.isDarkMode 
                              ? 'Dark Mode' 
                              : 'Light Mode',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    value: themeProvider.isDarkMode,
                    onChanged: (value) {
                      themeProvider.toggleDarkMode();
                    },
                    activeColor: primaryColor,
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Section: Text Size
                _buildSectionTitle('Text Size'),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions for adjusting text size
                        Text(
                          'Adjust the text size below:',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('A', style: TextStyle(fontSize: 14)),
                            Expanded(
                              child: Slider(
                                // Slider to adjust font size
                                value: themeProvider.fontSize,
                                min: 0.8,
                                max: 1.4,
                                divisions: 6,
                                activeColor: primaryColor,
                                onChanged: (value) {
                                  themeProvider.setFontSize(value);
                                },
                              ),
                            ),
                            const Text('A', style: TextStyle(fontSize: 24)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Display current font size label
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: primaryColor.withAlpha(26),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getFontSizeLabel(themeProvider.fontSize),
                              style: const TextStyle(color: primaryColor),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Sample text with current font size
                        Text(
                          'Sample text with current size',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'The quick brown fox jumps over the lazy dog.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Section: Additional Settings
                _buildSectionTitle('Additional Settings'),
                const SizedBox(height: 10),
                Card(
                  child: Column(
                    children: [
                      // Toggle for High Contrast
                      SwitchListTile(
                        title: Row(
                          children: [
                            const Icon(Icons.contrast, color: primaryColor),
                            const SizedBox(width: 16),
                            Text(
                              'High Contrast',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        subtitle: const Text(
                          'Increases contrast for better visibility'
                        ),
                        value: themeProvider.isHighContrast,
                        onChanged: (value) {
                          themeProvider.toggleHighContrast();
                        },
                        activeColor: primaryColor
                      ),
                      
                      const Divider(),
                      
                      // Toggle for Bold Text
                      SwitchListTile(
                        title: Row(
                          children: [
                            const Icon(Icons.text_fields, color: primaryColor),
                            const SizedBox(width: 16),
                            Text(
                              'Bold Text',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        subtitle: const Text('Makes text bolder and easier to read'),
                        value: themeProvider.isBoldText,
                        onChanged: (value) {
                          themeProvider.toggleBoldText();
                        },
                        activeColor: primaryColor,
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Reset to Default Settings Button
                Center(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, color: primaryColor),
                    label: const Text(
                      'Reset to Default Settings',
                      style: TextStyle(color: primaryColor),
                    ),
                    onPressed: () {
                      // Reset all settings to default values
                      themeProvider.setFontSize(1.0);
                      if (themeProvider.isDarkMode) {
                        themeProvider.toggleDarkMode();
                      }
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Settings reset to defaults'),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }
  
  // Helper method to build section titles
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: primaryColor,
        ),
      ),
    );
  }
  
  // Helper method to get font size label based on value
  String _getFontSizeLabel(double fontSize) {
    if (fontSize <= 0.8) return 'Small';
    if (fontSize <= 0.9) return 'Medium Small';
    if (fontSize <= 1.0) return 'Normal';
    if (fontSize <= 1.1) return 'Medium Large';
    if (fontSize <= 1.2) return 'Large';
    if (fontSize <= 1.3) return 'X-Large';
    return 'XX-Large';
  }
}