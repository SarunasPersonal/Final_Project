// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_ucs_app/constants.dart';
import 'package:flutter_ucs_app/booking_page.dart';
import 'package:flutter_ucs_app/login_screen.dart';
import 'package:flutter_ucs_app/my_bookings_page.dart';
import 'package:flutter_ucs_app/settings_screen.dart';
import 'package:flutter_ucs_app/theme_provider.dart';
import 'package:flutter_ucs_app/chat_bot_screen.dart';
import 'package:flutter_ucs_app/admin/admin_panel.dart'; // Import the admin panel
import 'package:flutter_ucs_app/services/firebase_auth_service.dart'; // Import the auth service
import 'package:provider/provider.dart';
import 'package:flutter_ucs_app/models/current_user.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider to use and modify theme settings
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<FirebaseAuthService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Row(
          children: [
            // App logo
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/logo.png', width: 30),
            ),
            // App title
            const Text(
              'UCS Booking',
              style: TextStyle(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          // Compact accessibility toolbar
          _buildCompactAccessibilityToolbar(context, themeProvider),
          
          // Menu button moved to the right side of the AppBar
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: primaryColor),
            tooltip: 'Menu',
            onSelected: (String choice) {
              _handleMenuSelection(context, choice, authService);
            },
            itemBuilder: (BuildContext context) {
  final List<PopupMenuEntry<String>> menuItems = [
    // Menu items
    const PopupMenuItem<String>(
      value: 'profile',
      child: _MenuListItem(
        icon: Icons.person,
        text: 'My Profile',
      ),
    ),
    const PopupMenuItem<String>(
      value: 'bookings',
      child: _MenuListItem(
        icon: Icons.calendar_today,
        text: 'My Bookings',
      ),
    ),
    const PopupMenuItem<String>(
      value: 'settings',
      child: _MenuListItem(
        icon: Icons.settings_accessibility,
        text: 'Accessibility Settings',
      ),
    ),
    const PopupMenuItem<String>(
      value: 'chat',
      child: _MenuListItem(
        icon: Icons.chat_bubble_outline,
        text: 'Chat Assistant',
      ),
    ),
    const PopupMenuDivider(),
    const PopupMenuItem<String>(
      value: 'help',
      child: _MenuListItem(
        icon: Icons.help_outline,
        text: 'Help & Support',
      ),
    ),
  ];
  
  // Only show admin panel option if user is an admin
  if (CurrentUser.isAdmin) {
    menuItems.add(
      const PopupMenuItem<String>(
        value: 'admin',
        child: _MenuListItem(
          icon: Icons.admin_panel_settings,
          text: 'Admin Panel',
        ),
      ),
    );
  }
  
  menuItems.add(const PopupMenuDivider());
  menuItems.add(
    const PopupMenuItem<String>(
      value: 'logout',
      child: _MenuListItem(
        icon: Icons.logout,
        text: 'Logout',
      ),
    ),
  );
  
  return menuItems;
},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Admin badge for admin users
                if (CurrentUser.isAdmin)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor, width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings, color: primaryColor, size: 16),
                        const SizedBox(width: 8),
                        const Text(
                          'Admin Access',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AdminPanel()),
                            );
                          },
                          child: const Text(
                            'Open Admin Panel',
                            style: TextStyle(
                              color: primaryColor,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Welcome Text
                Text(
                  'Welcome to UCS Booking',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select a campus to book your space',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),
                
                // Campus selection heading
                Text(
                  'Choose a Campus',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Campus cards
                _buildCampusList(context),
                
                // Help and Contact section
                const SizedBox(height: 32),
                _buildHelpSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Handle menu selection
  void _handleMenuSelection(BuildContext context, String choice, FirebaseAuthService authService) {
    switch (choice) {
      case 'profile':
        // Show a snackbar for the profile feature
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile feature coming soon')),
        );
        break;
      case 'admin':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AdminPanel()),
        );
        break;
      case 'bookings':
        // Navigate to My Bookings page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MyBookingsPage()),
        );
        break;
      case 'settings':
        // Navigate to Accessibility Settings page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsScreen()),
        );
        break;
      case 'chat':
        // Navigate to Chat Assistant page
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ChatBotScreen()),
        );
        break;
      case 'help':
        // Show a snackbar for the help center
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Help center coming soon')),
        );
        break;
      case 'logout':
        // Properly logout using the auth service
        authService.logout();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
        break;
    }
  }

  // Build the compact accessibility toolbar
  Widget _buildCompactAccessibilityToolbar(BuildContext context, ThemeProvider themeProvider) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Dark mode toggle
        IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
            color: primaryColor,
          ),
          onPressed: () => themeProvider.toggleDarkMode(),
          tooltip: 'Toggle Dark Mode',
        ),
        
        // Font size options
        IconButton(
          icon: const Icon(Icons.text_fields, color: primaryColor),
          onPressed: () => _showFontSizePopup(context, themeProvider),
          tooltip: 'Change Text Size',
        ),
        
        // High contrast toggle
        IconButton(
          icon: const Icon(Icons.contrast, color: primaryColor),
          onPressed: () {
            // Show message since high contrast is not fully implemented
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('High contrast mode coming soon')),
            );
            // When implemented:
            // themeProvider.toggleHighContrast();
          },
          tooltip: 'Toggle High Contrast',
        ),
      ],
    );
  }

  // Show font size popup menu
  void _showFontSizePopup(BuildContext context, ThemeProvider themeProvider) {
    final double currentSize = themeProvider.fontSize;
    
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(100, 80, 0, 0),
      items: [
        _buildFontSizeMenuItem(0.8, 'Small', currentSize, themeProvider),
        _buildFontSizeMenuItem(1.0, 'Normal', currentSize, themeProvider),
        _buildFontSizeMenuItem(1.2, 'Large', currentSize, themeProvider),
      ],
    );
  }

  // Build font size menu item
  PopupMenuItem _buildFontSizeMenuItem(double size, String label, double currentSize, ThemeProvider themeProvider) {
    return PopupMenuItem(
      value: size,
      child: Row(
        children: [
          Text('A', style: TextStyle(fontSize: size * 18)),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          if (currentSize == size) const Icon(Icons.check, color: primaryColor),
        ],
      ),
      onTap: () => themeProvider.setFontSize(size),
    );
  }

  // Build the list of campus cards
  Widget _buildCampusList(BuildContext context) {
    final campuses = [
      {'name': 'Taunton', 'address': 'Wellington Road, Taunton', 'icon': Icons.school},
      {'name': 'Bridgwater', 'address': 'Bath Road, Bridgwater', 'icon': Icons.account_balance},
      {'name': 'Cannington', 'address': 'Rodway, Cannington', 'icon': Icons.park},
    ];

    return Column(
      children: campuses.map((campus) => 
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: _buildCampusCard(
            context, 
            campus['name'] as String, 
            campus['address'] as String, 
            campus['icon'] as IconData
          ),
        )
      ).toList(),
    );
  }

  // Build a single campus card
  Widget _buildCampusCard(
    BuildContext context,
    String location,
    String address,
    IconData icon,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => navigateToLocation(context, location),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Campus icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: primaryColor,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              // Campus details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                color: primaryColor,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the help and contact section
  Widget _buildHelpSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Help section title
          Text(
            'Need Help?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          // Help section description
          Text(
            'If you need assistance with booking or have questions about our spaces availability, please contact us.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          // Contact buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactButton(
                context,
                Icons.email,
                'Email',
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening email...')),
                ),
              ),
              _buildContactButton(
                context,
                Icons.phone,
                'Call',
                () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Calling support...')),
                ),
              ),
              _buildContactButton(
                context,
                Icons.chat,
                'Chat',
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChatBotScreen()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build a single contact button
  Widget _buildContactButton(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: secondaryColor, size: 18),
      label: Text(
        label,
        style: const TextStyle(color: secondaryColor),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: onPressed,
    );
  }

  // Navigate to the booking page for the selected campus
  void navigateToLocation(BuildContext context, String location) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => BookingPage(location)),
    );
  }
}

// Helper class for menu items
class _MenuListItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MenuListItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 20),
        const SizedBox(width: 12),
        Text(text),
      ],
    );
  }
}